import 'dart:convert';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/player/playback_queue_store.dart';

void main() {
  const song = Song(
    id: 'song:1',
    title: '测试歌曲',
    artist: '测试歌手',
    hashes: AudioHashes(standard: 'hash'),
  );

  test(
    'v8 queue migrates with frozen enum values and survives cache cleanup',
    () async {
      final legacy = sqlite.sqlite3.openInMemory();
      legacy.execute(
        'CREATE TABLE cached_responses (cache_key TEXT PRIMARY KEY, account_user_id INTEGER, codec_version INTEGER, payload TEXT, updated_at INTEGER, last_accessed_at INTEGER)',
      );
      legacy.execute('INSERT INTO cached_responses VALUES (?, ?, ?, ?, ?, ?)', [
        'player/queue/v1/7',
        7,
        1,
        jsonEncode({
          'origin': {'kind': 2, 'title': 'Search', 'id': 'test'},
          'songs': [
            {
              'id': 'a',
              'title': 'A',
              'hashes': {'standard': 'a'},
            },
          ],
          'currentIndex': 0,
          'order': 3,
          'positionMs': 3000,
        }),
        1,
        1,
      ]);
      legacy.execute('PRAGMA user_version = 8');
      final database = AppDatabase.forTesting(NativeDatabase.opened(legacy));
      addTearDown(database.close);
      final store = PlaybackQueueStore(database);
      final restored = await store.read(7);
      expect(restored, isNotNull);
      expect(restored!.order, PlaybackOrder.shuffle);
      expect(restored.request.origin.kind, PlaybackQueueOriginKind.search);
      expect(restored.positionMs, 3000);
      await database.clearResponseCache();
      await database.pruneResponseCache(maxEntries: 0);
      expect(await store.read(7), isNotNull);
      await store.write(7, restored);
      final row = await database
          .select(database.storedPlaybackQueues)
          .getSingle();
      expect(jsonDecode(row.payload)['order'], 'shuffle');
      expect(row.codecVersion, 2);
    },
  );

  test(
    'queue snapshot preserves source, order and playback position',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final store = PlaybackQueueStore(database);
      final request = PlaybackQueueRequest(
        origin: const PlaybackQueueOrigin(
          kind: PlaybackQueueOriginKind.search,
          title: '搜索：测试',
          id: '测试',
          totalCount: 20,
        ),
        songs: const [song],
        nextPage: 2,
        hasMore: true,
        pageSize: 20,
      );

      await store.write(
        7,
        PlaybackQueueSnapshot(
          request: request,
          currentIndex: 0,
          order: PlaybackOrder.shuffle,
          positionMs: 12345,
        ),
      );

      final restored = await store.read(7);
      expect(restored, isNotNull);
      expect(restored!.request.origin.title, '搜索：测试');
      expect(restored.request.songs.single.title, song.title);
      expect(restored.request.nextPage, 2);
      expect(restored.request.hasMore, isTrue);
      expect(restored.order, PlaybackOrder.shuffle);
      expect(restored.positionMs, 12345);
    },
  );

  test('queue snapshots are isolated by account', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final store = PlaybackQueueStore(database);
    final request = PlaybackQueueRequest.snapshot(
      title: '我喜欢',
      songs: const [song],
      kind: PlaybackQueueOriginKind.favorites,
    );

    await store.write(
      1,
      PlaybackQueueSnapshot(
        request: request,
        currentIndex: 0,
        order: PlaybackOrder.repeatAll,
      ),
    );

    expect(await store.read(2), isNull);
    expect(await store.read(1), isNotNull);
  });

  test('discovery queues preserve their server title and card id', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final store = PlaybackQueueStore(database);
    final request = PlaybackQueueRequest.snapshot(
      title: '小众宝藏佳作',
      id: '3004',
      songs: const [song],
      kind: PlaybackQueueOriginKind.discovery,
    );

    await store.write(
      7,
      PlaybackQueueSnapshot(
        request: request,
        currentIndex: 0,
        order: PlaybackOrder.sequential,
      ),
    );

    final restored = await store.read(7);
    expect(restored!.request.origin.kind, PlaybackQueueOriginKind.discovery);
    expect(restored.request.origin.title, '小众宝藏佳作');
    expect(restored.request.origin.id, '3004');
    expect(restored.request.hasMore, isFalse);
  });
}
