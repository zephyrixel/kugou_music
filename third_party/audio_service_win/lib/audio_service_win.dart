import 'dart:developer';

import 'package:audio_service_platform_interface/audio_service_platform_interface.dart';
import 'package:flutter/services.dart';

class AudioServiceWin extends AudioServicePlatform {
  AudioHandlerCallbacks? _handlerCallbacks;
  final methodChannel = const MethodChannel('audio_service_win');
  bool _methodCallHandlerSet = false;
  Duration? _duration;

  static void registerWith() {
    final instance = AudioServiceWin();
    AudioServicePlatform.instance = instance;
  }

  @override
  Future<void> configure(ConfigureRequest request) async {
    log('Configure AudioServiceWin.', name: 'audio_service_win');
    assert(
      request.config.androidNotificationChannelId != null,
      "androidNotificationChannelId is required for registering DBus object. e.g com.ryanheise.myapp.channel.audio",
    );

    // Set up method call handler if not already done
    if (!_methodCallHandlerSet) {
      await _setupMethodCallHandler();
      _methodCallHandlerSet = true;
    }

    await methodChannel.invokeMethod<String>('initializeSMTC', {
      'appid': request.config.androidNotificationChannelId,
    });
  }

  @override
  Future<void> setMediaItem(SetMediaItemRequest request) async {
    log('Set Media Item in AudioServiceWin.', name: 'audio_service_win');

    await methodChannel.invokeMethod('setMediaItem', {
      'title': request.mediaItem.title,
      'artist': request.mediaItem.artist,
      'album': request.mediaItem.album,
      'artUri': request.mediaItem.artUri.toString(),
      'duration': request.mediaItem.duration?.inMilliseconds ?? 0,
    });
    _duration = request.mediaItem.duration;
  }

  @override
  Future<void> setState(SetStateRequest request) async {
    /* States:
    0: Playing
    1: Paused
    2: Stopped
    */
    int state = 0;
    switch (request.state.playing) {
      case true:
        state = 0; // Playing
        break;
      case false:
        state = 1; // Paused
        break;
    }
    final actions = request.state.systemActions;
    final controls = request.state.controls.map((control) => control.action);
    bool hasAction(MediaActionMessage action) =>
        actions.contains(action) || controls.contains(action);
    await methodChannel.invokeMethod('updateState', {
      'state': state,
      'position': request.state.updatePosition.inMilliseconds,
      'duration': _duration?.inMilliseconds ?? 0,
      'speed': request.state.speed,
      'canNext': hasAction(MediaActionMessage.skipToNext),
      'canPrevious': hasAction(MediaActionMessage.skipToPrevious),
      'repeatMode': request.state.repeatMode.index,
      'shuffle':
          request.state.shuffleMode != AudioServiceShuffleModeMessage.none,
    });
  }

  @override
  Future<void> setQueue(SetQueueRequest request) async {
    log(
      'setQueue() has not been implemented for Windows.',
      name: 'audio_service_win',
    );
  }

  @override
  Future<void> stopService(StopServiceRequest request) async {
    await methodChannel.invokeMethod('updateState', {'state': 2});
  }

  Future<void> _setupMethodCallHandler() async {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'onSMTCButtonPressed') {
        final button = call.arguments;
        log('SMTC Button Pressed: $button', name: 'audio_service_win');

        // Handle button presses using callbacks if available
        if (_handlerCallbacks != null) {
          switch (button) {
            case 'play':
              _handlerCallbacks!.play(const PlayRequest());
              break;
            case 'pause':
              _handlerCallbacks!.pause(const PauseRequest());
              break;
            case 'stop':
              _handlerCallbacks!.stop(const StopRequest());
              break;
            case 'next':
              _handlerCallbacks!.skipToNext(const SkipToNextRequest());
              break;
            case 'previous':
              _handlerCallbacks!.skipToPrevious(const SkipToPreviousRequest());
              break;
            case 'fastForward':
              _handlerCallbacks!.fastForward(const FastForwardRequest());
              break;
            case 'rewind':
              _handlerCallbacks!.rewind(const RewindRequest());
              break;
            default:
              log('Unhandled button: $button', name: 'audio_service_win');
              break;
          }
        }
      } else if (call.method == 'onSMTCSeek') {
        final position = call.arguments as int;
        await _handlerCallbacks?.seek(
          SeekRequest(position: Duration(milliseconds: position)),
        );
      } else if (call.method == 'onSMTCRepeatMode') {
        final index = call.arguments as int;
        await _handlerCallbacks?.setRepeatMode(
          SetRepeatModeRequest(
            repeatMode: AudioServiceRepeatModeMessage.values[index],
          ),
        );
      } else if (call.method == 'onSMTCShuffle') {
        await _handlerCallbacks?.setShuffleMode(
          SetShuffleModeRequest(
            shuffleMode: call.arguments == true
                ? AudioServiceShuffleModeMessage.all
                : AudioServiceShuffleModeMessage.none,
          ),
        );
      }
    });
  }

  @override
  void setHandlerCallbacks(AudioHandlerCallbacks callbacks) {
    _handlerCallbacks = callbacks;
  }
}
