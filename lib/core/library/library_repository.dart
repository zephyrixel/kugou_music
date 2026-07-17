import 'dart:async';

import 'package:kgmusic/core/library/library_models.dart';
import 'package:kgmusic/core/library/library_remote.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/library/playlist_track_loader.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/models/history_entry.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/recommendation/recommendation_reporter.dart';

/// Feature-facing library API: Drift read model + online write-back.
class LibraryRepository {
  LibraryRepository(
    LibraryStore store,
    LibraryRemote remote, {
    RecommendationReporter? recommendationReporter,
    DateTime Function()? now,
  }) : _store = store,
       _remote = remote,
       _reporter = recommendationReporter,
       _now = now ?? DateTime.now,
       _trackLoader = PlaylistTrackLoader(store, remote, now: now);

  static const syncCooldown = Duration(minutes: 5);

  final LibraryStore _store;
  final LibraryRemote _remote;
  final RecommendationReporter? _reporter;
  final DateTime Function() _now;
  final PlaylistTrackLoader _trackLoader;

  final StreamController<LibrarySyncStatus> _statuses =
      StreamController.broadcast(sync: true);
  LibrarySyncStatus _status = const LibrarySyncStatus.idle();
  int _generation = 0;
  int? _userId;
  int _membershipVersion = 0;
  Future<void>? _running;
  int? _runningGeneration;
  bool _disposed = false;

  Stream<List<Playlist>> watchPlaylists() => _store.watchPlaylists();
  Stream<List<Song>> watchFavorites() => _store.watchFavoriteSongs();
  Stream<Set<String>> watchFavoriteIds() => _store.watchFavoriteSongIds();
  Stream<List<HistoryEntry>> watchHistory() => _store.watchHistory();
  Stream<List<Song>> watchPlaylistTracks(String localId) =>
      _store.watchPlaylistTracks(localId);

  Future<SearchPage> playbackQueuePage(
    String localId, {
    required int page,
    int pageSize = LibraryRemote.pageSize,
  }) async {
    return loadPlaylistPage(localId, page: page, pageSize: pageSize).first;
  }

  Stream<SearchPage> loadPlaylistPage(
    String localId, {
    required int page,
    int pageSize = LibraryRemote.pageSize,
    bool forceRefresh = false,
  }) {
    final generation = _generation;
    final userId = _userId;
    if (userId == null) return const Stream.empty();
    return _trackLoader.page(
      localId,
      page: page,
      pageSize: pageSize,
      forceRefresh: forceRefresh,
      isCurrent: () => _isCurrent(generation, userId),
    );
  }

  Stream<LibrarySyncStatus> get syncStatuses async* {
    yield _status;
    yield* _statuses.stream;
  }

  LibrarySyncStatus get status => _status;

  Future<void> activate(int userId) async {
    if (_userId != userId) _reporter?.resetSession();
    _trackLoader.cancelAll();
    final generation = ++_generation;
    _userId = userId;
    final state = await _store.syncState;
    if (!_isCurrent(generation, userId)) return;
    if (state != null && state.userId != userId) {
      await _store.clearLibrary();
      if (!_isCurrent(generation, userId)) return;
    }
    final needBaseline =
        state?.userId != userId || state?.baselineComplete != true;
    if (needBaseline) {
      await _sync(generation, userId, wipe: true);
      return;
    }
    final cachedState = state!;
    _emit(
      LibrarySyncStatus(
        phase: LibrarySyncPhase.idle,
        lastSyncedAt: cachedState.lastSyncedAt,
      ),
    );
    if (_syncDue(cachedState.lastSyncedAt)) {
      unawaited(_sync(generation, userId, wipe: false).catchError((_) {}));
    }
  }

  Future<void> deactivate() async {
    _reporter?.resetSession();
    _trackLoader.cancelAll();
    _generation += 1;
    _userId = null;
    await _store.clearLibrary();
    if (!_disposed) _emit(const LibrarySyncStatus.idle());
  }

  Future<void> syncNow() {
    final userId = _userId;
    if (userId == null) return Future.value();
    return _sync(_generation, userId, wipe: false);
  }

  Future<void> syncIfDue() async {
    final userId = _userId;
    if (userId == null) return;
    final state = await _store.syncState;
    if (!_isCurrent(_generation, userId)) return;
    if (state?.userId == userId &&
        state?.baselineComplete == true &&
        !_syncDue(state?.lastSyncedAt)) {
      return;
    }
    await _sync(_generation, userId, wipe: state?.userId != userId);
  }

