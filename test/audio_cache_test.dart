import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';

void main() {
  const song = Song(
    id: 'mix:42',
    title: 'Cache Song',
    hashes: AudioHashes(standard: 'standard-hash', high: 'high-hash'),
  );

  test('audio cache identity ignores signed URL query parameters', () async {
    final directory = await Directory.systemTemp.createTemp('kgmusic-audio-');
    addTearDown(() => directory.delete(recursive: true));
    final manager = await AudioCacheManager.create(directory: directory);

    final first = await manager.sourceFor(
      song,
      const PlayableResolution(
        url: 'https://example.com/audio/song.mp3?token=first',
        quality: AudioQuality.standard,
      ),
    );
    final second = await manager.sourceFor(
      song,
      const PlayableResolution(
        url: 'https://example.com/audio/song.mp3?token=second',
        quality: AudioQuality.standard,
      ),
    );
    final high = await manager.sourceFor(
      song,
      const PlayableResolution(
        url: 'https://example.com/audio/song.mp3?token=second',
        quality: AudioQuality.high,
      ),
    );
    final preview = await manager.sourceFor(
      song,
      const PreviewResolution(
        url: 'https://example.com/audio/song.mp3?token=preview',
        quality: AudioQuality.standard,
        endMs: 60000,
      ),
    );

    expect(first.file.path, second.file.path);
    expect(high.file.path, isNot(first.file.path));
    expect(preview.file.path, isNot(first.file.path));
  });

  test('audio cache prunes least recently used completed files', () async {
    final directory = await Directory.systemTemp.createTemp('kgmusic-lru-');
    addTearDown(() => directory.delete(recursive: true));
    final manager = await AudioCacheManager.create(
      directory: directory,
      maxBytes: 10,
    );
    final oldFile = File('${directory.path}/old.mp3');
    final newFile = File('${directory.path}/new.mp3');
    await oldFile.writeAsBytes(List.filled(8, 1));
    await newFile.writeAsBytes(List.filled(8, 2));
    await oldFile.setLastModified(DateTime(2025));
    await newFile.setLastModified(DateTime(2026));

    await manager.prune();

    expect(await oldFile.exists(), isFalse);
    expect(await newFile.exists(), isTrue);
  });

  test(
    'cache clearing preserves the active file until playback changes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'kgmusic-active-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final manager = await AudioCacheManager.create(directory: directory);
      final expected = await manager.sourceFor(
        song,
        const PlayableResolution(
          url: 'https://example.com/audio/song.mp3',
          quality: AudioQuality.standard,
        ),
      );
      await expected.file.writeAsBytes(List.filled(8, 1));
      final active = await manager.sourceFor(
        song,
        const PlayableResolution(
          url: 'https://example.com/audio/song.mp3',
          quality: AudioQuality.standard,
        ),
      );
      manager.setActive(active);

      await manager.clear();
      expect(await active.file.exists(), isTrue);

      manager.setActive(null);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await active.file.exists(), isFalse);
    },
  );
}
