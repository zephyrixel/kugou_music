import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_remote.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/history_entry.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/native/music_sdk_models.dart';

void main() {
  late AppDatabase database;
  late LibraryStore store;
  late _FakeMusicSdk sdk;
  late LibraryRepository library;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    store = LibraryStore(database);
    sdk = _FakeMusicSdk();
    library = LibraryRepository(store, LibraryRemote(sdk));
  });

  tearDown(() async {
    await library.dispose();
    await database.close();
  });

  test('first activation replaces local state with cloud baseline', () async {
    sdk.playlists = const [_favoritePlaylist];
    sdk.tracksByListId[2] = const [remoteSong];
    sdk.historyItems = [
      HistoryEntry(
        song: remoteSong,
        playedAt: DateTime.utc(2026, 7, 15),
        playCount: 4,
      ),
    ];

    await library.activate(99);

    final playlists = await store.watchPlaylists().first;
    expect(playlists.map((item) => item.name), ['我喜欢']);
    expect(await store.watchFavoriteSongs().first, isEmpty);
    expect(sdk.trackCalls, isEmpty);
    await library.ensureFavoriteLoaded();
    expect((await store.watchFavoriteSongs().first).single.id, remoteSong.id);
    expect(sdk.trackCalls, ['gid:2:1']);
    await library.syncNow();
    expect(sdk.trackCalls, ['gid:2:1']);
    expect((await store.watchHistory().first).single.playCount, 4);
    expect((await store.syncState)?.userId, 99);
  });

  test('playlist creation is cloud-first then add works', () async {
    sdk.playlists = const [_favoritePlaylist];
    sdk.tracksByListId[2] = const [];
    await library.activate(99);

    final localId = await library.createPlaylist('新歌单', private: true);
    expect(localId, 'remote:88');
    expect((await store.playlist(localId))?.listId, 88);
    expect(sdk.calls, ['create:新歌单']);

    await library.addSong(localId, localSong);
    expect(sdk.calls, ['create:新歌单', 'add:88:${localSong.id}']);
    expect(
      (await store.watchPlaylistTracks(localId).first).single.id,
      localSong.id,
    );
  });

  test(
    'account refresh does not reload tracks of an opened playlist',
    () async {
      sdk.playlists = const [_favoritePlaylist, _customPlaylist];
      sdk.tracksByListId[4] = const [localSong];
      await library.activate(99);
      await library.ensurePlaylistLoaded('remote:4');
      expect(sdk.trackCalls, ['gid:4:1']);

      sdk.playlists = const [_favoritePlaylist, _customPlaylistUpdated];
      await library.syncNow();
      expect(sdk.trackCalls, ['gid:4:1']);
      final playlist = await store.playlist('remote:4');
      expect(playlist?.name, '更新后的歌单');
      expect(playlist?.tracksLoaded, isTrue);
      expect(
        (await store.watchPlaylistTracks('remote:4').first).single.id,
        localSong.id,
      );
    },
  );

  test('playlist tracks load page-by-page into Drift', () async {
    sdk.playlists = const [_favoritePlaylist, _customPlaylist];
    sdk.tracksByListId[4] = [
      for (var i = 0; i < 5; i++)
        Song(
          id: 'p-$i',
          title: 'P$i',
          mixSongId: 700 + i,
          hashes: AudioHashes(standard: 'p$i'),
        ),
    ];
    sdk.tracksPageSize = 2;
    await library.activate(99);

    final progressive = <int>[];
    final sub = store.watchPlaylistTracks('remote:4').listen((songs) {
      progressive.add(songs.length);
    });

    await library.ensurePlaylistLoaded('remote:4');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(sdk.trackCalls, ['gid:4:1', 'gid:4:2', 'gid:4:3']);
    expect((await store.watchPlaylistTracks('remote:4').first).length, 5);
    expect((await store.playlist('remote:4'))?.tracksLoaded, isTrue);
    // UI should have seen intermediate sizes, not only the final 5.
    expect(progressive.any((n) => n > 0 && n < 5), isTrue);
    expect(progressive.last, 5);
  });

  test('playback queue pages reuse local tracks before network', () async {
    sdk.playlists = const [_favoritePlaylist, _customPlaylist];
    sdk.tracksByListId[4] = [
      for (var i = 0; i < 4; i++)
        Song(
          id: 'queue-$i',
          title: 'Queue$i',
          hashes: AudioHashes(standard: 'queue-hash-$i'),
        ),
    ];
    await library.activate(99);

    final first = await library.playbackQueuePage(
      'remote:4',
      page: 1,
      pageSize: 2,
    );
    final second = await library.playbackQueuePage(
      'remote:4',
      page: 1,
      pageSize: 2,
    );

    expect(first.songs.length, 2);
    expect(
      second.songs.map((song) => song.id),
      first.songs.map((song) => song.id),
    );
    expect(sdk.trackCalls, ['gid:4:1']);
  });

  test('failed favorite rolls back local membership', () async {
    sdk.playlists = const [_favoritePlaylist];
    sdk.tracksByListId[2] = const [];
    sdk.addShouldFail = true;
    await library.activate(99);

    await expectLater(
      library.toggleFavorite(localSong),
      throwsA(isA<StateError>()),
    );
    expect(await store.watchFavoriteSongs().first, isEmpty);
  });

  test('history walk keeps newest entries', () async {
    sdk.playlists = const [_favoritePlaylist];
    sdk.historyPages[null] = HistoryPage(
      items: [
        for (var i = 0; i < 3; i++)
          _historyEntry(100 + i, DateTime.utc(2026, 7, 1 + i)),
      ],
      hasMore: true,
      cursor: 'newer',
    );
    sdk.historyPages['newer'] = HistoryPage(
      items: [
        for (var i = 3; i < 6; i++)
          _historyEntry(100 + i, DateTime.utc(2026, 7, 1 + i)),
      ],
      hasMore: false,
    );

    await library.activate(99);
    final history = await store.watchHistory().first;
    expect(history.first.song.mixSongId, 105);
    expect(history.last.song.mixSongId, 100);
  });

  test('stale account baseline cannot overwrite the active account', () async {
    sdk.playlists = const [_favoritePlaylist];
    final gate = Completer<void>();
    final started = Completer<void>();
    sdk.nextCloudPlaylistsGate = gate;
    sdk.nextCloudPlaylistsStarted = started;

    final first = library.activate(1);
    await started.future;
    await library.activate(2);
    gate.complete();
    await first;

    expect((await store.syncState)?.userId, 2);
  });

  test('recordPlayed uploads history when mixSongId present', () async {
    sdk.playlists = const [_favoritePlaylist];
    await library.activate(99);
    await library.recordPlayed(localSong);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(sdk.historyUploads, isNotEmpty);
    expect(sdk.historyUploads.single.mixSongId, localSong.mixSongId);
  });
}

