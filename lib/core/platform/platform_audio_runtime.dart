import 'dart:io';

import 'package:audio_service_mpris/audio_service_mpris.dart';
import 'package:audio_service_win/audio_service_win.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

/// Registers desktop audio implementations before any AudioPlayer is created.
abstract final class PlatformAudioRuntime {
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    if (Platform.isLinux) {
      JustAudioMediaKit.title = 'KGMusic';
      JustAudioMediaKit.ensureInitialized(linux: true, windows: false);
      AudioServiceMpris.registerWith();
      return;
    }
    if (Platform.isWindows) AudioServiceWin.registerWith();
  }
}
