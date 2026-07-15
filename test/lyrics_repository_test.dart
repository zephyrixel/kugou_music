import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/cache/lyrics_repository.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/lyric.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/lyrics_sdk.dart';

void main() {
  const song = Song(
    id: 'mix:42',
    title: '测试歌曲',
    mixSongId: 42,
    hashes: AudioHashes(standard: 'STANDARD'),
  );
  const lyrics = LyricDocument(
    format: LyricFormat.lrc,
    offsetMs: 0,
    lines: [LyricLine(startMs: 1000, durationMs: 500, text: '第一句')],
  );

  test('positive cache avoids a second remote request', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final first = _FakeLyricsSdk(() async => lyrics);
    expect(await LyricsRepository(first, database).load(song), same(lyrics));

    final second = _FakeLyricsSdk(() async => null);
    final cached = await LyricsRepository(second, database).load(song);
    expect(cached?.lines.single.text, '第一句');
    expect(second.calls, 0);
  });

  test('not-found cache expires after 24 hours', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    var now = DateTime.now();
    final remote = _FakeLyricsSdk(() async => null);
    final repository = LyricsRepository(remote, database, now: () => now);

    expect(await repository.load(song), isNull);
    now = now.add(const Duration(hours: 23));
    expect(await repository.load(song), isNull);
    expect(remote.calls, 1);

    now = now.add(const Duration(hours: 2));
    expect(await repository.load(song), isNull);
    expect(remote.calls, 2);
  });

  test(
    'concurrent loads are coalesced and force refresh bypasses cache',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final completer = Completer<LyricDocument?>();
      final remote = _FakeLyricsSdk(() => completer.future);
      final repository = LyricsRepository(remote, database);

      final first = repository.load(song);
      final second = repository.load(song);
      await Future<void>.delayed(Duration.zero);
      expect(remote.calls, 1);
      completer.complete(lyrics);
      await Future.wait([first, second]);

      final refreshed = _FakeLyricsSdk(() async => null);
      expect(
        await LyricsRepository(
          refreshed,
          database,
        ).load(song, forceRefresh: true),
        isNull,
      );
      expect(refreshed.calls, 1);
    },
  );
}

class _FakeLyricsSdk implements LyricsSdk {
  _FakeLyricsSdk(this.loader);

  final Future<LyricDocument?> Function() loader;
  int calls = 0;

  @override
  Future<LyricDocument?> fetchLyrics(Song song) {
    calls += 1;
    return loader();
  }
}