const _favoritePlaylist = Playlist(
  listId: 2,
  globalCollectionId: 'gid-fav',
  name: '我喜欢',
  isPrivate: false,
  isMyFavorite: true,
  isDefaultCollect: false,
  count: 0,
);

const _customPlaylist = Playlist(
  listId: 4,
  globalCollectionId: 'gid-4',
  name: '自建歌单',
  isPrivate: false,
  isMyFavorite: false,
  isDefaultCollect: false,
  count: 1,
);

const _customPlaylistUpdated = Playlist(
  listId: 4,
  globalCollectionId: 'gid-4',
  name: '更新后的歌单',
  isPrivate: false,
  isMyFavorite: false,
  isDefaultCollect: false,
  count: 1,
);

const remoteSong = Song(
  id: 'remote-1',
  title: '云端歌',
  mixSongId: 420,
  fileId: 420,
  hashes: AudioHashes(standard: 'hash-remote'),
);

const localSong = Song(
  id: 'local-1',
  title: '本机歌',
  mixSongId: 840,
  hashes: AudioHashes(standard: 'hash-local'),
);

HistoryEntry _historyEntry(int mixSongId, DateTime playedAt) => HistoryEntry(
  song: Song(
    id: 'h-$mixSongId',
    title: 'H$mixSongId',
    mixSongId: mixSongId,
    hashes: AudioHashes(standard: 'h$mixSongId'),
  ),
  playedAt: playedAt,
  playCount: 1,
);

class _FakeMusicSdk implements MusicSdk {
  List<Playlist> playlists = const [];
  final Map<int, List<Song>> tracksByListId = {};
  List<HistoryEntry> historyItems = const [];
  final Map<String?, HistoryPage> historyPages = {};
  final List<String> calls = [];
  final List<String> trackCalls = [];
  final List<HistoryUpload> historyUploads = [];
  bool addShouldFail = false;

  /// When set, [playlistTracks] slices [tracksByListId] into pages of this size.
  int? tracksPageSize;
  Completer<void>? nextCloudPlaylistsGate;
  Completer<void>? nextCloudPlaylistsStarted;

  @override
  Future<SdkCapabilities> initialize() async => const SdkCapabilities(
    platform: 'lite',
    songSearch: true,
    playlistSearch: true,
    dailyRecommendation: true,
    smsAuth: true,
    cloudLibrary: true,
    playlistMutations: true,
  );

  @override
  Future<AuthSnapshot> authState() async => const AuthSnapshot(
    authenticated: true,
    userId: 99,
    fingerprintRegistered: true,
  );

  @override
  Future<void> sendSmsCode(String mobile) async {}

  @override
  Future<SmsLoginResult> loginBySms(String mobile, String code) async =>
      SmsLoginResult(auth: await authState());

  @override
  Future<AuthSnapshot> refreshLogin() async => authState();

