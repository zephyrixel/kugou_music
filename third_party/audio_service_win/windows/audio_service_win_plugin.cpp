#include "audio_service_win_plugin.h"

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.h>
#include <winrt/Windows.Media.Playback.h>
#include <winrt/Windows.Storage.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/base.h>

#include <algorithm>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using winrt::Windows::Foundation::TimeSpan;
using winrt::Windows::Media::MediaPlaybackAutoRepeatMode;
using winrt::Windows::Media::MediaPlaybackStatus;
using winrt::Windows::Media::Playback::MediaPlayer;
using winrt::Windows::Media::SystemMediaTransportControls;
using winrt::Windows::Media::SystemMediaTransportControlsButton;
using winrt::Windows::Media::SystemMediaTransportControlsDisplayUpdater;
using winrt::Windows::Media::SystemMediaTransportControlsTimelineProperties;

constexpr UINT kSmtcEventMessage = WM_APP + 0x4B47;

enum class SmtcEvent : WPARAM {
  kPlay,
  kPause,
  kStop,
  kNext,
  kPrevious,
  kFastForward,
  kRewind,
  kSeek,
  kRepeat,
  kShuffle,
};

MediaPlayer g_media_player{nullptr};
SystemMediaTransportControls g_smtc{nullptr};
SystemMediaTransportControlsDisplayUpdater g_updater{nullptr};
std::unique_ptr<flutter::MethodChannel<EncodableValue>> g_channel;
flutter::PluginRegistrarWindows* g_registrar = nullptr;
int g_window_proc_id = -1;
std::string g_app_id;
int64_t g_duration_ms = 0;
winrt::event_token g_button_token{};
winrt::event_token g_seek_token{};
winrt::event_token g_repeat_token{};
winrt::event_token g_shuffle_token{};

const EncodableValue* Find(const EncodableMap& map, const char* key) {
  const auto iterator = map.find(EncodableValue(key));
  return iterator == map.end() ? nullptr : &iterator->second;
}

int64_t Integer(const EncodableValue* value, int64_t fallback = 0) {
  if (value == nullptr) return fallback;
  if (const auto* number = std::get_if<int64_t>(value)) return *number;
  if (const auto* number = std::get_if<int32_t>(value)) return *number;
  return fallback;
}

double Number(const EncodableValue* value, double fallback = 1.0) {
  if (value == nullptr) return fallback;
  if (const auto* number = std::get_if<double>(value)) return *number;
  return static_cast<double>(Integer(value, static_cast<int64_t>(fallback)));
}

bool Boolean(const EncodableValue* value, bool fallback = false) {
  if (value == nullptr) return fallback;
  if (const auto* boolean = std::get_if<bool>(value)) return *boolean;
  return fallback;
}

std::string String(const EncodableValue* value) {
  if (value == nullptr || value->IsNull()) return {};
  if (const auto* string = std::get_if<std::string>(value)) return *string;
  return {};
}

HWND RootWindow() {
  if (g_registrar == nullptr || g_registrar->GetView() == nullptr) return nullptr;
  return ::GetAncestor(g_registrar->GetView()->GetNativeWindow(), GA_ROOT);
}

void PostSmtcEvent(SmtcEvent event, LPARAM value = 0) {
  if (const HWND window = RootWindow()) {
    ::PostMessage(window, kSmtcEventMessage, static_cast<WPARAM>(event), value);
  }
}

void SendToDart(const char* method, EncodableValue value) {
  if (g_channel == nullptr) return;
  g_channel->InvokeMethod(method, std::make_unique<EncodableValue>(value));
}

std::optional<LRESULT> HandleWindowMessage(HWND, UINT message, WPARAM wparam,
                                           LPARAM lparam) {
  if (message != kSmtcEventMessage) return std::nullopt;
  switch (static_cast<SmtcEvent>(wparam)) {
    case SmtcEvent::kPlay:
      SendToDart("onSMTCButtonPressed", EncodableValue("play"));
      break;
    case SmtcEvent::kPause:
      SendToDart("onSMTCButtonPressed", EncodableValue("pause"));
      break;
    case SmtcEvent::kStop:
      SendToDart("onSMTCButtonPressed", EncodableValue("stop"));
      break;
    case SmtcEvent::kNext:
      SendToDart("onSMTCButtonPressed", EncodableValue("next"));
      break;
    case SmtcEvent::kPrevious:
      SendToDart("onSMTCButtonPressed", EncodableValue("previous"));
      break;
    case SmtcEvent::kFastForward:
      SendToDart("onSMTCButtonPressed", EncodableValue("fastForward"));
      break;
    case SmtcEvent::kRewind:
      SendToDart("onSMTCButtonPressed", EncodableValue("rewind"));
      break;
    case SmtcEvent::kSeek:
      SendToDart("onSMTCSeek", EncodableValue(static_cast<int64_t>(lparam)));
      break;
    case SmtcEvent::kRepeat:
      SendToDart("onSMTCRepeatMode", EncodableValue(static_cast<int32_t>(lparam)));
      break;
    case SmtcEvent::kShuffle:
      SendToDart("onSMTCShuffle", EncodableValue(lparam != 0));
      break;
  }
  return 0;
}

