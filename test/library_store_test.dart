import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_models.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/models/song.dart';

void main() {
  late AppDatabase database;
  late LibraryStore store;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    store = LibraryStore(database);
    await store.replaceBaseline(
      userId: 7,
      playlists: const [_favoritePlaylist],
      loadedTracks: const {'remote:2': []},
      history: const [],
    );
  });

  tearDown(() => database.close());

  test('favorite changes locally before any remote work', () async {
    await store.toggleFavorite(songA);

    expect((await store.watchFavoriteSongs().first).single.id, songA.id);
    final operation = (await store.readyOperations()).single;
    expect(operation.operation, LibraryOperation.playlistTrack);
    expect(_payload(operation)['desired'], isTrue);
  });

  test('rapid favorite changes keep one final outbox intent', () async {
    await store.toggleFavorite(songA);
    await store.toggleFavorite(songA);

    expect(await store.watchFavoriteSongs().first, isEmpty);
    final operations = await store.readyOperations();
    expect(operations, hasLength(1));
    expect(_payload(operations.single)['desired'], isFalse);
    expect(_payload(operations.single)['verify'], isTrue);
  });

  test('new local track stays ahead of newest-first remote tracks', () async {
    await store.replacePlaylistTracks('remote:2', const [songA, songB]);

    await store.setTrackMembership('remote:2', songC, present: true);
    await store.setTrackMembership('remote:2', songD, present: true);

    expect((await store.watchFavoriteSongs().first).map((song) => song.id), [
      songD.id,
      songC.id,
      songA.id,
      songB.id,
    ]);
  });

  test('remote refresh cannot overwrite pending local favorite', () async {
    await store.toggleFavorite(songA);

    await store.applyRemoteSnapshot(
      userId: 7,
      playlists: const [_favoritePlaylist],
      loadedTracks: const {'remote:2': []},
      history: const [],
    );

    expect((await store.watchFavoriteSongs().first).single.id, songA.id);
    expect(await store.pendingCount(), 1);
  });

  test('playlist edits collapse into one latest operation', () async {
    final localId = await store.createPlaylist('第一版', private: false);
    await store.editPlaylist(
      localId,
      name: '最终名称',
      intro: '简介',
      tags: '流行',
      private: true,
    );

    final playlist = await store.playlist(localId);
    expect(playlist?.name, '最终名称');
    expect(playlist?.isPrivate, isTrue);
    final operations = await store.readyOperations();
    expect(operations, hasLength(1));
    expect(operations.single.operation, LibraryOperation.playlistUpsert);
    expect(operations.single.revision, 2);
  });

  test('logout-style clear removes library and pending operations', () async {
    await store.toggleFavorite(songA);
    await store.recordPlayed(songA);

    await store.clearLibrary();

    expect(await store.watchFavoriteSongs().first, isEmpty);
    expect(await store.watchHistory().first, isEmpty);
    expect(await store.pendingCount(), 0);
    expect(await store.syncState, isNull);
  });
}

const _favoritePlaylist = LibraryPlaylist(
  localId: 'remote:2',
  remoteListId: 2,
  name: '我喜欢',
  count: 0,
  isPrivate: true,
  isMyFavorite: true,
  isDefaultCollect: false,
  tracksLoaded: true,
);

const songA = Song(
  id: 'mix:42',
  title: 'Song A',
  mixSongId: 42,
  hashes: AudioHashes(standard: 'hash-a'),
);

const songB = Song(
  id: 'mix:43',
  title: 'Song B',
  mixSongId: 43,
  hashes: AudioHashes(standard: 'hash-b'),
);

const songC = Song(
  id: 'mix:44',
  title: 'Song C',
  mixSongId: 44,
  hashes: AudioHashes(standard: 'hash-c'),
);

const songD = Song(
  id: 'mix:45',
  title: 'Song D',
  mixSongId: 45,
  hashes: AudioHashes(standard: 'hash-d'),
);

Map<String, Object?> _payload(PendingLibraryOperation operation) =>
    (jsonDecode(operation.payload) as Map).cast<String, Object?>();