  @override
  Future<AuthSnapshot> registerDevice() async => authState();

  @override
  Future<void> logout() async {}

  @override
  Future<List<Song>> everydayRecommendations() async => const [];

  @override
  Future<SearchPage> search(
    String keyword, {
    int page = 1,
    int pageSize = 30,
  }) async => const SearchPage(songs: [], page: 1, pageSize: 30);

  @override
  Future<PlaylistSearchPage> searchPlaylists(
    String keyword, {
    int page = 1,
    int pageSize = 30,
  }) async => const PlaylistSearchPage(items: [], page: 1, pageSize: 30);

  @override
  Future<PlaybackResolution> resolve(
    Song song, {
    AudioQuality quality = AudioQuality.standard,
    bool freePreview = false,
  }) async => const UnavailableResolution();

  @override
  Future<UserProfile> userProfile() async =>
      const UserProfile(userId: 99, displayName: 't');

  @override
  Future<UserVip> userVip() async => const UserVip();

  @override
  Future<VipClaimResult> claimDayVip() async => const VipClaimResult();

  @override
  Future<VipUpgradeResult> upgradeDayVip() async => const VipUpgradeResult();

  @override
  Future<VipMonthRecord> monthVipRecord() async => const VipMonthRecord();

  @override
  Future<HistoryPage> cloudHistory({String? cursor}) async {
    if (historyPages.isNotEmpty) {
      return historyPages[cursor] ??
          const HistoryPage(items: [], hasMore: false);
    }
    return HistoryPage(items: historyItems, hasMore: false);
  }

  @override
  Future<void> uploadHistory(List<HistoryUpload> items) async {
    historyUploads.addAll(items);
  }

  @override
  Future<PlaylistPage> cloudPlaylists({int page = 1, int pageSize = 50}) async {
    final gate = page == 1 ? nextCloudPlaylistsGate : null;
    if (page == 1) {
      nextCloudPlaylistsGate = null;
      final started = nextCloudPlaylistsStarted;
      nextCloudPlaylistsStarted = null;
      started?.complete();
    }
    if (gate != null) await gate.future;
    final items = page == 1 ? List<Playlist>.of(playlists) : const <Playlist>[];
    return PlaylistPage(
      items: items,
      page: page,
      pageSize: pageSize,
      total: items.length,
    );
  }

  @override
  Future<SearchPage> playlistTracks(
    Playlist playlist, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final listId = playlist.listId;
    trackCalls.add('gid:${listId ?? playlist.globalCollectionId}:$page');
    return _pageTracks(listId, page: page, pageSize: pageSize);
  }

  @override
  Future<SearchPage> playlistTracksByListId(
    int listId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    trackCalls.add('listid:$listId:$page');
    return _pageTracks(listId, page: page, pageSize: pageSize);
  }

  SearchPage _pageTracks(
    int? listId, {
    required int page,
    required int pageSize,
  }) {
    final all = listId == null
        ? const <Song>[]
        : (tracksByListId[listId] ?? const <Song>[]);
    final size = tracksPageSize ?? pageSize;
    final start = (page - 1) * size;
    if (start >= all.length) {
      return SearchPage(
        songs: const [],
        page: page,
        pageSize: size,
        total: all.length,
      );
    }
    final end = (start + size).clamp(0, all.length);
    return SearchPage(
      songs: all.sublist(start, end),
      page: page,
      pageSize: size,
      total: all.length,
    );
  }

  @override
  Future<SearchPage> publicPlaylistTracks(
    String globalCollectionId, {
    int page = 1,
    int pageSize = 50,
  }) async => const SearchPage(songs: [], page: 1, pageSize: 50);

  @override
  Future<PlaylistMutation> createPlaylist(
    String name, {
    required bool private,
  }) async {
    calls.add('create:$name');
    return const PlaylistMutation(listId: 88, globalCollectionId: 'gid-88');
  }

  @override
  Future<PlaylistMutation> collectPlaylist(PlaylistSearchHit playlist) async {
    calls.add('collect:${playlist.globalCollectionId}');
    return PlaylistMutation(
      listId: 5000,
      globalCollectionId: playlist.globalCollectionId,
    );
  }

  @override
  Future<void> deletePlaylist({
    required int listId,
    required bool collected,
  }) async {
    calls.add('delete:$listId:$collected');
  }

  @override
  Future<void> editPlaylist(PlaylistEditInput input) async {
    calls.add('edit:${input.listId}:${input.name}');
  }

  @override
  Future<PlaylistTracksMutation> addSongToPlaylist(
    int listId,
    Song song,
  ) async {
    if (addShouldFail) throw StateError('add failed');
    calls.add('add:$listId:${song.id}');
    return const PlaylistTracksMutation(fileIds: [900]);
  }

  @override
  Future<void> removeSongFromPlaylist(int listId, int fileId) async {
    calls.add('remove:$listId:$fileId');
  }
}