std::optional<SmtcEvent> ButtonEvent(
    SystemMediaTransportControlsButton button) {
  switch (button) {
    case SystemMediaTransportControlsButton::Play:
      return SmtcEvent::kPlay;
    case SystemMediaTransportControlsButton::Pause:
      return SmtcEvent::kPause;
    case SystemMediaTransportControlsButton::Stop:
      return SmtcEvent::kStop;
    case SystemMediaTransportControlsButton::Next:
      return SmtcEvent::kNext;
    case SystemMediaTransportControlsButton::Previous:
      return SmtcEvent::kPrevious;
    case SystemMediaTransportControlsButton::FastForward:
      return SmtcEvent::kFastForward;
    case SystemMediaTransportControlsButton::Rewind:
      return SmtcEvent::kRewind;
    default:
      return std::nullopt;
  }
}

void EnsureSmtc() {
  if (g_smtc != nullptr) return;
  g_media_player = MediaPlayer();
  g_smtc = g_media_player.SystemMediaTransportControls();
  g_updater = g_smtc.DisplayUpdater();
  g_updater.AppMediaId(winrt::to_hstring(g_app_id));
  g_smtc.IsPlayEnabled(true);
  g_smtc.IsPauseEnabled(true);
  g_smtc.IsStopEnabled(true);
  g_smtc.IsEnabled(false);
  g_button_token = g_smtc.ButtonPressed([](auto const&, auto const& args) {
    if (const auto event = ButtonEvent(args.Button())) {
      PostSmtcEvent(*event);
    }
  });
  g_seek_token = g_smtc.PlaybackPositionChangeRequested(
      [](auto const&, auto const& args) {
        PostSmtcEvent(SmtcEvent::kSeek,
                      args.RequestedPlaybackPosition().count() / 10000);
      });
  g_repeat_token = g_smtc.AutoRepeatModeChangeRequested(
      [](auto const&, auto const& args) {
        int32_t mode = 0;
        if (args.RequestedAutoRepeatMode() == MediaPlaybackAutoRepeatMode::Track) {
          mode = 1;
        } else if (args.RequestedAutoRepeatMode() ==
                   MediaPlaybackAutoRepeatMode::List) {
          mode = 2;
        }
        PostSmtcEvent(SmtcEvent::kRepeat, mode);
      });
  g_shuffle_token = g_smtc.ShuffleEnabledChangeRequested(
      [](auto const&, auto const& args) {
        PostSmtcEvent(SmtcEvent::kShuffle,
                      args.RequestedShuffleEnabled() ? 1 : 0);
      });
}

void UpdateTimeline(int64_t position_ms, double speed) {
  if (g_smtc == nullptr) return;
  SystemMediaTransportControlsTimelineProperties timeline;
  timeline.StartTime(TimeSpan{0});
  timeline.MinSeekTime(TimeSpan{0});
  timeline.Position(TimeSpan{std::max<int64_t>(0, position_ms) * 10000});
  timeline.MaxSeekTime(TimeSpan{std::max<int64_t>(0, g_duration_ms) * 10000});
  timeline.EndTime(TimeSpan{std::max<int64_t>(0, g_duration_ms) * 10000});
  g_smtc.UpdateTimelineProperties(timeline);
  g_smtc.PlaybackRate(speed);
}

void ClearSmtc() {
  if (g_smtc == nullptr) return;
  g_smtc.ButtonPressed(g_button_token);
  g_smtc.PlaybackPositionChangeRequested(g_seek_token);
  g_smtc.AutoRepeatModeChangeRequested(g_repeat_token);
  g_smtc.ShuffleEnabledChangeRequested(g_shuffle_token);
  g_smtc.IsEnabled(false);
  if (g_updater != nullptr) {
    g_updater.ClearAll();
    g_updater.Update();
  }
  g_updater = nullptr;
  g_smtc = nullptr;
  g_media_player = nullptr;
}

}  // namespace

