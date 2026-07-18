import 'package:flutter/foundation.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/preferences/preference_store.dart';

abstract final class AudioCacheLimits {
  static const mebibyte = 1024 * 1024;
  static const stepBytes = 256 * mebibyte;
  static const minBytes = stepBytes;
  static const maxBytes = 8 * 1024 * mebibyte;
  static const defaultBytes = 1024 * mebibyte;

  static int normalize(int bytes) {
    final clamped = bytes.clamp(minBytes, maxBytes);
    final steps = ((clamped - minBytes) / stepBytes).round();
    return minBytes + steps * stepBytes;
  }
}

class AppSettings {
  const AppSettings({
    this.defaultPlaybackQuality = AudioQuality.standard,
    this.audioCacheMaxBytes = AudioCacheLimits.defaultBytes,
  });

  final AudioQuality defaultPlaybackQuality;
  final int audioCacheMaxBytes;

  AppSettings copyWith({
    AudioQuality? defaultPlaybackQuality,
    int? audioCacheMaxBytes,
  }) => AppSettings(
    defaultPlaybackQuality:
        defaultPlaybackQuality ?? this.defaultPlaybackQuality,
    audioCacheMaxBytes: audioCacheMaxBytes ?? this.audioCacheMaxBytes,
  );
}

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._(this._store, this._settings);

  static final _qualityKey = PreferenceKey<AudioQuality>(
    name: 'playback_default_quality',
    defaultValue: AudioQuality.standard,
    decode: _decodeQuality,
    encode: (value) => value.name,
  );
  static final _audioCacheMaxBytesKey = PreferenceKey<int>(
    name: 'audio_cache_max_bytes',
    defaultValue: AudioCacheLimits.defaultBytes,
    decode: (value) => value is int ? AudioCacheLimits.normalize(value) : null,
    encode: AudioCacheLimits.normalize,
  );

  final PreferenceStore _store;
  AppSettings _settings;

  AppSettings get settings => _settings;

  static Future<AppSettingsController> create(PreferenceStore store) async {
    final quality = _readOrDefault(store, _qualityKey);
    final audioCacheMaxBytes = _readOrDefault(store, _audioCacheMaxBytesKey);
    return AppSettingsController._(
      store,
      AppSettings(
        defaultPlaybackQuality: await quality,
        audioCacheMaxBytes: await audioCacheMaxBytes,
      ),
    );
  }

  Future<void> setDefaultPlaybackQuality(AudioQuality quality) async {
    if (_settings.defaultPlaybackQuality == quality) return;
    await _store.write(_qualityKey, quality);
    _settings = _settings.copyWith(defaultPlaybackQuality: quality);
    notifyListeners();
  }

  Future<void> setAudioCacheMaxBytes(int bytes) async {
    final normalized = AudioCacheLimits.normalize(bytes);
    if (_settings.audioCacheMaxBytes == normalized) return;
    await _store.write(_audioCacheMaxBytesKey, normalized);
    _settings = _settings.copyWith(audioCacheMaxBytes: normalized);
    notifyListeners();
  }
}

Future<T> _readOrDefault<T>(PreferenceStore store, PreferenceKey<T> key) async {
  try {
    return await store.read(key);
  } catch (_) {
    return key.defaultValue;
  }
}

AudioQuality? _decodeQuality(Object? value) {
  if (value is! String) return null;
  for (final quality in AudioQuality.values) {
    if (quality.name == value) return quality;
  }
  return null;
}