  Future<void> _sync(int generation, int userId, {required bool wipe}) {
    // Coalesce only same-generation work. A newer activate must not wait on
    // the previous account's in-flight pull (old work dies on _isCurrent).
    final current = _running;
    if (current != null && _runningGeneration == generation) return current;

    late final Future<void> tracked;
    tracked =
        Future(() async {
          if (!_isCurrent(generation, userId)) return;
          _emit(
            LibrarySyncStatus(
              phase: LibrarySyncPhase.syncing,
              lastSyncedAt: _status.lastSyncedAt,
            ),
          );
          try {
            AppLog.info('开始同步音乐库 wipe=$wipe', target: 'library.sync');
            final playlists = await _remote.fetchAllPlaylists();
            if (!_isCurrent(generation, userId)) return;
            final history = await _remote.fetchHistory();
            if (!_isCurrent(generation, userId)) return;
            if (wipe) {
              await _store.clearLibrary();
              if (!_isCurrent(generation, userId)) return;
            }
            await _store.replaceLibrary(
              userId: userId,
              playlists: playlists,
              history: history,
            );
            if (!_isCurrent(generation, userId)) return;
            await _store.setSyncResult(userId: userId);
            if (!_isCurrent(generation, userId)) return;
            _emit(
              LibrarySyncStatus(
                phase: LibrarySyncPhase.idle,
                lastSyncedAt: _now(),
              ),
            );
            AppLog.info(
              '音乐库同步完成 playlists=${playlists.length} history=${history.length}',
              target: 'library.sync',
            );
          } catch (error) {
            AppLog.warn('音乐库同步失败', target: 'library.sync', error: error);
            if (!_isCurrent(generation, userId)) return;
            await _store.setSyncResult(userId: userId, error: error.toString());
            if (!_isCurrent(generation, userId)) return;
            _emit(
              LibrarySyncStatus(
                phase: LibrarySyncPhase.failed,
                lastSyncedAt: _status.lastSyncedAt,
              ),
            );
            rethrow;
          }
        }).whenComplete(() {
          if (identical(_running, tracked)) {
            _running = null;
            _runningGeneration = null;
          }
        });
    _running = tracked;
    _runningGeneration = generation;
    return tracked;
  }

  Future<void> refreshPlaylistSnapshot(String localId) async {
    final generation = _generation;
    final userId = _userId;
    if (userId == null) return;
    final membershipVersion = _membershipVersion;
    await _trackLoader.refreshAll(
      localId,
      isCurrent: () => _isCurrent(generation, userId),
      canCommit: () => membershipVersion == _membershipVersion,
    );
  }

  Future<void> toggleFavorite(Song song) async {
    final favorite = await _store.favoritePlaylist();
    if (favorite?.localId == null || favorite?.listId == null) {
      throw StateError('账号没有可用的“我喜欢”歌单');
    }
    final present = await _store.isTrackMember(favorite!.localId!, song.id);
    await _setMembership(favorite, song, present: !present);
  }

  Future<void> addSong(String playlistLocalId, Song song) async {
    final playlist = await _store.playlist(playlistLocalId);
    if (playlist == null) throw StateError('歌单不存在');
    await _setMembership(playlist, song, present: true);
  }

  Future<void> removeSong(String playlistLocalId, Song song) async {
    final playlist = await _store.playlist(playlistLocalId);
    if (playlist == null) throw StateError('歌单不存在');
    await _setMembership(playlist, song, present: false);
  }

  Future<void> _setMembership(
    Playlist playlist,
    Song song, {
    required bool present,
  }) async {
    _membershipVersion += 1;
    final localId = playlist.localId!;
    final listId = playlist.listId;
    if (listId == null) {
      throw StateError('歌单尚未绑定云端 ID');
    }

    final snapshot = await _store.setTrackMembershipLocal(
      localId,
      song,
      present: present,
    );
    if (snapshot.wasPresent == present) return;

    try {
      if (present) {
        final result = await _remote.addSong(listId, song);
        await _store.markTrackFileId(
          localId,
          song.id,
          fileId: result.fileIds.firstOrNull,
        );
      } else {
        var fileId = snapshot.fileId ?? song.fileId;
        fileId ??= await _remote.findTrackFileId(listId, song);
        if (fileId == null) {
          throw StateError('无法取得删除所需的 fileId');
        }
        await _remote.removeSong(listId, fileId);
      }
      _reporter?.reportFavoriteChanged(song, liked: present);
    } catch (error) {
      await _store.restoreTrackMembership(
        localId,
        song,
        present: snapshot.wasPresent,
        fileId: snapshot.fileId,
        count: snapshot.previousCount,
      );
      rethrow;
    }
  }

