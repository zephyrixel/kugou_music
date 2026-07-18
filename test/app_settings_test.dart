import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/preferences/app_settings.dart';
import 'package:kgmusic/core/preferences/preference_store.dart';

void main() {
  test('settings use stable defaults when preferences are empty', () async {
    final controller = await AppSettingsController.create(
      _MemoryPreferenceStore(),
    );

    expect(controller.settings.defaultPlaybackQuality, AudioQuality.standard);
    expect(
      controller.settings.audioCacheMaxBytes,
      AudioCacheLimits.defaultBytes,
    );
  });

  test('settings restore valid values and normalize cache capacity', () async {
    final store = _MemoryPreferenceStore({
      'playback_default_quality': 'flac',
      'audio_cache_max_bytes': 700 * AudioCacheLimits.mebibyte,
    });

    final controller = await AppSettingsController.create(store);

    expect(controller.settings.defaultPlaybackQuality, AudioQuality.flac);
    expect(
      controller.settings.audioCacheMaxBytes,
      768 * AudioCacheLimits.mebibyte,
    );
  });

  test('invalid persisted values fall back without blocking startup', () async {
    final store = _MemoryPreferenceStore({
      'playback_default_quality': 'unknown',
      'audio_cache_max_bytes': 'large',
    });

    final controller = await AppSettingsController.create(store);

    expect(controller.settings.defaultPlaybackQuality, AudioQuality.standard);
    expect(
      controller.settings.audioCacheMaxBytes,
      AudioCacheLimits.defaultBytes,
    );
  });

  test('settings persist changes before publishing them', () async {
    final store = _MemoryPreferenceStore();
    final controller = await AppSettingsController.create(store);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    await controller.setDefaultPlaybackQuality(AudioQuality.high);
    await controller.setAudioCacheMaxBytes(2 * 1024 * 1024 * 1024);

    expect(store.values['playback_default_quality'], 'high');
    expect(store.values['audio_cache_max_bytes'], 2 * 1024 * 1024 * 1024);
    expect(controller.settings.defaultPlaybackQuality, AudioQuality.high);
    expect(notifications, 2);
  });

  test('failed writes leave the published settings unchanged', () async {
    final store = _MemoryPreferenceStore()..failWrites = true;
    final controller = await AppSettingsController.create(store);

    await expectLater(
      controller.setDefaultPlaybackQuality(AudioQuality.high),
      throwsStateError,
    );

    expect(controller.settings.defaultPlaybackQuality, AudioQuality.standard);
  });
}

class _MemoryPreferenceStore implements PreferenceStore {
  _MemoryPreferenceStore([Map<String, Object>? values]) : values = {...?values};

  final Map<String, Object> values;
  bool failWrites = false;

  @override
  Future<T> read<T>(PreferenceKey<T> key) async =>
      key.decode(values[key.name]) ?? key.defaultValue;

  @override
  Future<void> write<T>(PreferenceKey<T> key, T value) async {
    if (failWrites) throw StateError('write failed');
    values[key.name] = key.encode(value);
  }
}
