import 'package:drift/native.dart';
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