  /// Cloud-first create so the row always has a remote listId.
  Future<String> createPlaylist(String name, {required bool private}) async {
    final mutation = await _remote.createPlaylist(name, private: private);
    final localId = Playlist.localIdForRemote(mutation.listId);
    await _store.upsertPlaylist(
      Playlist(
        localId: localId,
        listId: mutation.listId,
        globalCollectionId: mutation.globalCollectionId,
        name: name,
        isPrivate: private,
        isMyFavorite: false,
        isDefaultCollect: false,
        tracksLoaded: true,
        count: 0,
      ),
    );
    return localId;
  }

  Future<String> collectPlaylist(PlaylistSearchHit hit) async {
    final gid = hit.globalCollectionId;
    if (gid == null || gid.isEmpty) {
      throw ArgumentError.value(gid, 'globalCollectionId', '收藏歌单缺少全局 ID');
    }
    final existing = (await _store.watchPlaylists().first)
        .where((item) => item.globalCollectionId == gid)
        .firstOrNull;
    if (existing?.localId != null) return existing!.localId!;

    final mutation = await _remote.collectPlaylist(hit);
    final localId = Playlist.localIdForRemote(mutation.listId);
    await _store.upsertPlaylist(
      Playlist(
        localId: localId,
        listId: mutation.listId,
        globalCollectionId: mutation.globalCollectionId ?? gid,
        name: hit.name,
        intro: hit.intro,
        artworkUrl: hit.artworkUrl,
        count: hit.songCount ?? 0,
        listType: 1,
        creatorUserId: hit.creatorUserId,
        creatorName: hit.creatorName,
        isPrivate: false,
        isMyFavorite: false,
        isDefaultCollect: false,
        tracksLoaded: false,
        tags: hit.tags,
      ),
    );
    return localId;
  }

  Future<void> editPlaylist(
    String localId, {
    required String name,
    required String intro,
    required String tags,
    required bool private,
  }) async {
    final playlist = await _store.playlist(localId);
    if (playlist == null) throw StateError('歌单不存在');
    if (playlist.listId == null) throw StateError('歌单尚未绑定云端 ID');
    if (playlist.isCollected) throw StateError('收藏歌单不可编辑');

    final previous = playlist;
    await _store.updatePlaylistMeta(
      localId,
      name: name,
      intro: intro,
      tags: tags,
      private: private,
    );
    try {
      await _remote.editPlaylist(
        PlaylistEditInput(
          listId: playlist.listId!,
          name: name,
          intro: intro,
          tags: tags,
          private: private,
        ),
      );
    } catch (error) {
      await _store.updatePlaylistMeta(
        localId,
        name: previous.name,
        intro: previous.intro ?? '',
        tags: previous.tags ?? '',
        private: previous.isPrivate,
      );
      rethrow;
    }
  }

  Future<void> deletePlaylist(String localId) async {
    final playlist = await _store.playlist(localId);
    if (playlist == null || playlist.isSystem) return;
    final listId = playlist.listId;
    if (listId != null) {
      await _remote.deletePlaylist(
        listId: listId,
        collected: playlist.isCollected,
      );
    }
    await _store.deletePlaylistLocal(localId);
  }

  Future<void> recordPlayed(Song song) async {
    if (_userId == null) return;
    final entry = await _store.recordPlayed(song);
    final mixSongId = entry.song.mixSongId;
    if (mixSongId == null) return;
    unawaited(
      _remote
          .uploadHistory([
            HistoryUpload(
              mixSongId: mixSongId,
              playedAt: entry.playedAt,
              playCount: entry.playCount,
            ),
          ])
          .catchError((_) {}),
    );
  }

  Future<void> reportRecommendationPlayed(Song song) async {
    if (_userId == null) return;
    _reporter?.reportPlayed(song);
  }

  bool _isCurrent(int generation, int userId) =>
      !_disposed && _generation == generation && _userId == userId;

  bool _syncDue(DateTime? lastSyncedAt) =>
      lastSyncedAt == null || _now().difference(lastSyncedAt) >= syncCooldown;

  void _emit(LibrarySyncStatus value) {
    if (_disposed) return;
    _status = value;
    _statuses.add(value);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _trackLoader.cancelAll();
    _generation += 1;
    _userId = null;
    await _statuses.close();
  }
}
