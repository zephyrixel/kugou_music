import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/library/library_sync_service.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/native/music_sdk_models.dart';

void main() {
  late AppDatabase database;
  late LibraryStore store;
  late _FakeMusicSdk sdk;
  late LibrarySyncService sync;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    store = LibraryStore(database);
    sdk = _FakeMusicSdk();
    sync = LibrarySyncService(sdk, store);
  });

  tearDown(() async {
    await sync.dispose();
    await database.close();
  });

  test('first activation replaces local state with cloud baseline', () async {
    await store.createPlaylist('旧本地歌单', private: false);
    sdk.playlists = const [_favoritePlaylist];
    sdk.tracksByListId[2] = const [remoteSong];
    sdk.historyItems = [
      CloudHistoryEntry(
        song: remoteSong,
        playedAt: DateTime.utc(2026, 7, 15),
        playCount: 4,
      ),
    ];

    await sync.activate(99);

    final playlists = await store.watchPlaylists().first;
    expect(playlists.map((item) => item.name), ['我喜欢']);
    expect((await store.watchFavoriteSongs().first).single.id, remoteSong.id);
    expect((await store.watchHistory().first).single.playCount, 4);
    expect((await store.syncState)?.userId, 99);
    expect(await store.pendingCount(), 0);
  });

  test('playlist creation is sent before its queued track', () async {
    sdk.playlists = const [_favoritePlaylist];
    sdk.tracksByListId[2] = const [];
    await sync.activate(99);
    final localId = await store.createPlaylist('离线歌单', private: true);
    await store.setTrackMembership(localId, localSong, present: true);

    await sync.sync();

    expect(sdk.calls, ['create:离线歌单', 'add:88:${localSong.id}']);
    expect((await store.playlist(localId))?.remoteListId, 88);
    expect(await store.pendingCount(), 0);
  });

  test('history records upload as one latest count', () async {
    sdk.playlists = const [_favoritePlaylist];
    sdk.tracksByListId[2] = const [];
    await sync.activate(99);
    await store.recordPlayed(localSong, playedAt: DateTime.utc(2026, 7, 15));
    await store.recordPlayed(localSong, playedAt: DateTime.utc(2026, 7, 15, 1));

    await sync.sync();

    expect(sdk.historyUploads, hasLength(1));
    expect(sdk.historyUploads.single.mixSongId, 77);
    expect(sdk.historyUploads.single.playCount, 2);
    expect(await store.pendingCount(), 0);
  });

  test('remote failure keeps local state and pending operation', () async {
    sdk.playlists = const [_favoritePlaylist];
    sdk.tracksByListId[2] = const [];
    await sync.activate(99);
    sdk.failAdds = true;
    await store.toggleFavorite(localSong);

    await sync.sync();

    expect((await store.watchFavoriteSongs().first).single.id, localSong.id);
    expect(await store.pendingCount(), 1);
    expect(sync.status.failed, isTrue);
  });

  test('stale account baseline cannot overwrite the active account', () async {
    final gate = Completer<void>();
    final started = Completer<void>();
    sdk.playlists = const [_favoritePlaylist];
    sdk.tracksByListId[2] = const [remoteSong];
    sdk.nextCloudPlaylistsGate = gate;
    sdk.nextCloudPlaylistsStarted = started;

    final staleActivation = sync.activate(1);
    await started.future;

    sdk.playlists = const [_secondFavoritePlaylist];
    sdk.tracksByListId[3] = const [secondAccountSong];
    await sync.activate(2);

    gate.complete();
    await staleActivation;

    expect((await store.syncState)?.userId, 2);
    expect((await store.watchPlaylists().first).map((item) => item.name), [
      '第二账号的我喜欢',
    ]);
    expect(
      (await store.watchFavoriteSongs().first).single.id,
      secondAccountSong.id,
    );
  });
}

const _favoritePlaylist = CloudPlaylist(
  listId: 2,
  name: '我喜欢',
  isPrivate: true,
  isMyFavorite: true,
  isDefaultCollect: false,
  listType: 0,
);

const remoteSong = Song(
  id: 'mix:42',
  title: 'Remote Song',
  mixSongId: 42,
  fileId: 420,
  hashes: AudioHashes(standard: 'remote-hash'),
);

const _secondFavoritePlaylist = CloudPlaylist(
  listId: 3,
  name: '第二账号的我喜欢',
  isPrivate: true,
  isMyFavorite: true,
  isDefaultCollect: false,
  listType: 0,
);

const secondAccountSong = Song(
  id: 'mix:84',
  title: 'Second Account Song',
  mixSongId: 84,
  fileId: 840,
  hashes: AudioHashes(standard: 'second-account-hash'),
);

const localSong = Song(
  id: 'mix:77',
  title: 'Local Song',
  mixSongId: 77,
  hashes: AudioHashes(standard: 'local-hash'),
);

class _FakeMusicSdk implements MusicSdk {
  List<CloudPlaylist> playlists = const [];
  final Map<int, List<Song>> tracksByListId = {};
  List<CloudHistoryEntry> historyItems = const [];
  final List<String> calls = [];
  final List<CloudHistoryUpload> historyUploads = [];
  bool failAdds = false;
  Completer<void>? nextCloudPlaylistsGate;
  Completer<void>? nextCloudPlaylistsStarted;

  @override
  Future<CloudPlaylistPage> cloudPlaylists({
    int page = 1,
    int pageSize = 50,
  }) async {
    final List<CloudPlaylist> items = page == 1
        ? List<CloudPlaylist>.of(playlists)
        : const <CloudPlaylist>[];
    final gate = page == 1 ? nextCloudPlaylistsGate : null;
    if (gate != null) {
      nextCloudPlaylistsGate = null;
      final started = nextCloudPlaylistsStarted;
      nextCloudPlaylistsStarted = null;
      if (started != null && !started.isCompleted) started.complete();
      await gate.future;
    }
    return CloudPlaylistPage(
      items: items,
      page: page,
      pageSize: pageSize,
      total: items.length,
    );
  }

  @override
  Future<SearchPage> playlistTracks(
    CloudPlaylist playlist, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final songs = tracksByListId[playlist.listId] ?? const [];
    return SearchPage(
      songs: page == 1 ? songs : const [],
      page: page,
      pageSize: pageSize,
      total: songs.length,
    );
  }

  @override
  Future<CloudHistoryPage> cloudHistory({String? cursor}) async =>
      CloudHistoryPage(
        items: cursor == null ? historyItems : const [],
        hasMore: false,
      );

  @override
  Future<PlaylistMutation> createPlaylist(
    String name, {
    required bool private,
  }) async {
    calls.add('create:$name');
    playlists = [
      ...playlists,
      CloudPlaylist(
        listId: 88,
        name: name,
        isPrivate: private,
        isMyFavorite: false,
        isDefaultCollect: false,
        listType: 0,
      ),
    ];
    tracksByListId[88] = [];
    return const PlaylistMutation(listId: 88);
  }

  @override
  Future<PlaylistTracksMutation> addSongToPlaylist(
    int listId,
    Song song,
  ) async {
    calls.add('add:$listId:${song.id}');
    if (failAdds) throw const MusicSdkException('offline', retryable: true);
    final saved = Song(
      id: song.id,
      title: song.title,
      mixSongId: song.mixSongId,
      fileId: 900,
      hashes: song.hashes,
    );
    tracksByListId[listId] = [...?tracksByListId[listId], saved];
    return const PlaylistTracksMutation(fileIds: [900]);
  }

  @override
  Future<void> uploadHistory(List<CloudHistoryUpload> items) async {
    historyUploads.addAll(items);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
