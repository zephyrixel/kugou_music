import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/recommendation/recommendation_profile_store.dart';

void main() {
  late AppDatabase database;
  late RecommendationProfileStore profiles;
  late LibraryStore library;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    profiles = RecommendationProfileStore(database);
    library = LibraryStore(database);
  });

  tearDown(() => database.close());

  test('120 秒为短播，121 秒为完整向播放且来源位按 OR 合并', () async {
    final at = DateTime(2026, 7, 18, 10);
    await profiles.recordPlayback(
      userId: 7,
      song: songA,
      listened: const Duration(seconds: 120),
      sourceBits: 1,
      occurredAt: at,
    );
    await profiles.recordPlayback(
      userId: 7,
      song: songA,
      listened: const Duration(seconds: 120),
      sourceBits: 128,
      occurredAt: at.add(const Duration(minutes: 1)),
    );
    await profiles.recordPlayback(
      userId: 7,
      song: songA,
      listened: const Duration(seconds: 121),
      sourceBits: 8,
      occurredAt: at.add(const Duration(minutes: 2)),
    );

    final snapshot = await profiles.snapshot(7);
    final short = snapshot.items.singleWhere(
      (item) => item.action == RecommendationProfileAction.playShort,
    );
    final complete = snapshot.items.singleWhere(
      (item) => item.action == RecommendationProfileAction.playComplete,
    );
    expect(short.count, 2);
    expect(short.sourceBits, 129);
    expect(complete.count, 1);
    expect(complete.sourceBits, 8);
  });

  test('sync_point 使用官方周桶作为画像时间下限', () async {
    const epoch = 1514736000000;
    const week = 604800000;
    const cutoff = epoch + week;
    final rawSyncPoint = cutoff + 1234;

    await profiles.recordPlayback(
      userId: 7,
      song: songA,
      listened: const Duration(seconds: 10),
      sourceBits: 1,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(cutoff - 1),
    );
    await profiles.recordPlayback(
      userId: 7,
      song: songB,
      listened: const Duration(seconds: 10),
      sourceBits: 1,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(cutoff),
    );

    final snapshot = await profiles.snapshot(
      7,
      sinceMs: RecommendationProfilePolicy.profileCutoffMs(rawSyncPoint),
    );

    expect(snapshot.items.map((item) => item.standardHash), [
      songB.hashes.standard,
    ]);
    expect(RecommendationProfilePolicy.profileCutoffMs(0), isNull);
  });

  test('完整收藏画像使用实际可用歌曲和真实 collect_time', () async {
    await library.replaceLibrary(
      userId: 7,
      playlists: const [favorite],
      history: const [],
    );
    await library.replacePlaylistTracksAtomic(favorite.localId!, const [
      songA,
      songB,
    ], remoteTotalCount: 3);

    final snapshot = await profiles.snapshot(7);
    final collected = snapshot.items
        .where((item) => item.action == RecommendationProfileAction.collect)
        .toList();
    final stored = await library.favoritePlaylist();

    expect(snapshot.ready, isTrue);
    expect(collected, hasLength(2));
    expect(collected.first.sourceBits, 32);
    expect(
      collected.map((item) => item.eventTimeMs),
      contains(songA.collectTimeSecs! * 1000),
    );
    expect(stored?.count, 3);
    expect(stored?.trackSnapshotCount, 2);
    expect(stored?.tracksLoaded, isTrue);
    expect(stored?.availableTrackCount, 2);
  });

  test('收藏索引未走到终止页时画像保持未就绪', () async {
    await library.replaceLibrary(
      userId: 7,
      playlists: const [favorite],
      history: const [],
    );

    final snapshot = await profiles.snapshot(7);

    expect(snapshot.ready, isFalse);
    expect(snapshot.items, isEmpty);
  });

  test('账号切换时不会把旧账号的收藏带入画像', () async {
    await library.replaceLibrary(
      userId: 7,
      playlists: const [favorite],
      history: const [],
    );
    await library.replacePlaylistTracksAtomic(favorite.localId!, const [
      songA,
    ], remoteTotalCount: 1);

    final snapshot = await profiles.snapshot(8);

    expect(snapshot.ready, isTrue);
    expect(snapshot.items, isEmpty);
  });
}

const favorite = Playlist(
  localId: 'remote:2',
  listId: 2,
  globalCollectionId: 'gid-favorite',
  name: '我喜欢',
  count: 3,
  isPrivate: false,
  isMyFavorite: true,
  isDefaultCollect: false,
);

const songA = Song(
  id: 'a',
  title: 'A',
  collectTimeSecs: 1_700_000_001,
  hashes: AudioHashes(standard: 'hash-a'),
);

const songB = Song(
  id: 'b',
  title: 'B',
  collectTimeSecs: 1_700_000_002,
  hashes: AudioHashes(standard: 'hash-b'),
);