namespace audio_service_win {

void AudioServiceWinPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  static bool registered = false;
  if (registered) return;
  registered = true;
  g_registrar = registrar;
  g_channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), "audio_service_win",
      &flutter::StandardMethodCodec::GetInstance());
  auto plugin = std::make_unique<AudioServiceWinPlugin>();
  g_channel->SetMethodCallHandler(
      [pointer = plugin.get()](const auto& call, auto result) {
        pointer->HandleMethodCall(call, std::move(result));
      });
  g_window_proc_id =
      registrar->RegisterTopLevelWindowProcDelegate(HandleWindowMessage);
  registrar->AddPlugin(std::move(plugin));
}

AudioServiceWinPlugin::AudioServiceWinPlugin() = default;

AudioServiceWinPlugin::~AudioServiceWinPlugin() {
  ClearSmtc();
  if (g_registrar != nullptr && g_window_proc_id >= 0) {
    g_registrar->UnregisterTopLevelWindowProcDelegate(g_window_proc_id);
  }
  g_window_proc_id = -1;
  g_registrar = nullptr;
  g_channel.reset();
}

void AudioServiceWinPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  const auto* arguments =
      call.arguments() == nullptr ? nullptr : std::get_if<EncodableMap>(call.arguments());
  if (arguments == nullptr) {
    result->Error("InvalidArguments", "A map of arguments is required");
    return;
  }

  if (call.method_name() == "initializeSMTC") {
    g_app_id = String(Find(*arguments, "appid"));
    if (g_app_id.empty()) {
      result->Error("InvalidArguments", "appid must be a non-empty string");
      return;
    }
    EnsureSmtc();
    result->Success();
    return;
  }

  if (call.method_name() == "setMediaItem") {
    EnsureSmtc();
    g_duration_ms = Integer(Find(*arguments, "duration"));
    g_smtc.IsEnabled(true);
    g_updater.ClearAll();
    g_updater.Type(winrt::Windows::Media::MediaPlaybackType::Music);
    g_updater.MusicProperties().Title(
        winrt::to_hstring(String(Find(*arguments, "title"))));
    g_updater.MusicProperties().Artist(
        winrt::to_hstring(String(Find(*arguments, "artist"))));
    g_updater.MusicProperties().AlbumTitle(
        winrt::to_hstring(String(Find(*arguments, "album"))));
    const std::string art_uri = String(Find(*arguments, "artUri"));
    if (art_uri.rfind("http://", 0) == 0 ||
        art_uri.rfind("https://", 0) == 0) {
      try {
        const winrt::Windows::Foundation::Uri uri(winrt::to_hstring(art_uri));
        g_updater.Thumbnail(
            winrt::Windows::Storage::Streams::RandomAccessStreamReference::CreateFromUri(uri));
      } catch (const winrt::hresult_error&) {
        // Metadata remains usable when remote artwork is malformed or unavailable.
      }
    }
    g_updater.Update();
    UpdateTimeline(0, 1.0);
    result->Success();
    return;
  }

  if (call.method_name() == "updateState") {
    const int64_t state = Integer(Find(*arguments, "state"), -1);
    if (state < 0 || state > 2) {
      result->Error("InvalidArguments", "state must be 0, 1, or 2");
      return;
    }
    EnsureSmtc();
    g_smtc.IsEnabled(state != 2);
    g_smtc.IsNextEnabled(Boolean(Find(*arguments, "canNext")));
    g_smtc.IsPreviousEnabled(Boolean(Find(*arguments, "canPrevious")));
    g_smtc.ShuffleEnabled(Boolean(Find(*arguments, "shuffle")));
    const int64_t repeat = Integer(Find(*arguments, "repeatMode"));
    g_smtc.AutoRepeatMode(repeat == 1 ? MediaPlaybackAutoRepeatMode::Track
                                     : repeat == 2 ? MediaPlaybackAutoRepeatMode::List
                                                   : MediaPlaybackAutoRepeatMode::None);
    g_smtc.PlaybackStatus(state == 0 ? MediaPlaybackStatus::Playing
                                     : state == 1 ? MediaPlaybackStatus::Paused
                                                  : MediaPlaybackStatus::Stopped);
    g_duration_ms = Integer(Find(*arguments, "duration"), g_duration_ms);
    UpdateTimeline(Integer(Find(*arguments, "position")),
                   Number(Find(*arguments, "speed")));
    if (state == 2 && g_updater != nullptr) {
      g_updater.ClearAll();
      g_updater.Update();
    }
    result->Success();
    return;
  }

  result->NotImplemented();
}

}  // namespace audio_service_win
