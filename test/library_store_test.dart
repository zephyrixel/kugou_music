import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';

void main() {
  late AppDatabase database;
  late LibraryStore store;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    store = LibraryStore(database);
    await store.replaceLibrary(
      userId: 7,
      playlists: const [_favoritePlaylist],
      history: const [],
    );
  });

  tearDown(() => database.close());

  test('favorite membership is optimistic and reversible', () async {
    final snapshot = await store.setTrackMembershipLocal(
      'remote:2',
      songA,
      present: true,
    );
    expect(snapshot.wasPresent, isFalse);
    expect((await store.watchFavoriteSongs().first).single.id, songA.id);

    await store.restoreTrackMembership(
      'remote:2',
      songA,
      present: false,
      fileId: null,
      count: snapshot.previousCount,
      snapshotCount: snapshot.previousSnapshotCount,
    );
    expect(await store.watchFavoriteSongs().first, isEmpty);
  });

  test('new local track stays ahead of newest-first remote tracks', () async {
    await store.replacePlaylistTracks('remote:2', const [songA, songB]);

    await store.setTrackMembershipLocal('remote:2', songC, present: true);
    await store.setTrackMembershipLocal('remote:2', songD, present: true);

    expect((await store.watchFavoriteSongs().first).map((song) => song.id), [
      songD.id,
      songC.id,
      songA.id,
      songB.id,
    ]);
  });

  test(
    'metadata count changes preserve tracks but mark snapshot stale',
    () async {
      await store.replacePlaylistTracks('remote:2', const [songA]);
      expect((await store.watchFavoriteSongs().first).single.id, songA.id);

      await store.replaceLibrary(
        userId: 7,
        playlists: const [_favoritePlaylist],
        history: const [],
      );

      final favorite = await store.favoritePlaylist();
      expect(favorite?.tracksLoaded, isFalse);
      expect((await store.watchFavoriteSongs().first).single.id, songA.id);
    },
  );

  test(
    'complete snapshot replacement never exposes an empty favorite list',
    () async {
      await store.replacePlaylistTracks('remote:2', const [songA]);
      final snapshots = <List<String>>[];
      final subscription = store.watchFavoriteSongs().listen(
        (songs) => snapshots.add(songs.map((song) => song.id).toList()),
      );
      await Future<void>.delayed(Duration.zero);

      await store.replacePlaylistTracks('remote:2', const [songB, songC]);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(snapshots, isNot(contains(isEmpty)));
      expect(snapshots.last, [songB.id, songC.id]);
    },
  );

  test('recordPlayed updates history order', () async {
    await store.recordPlayed(songA, playedAt: DateTime.utc(2026, 7, 1));
    await store.recordPlayed(songB, playedAt: DateTime.utc(2026, 7, 2));

    final history = await store.watchHistory().first;
    expect(history.map((item) => item.song.id), [songB.id, songA.id]);
  });

  test('完成分页快照会清理云端缩短后留下的旧行', () async {
    await store.replacePlaylistTracks('remote:2', const [songA, songB, songC]);

    await store.finishPlaylistSnapshot('remote:2', remoteTotalCount: 2);

    expect(
      (await store.watchPlaylistTracks('remote:2').first).map(
        (song) => song.id,
      ),
      [songA.id, songB.id],
    );
    expect((await store.playlist('remote:2'))?.trackSnapshotCount, 2);
  });

  test('歌单列表按系统歌单置顶 + 创建时间新到旧排序', () async {
    await store.replaceLibrary(
      userId: 7,
      playlists: [
        // Wire order is oldest-first; the read model must invert it.
        _playlist('remote:10', '最旧', createdAt: DateTime.utc(2024, 1, 1)),
        _playlist('remote:11', '较新', createdAt: DateTime.utc(2025, 6, 1)),
        _playlist('remote:12', '最新', createdAt: DateTime.utc(2026, 3, 1)),
        _favoritePlaylist,
      ],
      history: const [],
    );

    expect((await store.watchPlaylists().first).map((item) => item.name), [
      '我喜欢',
      '最新',
      '较新',
      '最旧',
    ]);
  });

  test('缺少创建时间的旧数据落在有时间戳的歌单之后', () async {
    await store.replaceLibrary(
      userId: 7,
      playlists: [
        _playlist('remote:20', '无时间戳A'),
        _playlist('remote:21', '无时间戳B'),
        _playlist('remote:22', '有时间戳', createdAt: DateTime.utc(2020, 1, 1)),
      ],
      history: const [],
    );

    // Rows without createdAt keep their stable wire order at the end rather
    // than floating to the top.
    expect((await store.watchPlaylists().first).map((item) => item.name), [
      '有时间戳',
      '无时间戳A',
      '无时间戳B',
    ]);
  });

  test('新建歌单出现在列表顶部而不是底部', () async {
    await store.replaceLibrary(
      userId: 7,
      playlists: [
        _favoritePlaylist,
        _playlist('remote:30', '已有歌单', createdAt: DateTime.utc(2025, 1, 1)),
      ],
      history: const [],
    );

    await store.upsertPlaylist(_playlist('remote:31', '刚建的歌单'));

    expect((await store.watchPlaylists().first).map((item) => item.name), [
      '我喜欢',
      '刚建的歌单',
      '已有歌单',
    ]);
  });

  test('云端同步不会把本地新建歌单的创建时间抹掉', () async {
    await store.upsertPlaylist(_playlist('remote:40', '本地新建'));
    final stamped = (await store.playlist('remote:40'))?.createdAt;
    expect(stamped, isNotNull);

    // A later sync returns the same list without create_time.
    await store.replaceLibrary(
      userId: 7,
      playlists: [
        _playlist('remote:41', '更旧的云端歌单', createdAt: DateTime.utc(2024, 1, 1)),
        _playlist('remote:40', '本地新建'),
      ],
      history: const [],
    );

    expect((await store.playlist('remote:40'))?.createdAt, stamped);
    expect((await store.watchPlaylists().first).first.name, '本地新建');
  });
}

Playlist _playlist(String localId, String name, {DateTime? createdAt}) =>
    Playlist(
      localId: localId,
      listId: int.parse(localId.split(':').last),
      name: name,
      isPrivate: false,
      isMyFavorite: false,
      isDefaultCollect: false,
      createdAt: createdAt,
    );

const _favoritePlaylist = Playlist(
  localId: 'remote:2',
  listId: 2,
  name: '我喜欢',
  isPrivate: false,
  isMyFavorite: true,
  isDefaultCollect: false,
  tracksLoaded: false,
  count: 0,
);

const songA = Song(id: 'a', title: 'A', hashes: AudioHashes());
const songB = Song(id: 'b', title: 'B', hashes: AudioHashes());
const songC = Song(id: 'c', title: 'C', hashes: AudioHashes());
const songD = Song(id: 'd', title: 'D', hashes: AudioHashes());
