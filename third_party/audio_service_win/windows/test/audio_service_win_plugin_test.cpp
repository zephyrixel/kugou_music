#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <utility>

#include "audio_service_win_plugin.h"

namespace audio_service_win {
namespace test {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

std::string InvokeAndCaptureError(AudioServiceWinPlugin& plugin,
                                  const std::string& method,
                                  EncodableMap arguments) {
  std::string error_code;
  plugin.HandleMethodCall(
      MethodCall(method,
                 std::make_unique<EncodableValue>(std::move(arguments))),
      std::make_unique<MethodResultFunctions<>>(
          nullptr,
          [&error_code](const std::string& code, const std::string&,
                        const EncodableValue*) { error_code = code; },
          nullptr));
  return error_code;
}

}  // namespace

TEST(AudioServiceWinPlugin, InitializeRejectsEmptyAppId) {
  AudioServiceWinPlugin plugin;
  EXPECT_EQ(InvokeAndCaptureError(plugin, "initializeSMTC", EncodableMap{}),
            "InvalidArguments");
}

TEST(AudioServiceWinPlugin, UpdateStateRejectsUnknownState) {
  AudioServiceWinPlugin plugin;
  EncodableMap arguments;
  arguments[EncodableValue("state")] = EncodableValue(9);
  EXPECT_EQ(InvokeAndCaptureError(plugin, "updateState", std::move(arguments)),
            "InvalidArguments");
}

TEST(AudioServiceWinPlugin, UnknownMethodIsNotImplemented) {
  AudioServiceWinPlugin plugin;
  bool not_implemented = false;
  plugin.HandleMethodCall(
      MethodCall("unknown",
                 std::make_unique<EncodableValue>(EncodableMap{})),
      std::make_unique<MethodResultFunctions<>>(
          nullptr, nullptr, [&not_implemented]() { not_implemented = true; }));
  EXPECT_TRUE(not_implemented);
}

}  // namespace test
}  // namespace audio_service_win
