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

Map<String, Object?> _payload(PendingLibraryOperation operation) =>
    (jsonDecode(operation.payload) as Map).cast<String, Object?>();
