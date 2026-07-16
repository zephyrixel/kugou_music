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
}

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
