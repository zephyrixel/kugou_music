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
    expect(await store.watchFavoriteSongs().first, isEmpty);
    expect(sdk.trackCalls, isEmpty);
    await sync.ensureFavoriteLoaded();
    expect((await store.watchFavoriteSongs().first).single.id, remoteSong.id);
    expect(sdk.trackCalls, ['gid:2:1']);
    await sync.sync(pullRemote: true, force: true);
    expect(sdk.trackCalls, ['gid:2:1']);
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

  test(
    'account refresh does not reload tracks of an opened playlist',
    () async {
      sdk.playlists = const [_favoritePlaylist, _customPlaylist];
      sdk.tracksByListId[4] = const [localSong];
      await sync.activate(99);
      await sync.ensurePlaylistLoaded('remote:4');
      expect(sdk.trackCalls, ['gid:4:1']);

      sdk.playlists = const [_favoritePlaylist, _customPlaylistUpdated];
      await sync.sync(pullRemote: true, force: true);

      expect(sdk.trackCalls, ['gid:4:1']);
      expect(
        (await store.watchPlaylistTracks('remote:4').first).single.id,
        localSong.id,
      );
      expect((await store.playlist('remote:4'))?.count, 2);
    },
  );

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

  test(
    'history reaches newer cursor pages before keeping latest 100',
    () async {
      sdk.playlists = const [_favoritePlaylist];
      sdk.tracksByListId[2] = const [];
      final start = DateTime.utc(2026, 1, 1);
      final older = List.generate(
        100,
        (index) =>
            _historyEntry(1000 + index, start.add(Duration(minutes: index))),
      );
      final newest = _historyEntry(2000, DateTime.utc(2026, 1, 2));
      sdk.historyPages[null] = CloudHistoryPage(
        items: older,
        cursor: 'newer',
        hasMore: true,
        total: 101,
      );
      sdk.historyPages['newer'] = CloudHistoryPage(
        items: [newest],
        hasMore: false,
        total: 101,
      );

      await sync.activate(99);

      final history = await store.watchHistory().first;
      expect(sdk.historyCursors, [null, 'newer']);
      expect(history, hasLength(100));
      expect(history.first.song.id, newest.song.id);
      expect(
        history.map((entry) => entry.song.id),
        isNot(contains('mix:1000')),
      );
    },
  );

  test(
    'missing gid file id is recovered through listid before removal',
    () async {
      sdk.playlists = const [_favoritePlaylist];
      sdk.tracksByListId[2] = const [remoteSongWithoutFileId];
      sdk.physicalTracksByListId[2] = [
        ...List.generate(100, _physicalDecoy),
        remotePhysicalSong,
      ];
      await sync.activate(99);
      await sync.ensureFavoriteLoaded();
      await store.toggleFavorite(remoteSongWithoutFileId);

      await sync.sync();

      expect(sdk.calls, ['physical:2:1', 'physical:2:2', 'remove:2:420']);
      expect(await store.pendingCount(), 0);
    },
  );

  test(
    'removal remains pending when listid cannot provide a file id',
    () async {
      sdk.playlists = const [_favoritePlaylist];
      sdk.tracksByListId[2] = const [remoteSongWithoutFileId];
      sdk.physicalTracksByListId[2] = const [remoteSongWithoutFileId];
      await sync.activate(99);
      await sync.ensureFavoriteLoaded();
      await store.toggleFavorite(remoteSongWithoutFileId);

      await sync.sync();

      expect(sdk.calls, ['physical:2:1']);
      expect(await store.pendingCount(), 1);
      expect(sync.status.failed, isTrue);
    },
  );

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
    expect(await store.watchFavoriteSongs().first, isEmpty);
    await sync.ensureFavoriteLoaded();
    expect(
      (await store.watchFavoriteSongs().first).single.id,
      secondAccountSong.id,
    );
  });
}

const _favoritePlaylist = CloudPlaylist(
  listId: 2,
  globalCollectionId: 'collection_3_99_2_0',
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

const remoteSongWithoutFileId = Song(
  id: 'mix:42',
  title: 'Remote Song',
  mixSongId: 42,
  hashes: AudioHashes(standard: 'remote-hash'),
);

const remotePhysicalSong = Song(
  id: 'physical:42',
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

const _customPlaylist = CloudPlaylist(
  listId: 4,
  globalCollectionId: 'collection_3_99_4_0',
  name: '自建歌单',
  count: 1,
  isPrivate: false,
  isMyFavorite: false,
  isDefaultCollect: false,
  listType: 0,
);

const _customPlaylistUpdated = CloudPlaylist(
  listId: 4,
  globalCollectionId: 'collection_3_99_4_0',
  name: '自建歌单',
  count: 2,
  isPrivate: false,
  isMyFavorite: false,
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

CloudHistoryEntry _historyEntry(int mixSongId, DateTime playedAt) =>
    CloudHistoryEntry(
      song: Song(
        id: 'mix:$mixSongId',
        title: 'History $mixSongId',
        mixSongId: mixSongId,
        hashes: AudioHashes(standard: 'history-$mixSongId'),
      ),
      playedAt: playedAt,
      playCount: 1,
    );

Song _physicalDecoy(int index) => Song(
  id: 'mix:${3000 + index}',
  title: 'Physical $index',
  mixSongId: 3000 + index,
  fileId: 5000 + index,
  hashes: AudioHashes(standard: 'physical-$index'),
);

class _FakeMusicSdk implements MusicSdk {
  List<CloudPlaylist> playlists = const [];
  final Map<int, List<Song>> tracksByListId = {};
  final Map<int, List<Song>> physicalTracksByListId = {};
  List<CloudHistoryEntry> historyItems = const [];
  final Map<String?, CloudHistoryPage> historyPages = {};
  final List<String?> historyCursors = [];
  final List<String> calls = [];
  final List<String> trackCalls = [];
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
    trackCalls.add('gid:${playlist.listId}:$page');
    final songs = tracksByListId[playlist.listId] ?? const [];
    return _page(songs, page: page, pageSize: pageSize);
  }

  @override
  Future<SearchPage> playlistTracksByListId(
    int listId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    calls.add('physical:$listId:$page');
    return _page(
      physicalTracksByListId[listId] ?? const [],
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<CloudHistoryPage> cloudHistory({String? cursor}) async {
    historyCursors.add(cursor);
    final configured = historyPages[cursor];
    if (configured != null) return configured;
    return CloudHistoryPage(
      items: cursor == null ? historyItems : const [],
      hasMore: false,
    );
  }

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
  Future<void> removeSongFromPlaylist(int listId, int fileId) async {
    calls.add('remove:$listId:$fileId');
  }

  @override
  Future<void> uploadHistory(List<CloudHistoryUpload> items) async {
    historyUploads.addAll(items);
  }

  SearchPage _page(
    List<Song> songs, {
    required int page,
    required int pageSize,
  }) {
    final start = (page - 1) * pageSize;
    final items = start >= songs.length
        ? const <Song>[]
        : songs.skip(start).take(pageSize).toList(growable: false);
    return SearchPage(
      songs: items,
      page: page,
      pageSize: pageSize,
      total: songs.length,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
