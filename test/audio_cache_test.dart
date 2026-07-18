// ignore_for_file: experimental_member_use

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
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

  test('audio cache accepts repeated Accept-Ranges response headers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final serverSubscription = server.listen((request) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('audio', 'mpeg')
        ..headers.add(HttpHeaders.acceptRangesHeader, 'bytes')
        ..headers.add(HttpHeaders.acceptRangesHeader, 'bytes')
        ..add(List<int>.generate(64, (index) => index))
        ..close();
    });
    addTearDown(() async {
      await serverSubscription.cancel();
      await server.close(force: true);
    });
    final directory = await Directory.systemTemp.createTemp(
      'kgmusic-range-header-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final source = LockCachingAudioSource(
      Uri.parse('http://${server.address.host}:${server.port}/song.mp3'),
      cacheFile: File('${directory.path}/song.mp3'),
    );

    final response = await source.request();
    final bytes = await response.stream.expand((chunk) => chunk).toList();

    expect(response.rangeRequestsSupported, isTrue);
    expect(bytes, hasLength(64));
    await source.downloadProgressStream.firstWhere((progress) => progress == 1);
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
    'audio cache applies a smaller runtime limit and reports usage',
    () async {
      final directory = await Directory.systemTemp.createTemp('kgmusic-limit-');
      addTearDown(() => directory.delete(recursive: true));
      final manager = await AudioCacheManager.create(
        directory: directory,
        maxBytes: 100,
      );
      final oldFile = File('${directory.path}/old.mp3');
      final newFile = File('${directory.path}/new.mp3');
      await oldFile.writeAsBytes(List.filled(8, 1));
      await newFile.writeAsBytes(List.filled(8, 2));
      await oldFile.setLastModified(DateTime(2025));
      await newFile.setLastModified(DateTime(2026));

      await manager.setMaxBytes(10);
      final usage = await manager.usage();

      expect(await oldFile.exists(), isFalse);
      expect(await newFile.exists(), isTrue);
      expect(usage.totalBytes, 8);
      expect(usage.maxBytes, 10);
    },
  );

  test(
    'runtime pruning defers the active song until playback changes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'kgmusic-active-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final manager = await AudioCacheManager.create(
        directory: directory,
        maxBytes: 100,
      );
      final activeFile = File('${directory.path}/active.mp3');
      await activeFile.writeAsBytes(List.filled(12, 1));
      manager.setActive(
        CachedAudioHandle(
          source: LockCachingAudioSource(
            Uri.parse('https://example.com/active.mp3'),
            cacheFile: activeFile,
          ),
          file: activeFile,
        ),
      );

      await manager.setMaxBytes(10);
      expect(await activeFile.exists(), isTrue);

      manager.setActive(null);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(await activeFile.exists(), isFalse);
    },
  );

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
