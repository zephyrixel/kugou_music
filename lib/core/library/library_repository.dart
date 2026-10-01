import 'dart:async';
import 'package:kgmusic/core/auth/account_session.dart';

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
    AccountSession? accountSession,
  }) : _store = store,
       _remote = remote,
       _reporter = recommendationReporter,
       _now = now ?? store.database.now,
       _trackLoader = PlaylistTrackLoader(store, remote, now: now),
       _session = accountSession;

  static const syncCooldown = Duration(minutes: 5);

  final LibraryStore _store;
  final LibraryRemote _remote;
  final RecommendationReporter? _reporter;
  final DateTime Function() _now;
  final PlaylistTrackLoader _trackLoader;
  final AccountSession? _session;

  final StreamController<LibrarySyncStatus> _statuses =
      StreamController.broadcast(sync: true);
  LibrarySyncStatus _status = const LibrarySyncStatus.idle();
  int _generation = 0;
  int? _userId;
  int _membershipVersion = 0;
  Future<void>? _running;
  int? _runningGeneration;
  Future<bool>? _favoriteIndexLoad;
  bool _disposed = false;
  bool _ready = false;
  int _activeMutations = 0;
  bool _resyncRequested = false;
  final Map<String, Future<void>> _mutations = {};

  bool get ready => _ready && _userId != null && !_disposed;
  DateTime Function() get now => _now;

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
    return loadPlaylistPage(localId, page: page, pageSize: pageSize).last;
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
    final version = _membershipVersion;
    return _trackLoader.page(
      localId,
      page: page,
      pageSize: pageSize,
      forceRefresh: forceRefresh,
      isCurrent: () => _isCurrent(generation, userId),
      canCommit: () => version == _membershipVersion && _activeMutations == 0,
    );
  }

  Stream<LibrarySyncStatus> get syncStatuses async* {
    yield _status;
    yield* _statuses.stream;
  }

  LibrarySyncStatus get status => _status;

  Future<void> activate(int userId) async {
    if (_userId != userId) _reporter?.activate(userId);
    _favoriteIndexLoad = null;
    _trackLoader.cancelAll();
    final generation = ++_generation;
    _ready = false;
    _activeMutations = 0;
    _mutations.clear();
    _resyncRequested = false;
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
    _ready = true;
    final cachedState = state!;
    _emit(
      LibrarySyncStatus(
        phase: LibrarySyncPhase.idle,
        lastSyncedAt: cachedState.lastSyncedAt,
      ),
    );
    if (_syncDue(cachedState.lastSyncedAt)) {
      unawaited(_sync(generation, userId, wipe: false).catchError((_) {}));
    } else {
      _scheduleFavoriteIndex();
    }
  }

  Future<void> deactivate() async {
    _generation += 1;
    _userId = null;
    _ready = false;
    _resyncRequested = false;
    _trackLoader.cancelAll();
    await _reporter?.deactivate();
    _favoriteIndexLoad = null;
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
            final version = _membershipVersion;
            final playlists = await _remote.fetchAllPlaylists();
            if (!_isCurrent(generation, userId)) return;
            final history = await _remote.fetchHistory();
            if (!_isCurrent(generation, userId)) return;
            final committed = await _store.database.transaction(() async {
              if (!_isCurrent(generation, userId)) return false;
              if (version != _membershipVersion || _activeMutations != 0) {
                _resyncRequested = true;
                return false;
              }
              if (wipe) await _store.clearLibrary();
              await _store.replaceLibrary(
                userId: userId,
                playlists: playlists,
                history: history,
              );
              return true;
            });
            if (!committed) return;
            _ready = true;
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
            _scheduleFavoriteIndex();
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
            _resumePendingSync();
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
    final committed = await _trackLoader.refreshAll(
      localId,
      isCurrent: () => _isCurrent(generation, userId),
      canCommit: () => membershipVersion == _membershipVersion,
    );
    if (committed) {
      final playlist = await _store.playlist(localId);
      if (playlist?.isMyFavorite == true) _reporter?.notifyProfileReady();
    }
  }

  Future<bool> ensureFavoriteIndex({bool force = false}) {
    final existing = _favoriteIndexLoad;
    if (existing != null) return existing;
    late final Future<bool> tracked;
    tracked = _ensureFavoriteIndex(force: force).whenComplete(() {
      if (identical(_favoriteIndexLoad, tracked)) _favoriteIndexLoad = null;
    });
    _favoriteIndexLoad = tracked;
    return tracked;
  }

  Future<bool> _ensureFavoriteIndex({required bool force}) async {
    final userId = _userId;
    final generation = _generation;
    if (userId == null) return false;
    var favorite = await _store.favoritePlaylist();
    if (!_isCurrent(generation, userId)) return false;
    if (favorite == null) {
      _reporter?.notifyProfileReady();
      return true;
    }
    if (!force &&
        favorite.tracksLoaded &&
        _sameDay(favorite.fullSnapshotUpdatedAt, _now())) {
      _reporter?.notifyProfileReady();
      return true;
    }

    for (var attempt = 0; attempt < 2; attempt += 1) {
      final membershipVersion = _membershipVersion;
      final committed = await _trackLoader.refreshAll(
        favorite!.localId!,
        isCurrent: () => _isCurrent(generation, userId),
        canCommit: () => membershipVersion == _membershipVersion,
      );
      if (!_isCurrent(generation, userId)) return false;
      if (committed) {
        _reporter?.notifyProfileReady();
        return true;
      }
      favorite = await _store.favoritePlaylist();
      if (favorite == null) return true;
    }
    return false;
  }

  void _scheduleFavoriteIndex() {
    unawaited(
      ensureFavoriteIndex().catchError((Object error) {
        AppLog.warn('后台更新“我喜欢”索引失败', target: 'library.favorite', error: error);
        return false;
      }),
    );
  }

  Future<void> toggleFavorite(Song song) => _changeFavorite(song, null);

  /// Preserve the user's requested state even if an earlier queued write rolls back.
  Future<void> setFavorite(Song song, {required bool liked}) =>
      _changeFavorite(song, liked);

  Future<void> _changeFavorite(
    Song song,
    bool? desired,
  ) => _mutate('favorites', (isCurrent) async {
    var favorite = await _store.favoritePlaylist();
    if (favorite != null && !favorite.tracksLoaded) {
      // The operation itself is serialized; index loading must remain able to commit.
      final loaded = await ensureFavoriteIndex(force: true);
      if (!loaded) throw StateError('“我喜欢”索引尚未准备完成');
      favorite = await _store.favoritePlaylist();
    }
    if (favorite?.localId == null || favorite?.listId == null) {
      throw StateError('账号没有可用的“我喜欢”歌单');
    }
    if (!isCurrent()) return;
    final present = await _store.isTrackMember(favorite!.localId!, song.id);
    await _setMembership(
      favorite,
      song,
      present: desired ?? !present,
      isCurrent: isCurrent,
    );
  });

  Future<void> addSong(String playlistLocalId, Song song) =>
      _mutatePlaylist(playlistLocalId, song, true);

  Future<void> removeSong(String playlistLocalId, Song song) =>
      _mutatePlaylist(playlistLocalId, song, false);

  Future<void> _mutatePlaylist(String localId, Song song, bool present) async {
    final generation = _generation;
    final playlist = await _store.playlist(localId);
    if (_generation != generation) throw StateError('账号已切换');
    if (playlist == null) throw StateError('歌单不存在');
    return _mutate(
      playlist.isMyFavorite ? 'favorites' : localId,
      (isCurrent) => _setMembership(
        playlist,
        song,
        present: present,
        isCurrent: isCurrent,
      ),
    );
  }

  Future<void> _setMembership(
    Playlist playlist,
    Song song, {
    required bool present,
    required bool Function() isCurrent,
  }) async {
    final localId = playlist.localId!;
    final listId = playlist.listId;
    if (listId == null || !playlist.isWritable) throw StateError('歌单不可修改');
    final snapshot = await _write(
      isCurrent,
      () => _store.setTrackMembershipLocal(localId, song, present: present),
    );
    if (snapshot.wasPresent == present || !isCurrent()) return;
    try {
      if (present) {
        final result = await _remote.addSong(listId, song);
        await _write(
          isCurrent,
          () => _store.markTrackFileId(
            localId,
            song.id,
            fileId: result.fileIds.firstOrNull,
          ),
        );
      } else {
        final fileId =
            snapshot.fileId ?? await _remote.findTrackFileId(listId, song);
        if (!isCurrent()) return;
        if (fileId == null) throw StateError('无法取得删除所需的 fileId');
        await _remote.removeSong(listId, fileId);
      }
      if (isCurrent()) _reporter?.reportFavoriteChanged(song, liked: present);
    } catch (_) {
      if (isCurrent()) {
        await _write(
          isCurrent,
          () => _store.restoreTrackMembership(
            localId,
            song,
            present: snapshot.wasPresent,
            fileId: snapshot.fileId,
            collectTimeSecs: snapshot.collectTimeSecs,
            position: snapshot.position,
            count: snapshot.previousCount,
            snapshotCount: snapshot.previousSnapshotCount,
          ),
        );
      }
      rethrow;
    }
  }

  /// Cloud-first create so the row always has a remote listId.
  Future<String> createPlaylist(String name, {required bool private}) =>
      _mutate('metadata', (isCurrent) async {
        final mutation = await _remote.createPlaylist(name, private: private);
        final localId = Playlist.localIdForRemote(mutation.listId);
        await _write(
          isCurrent,
          () => _store.upsertPlaylist(
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
          ),
        );
        return localId;
      });

  Future<String> collectPlaylist(PlaylistSearchHit hit) =>
      _mutate('metadata', (isCurrent) async {
        final gid = hit.globalCollectionId;
        if (gid == null || gid.isEmpty) {
          throw ArgumentError.value(gid, 'globalCollectionId', '收藏歌单缺少全局 ID');
        }
        final existing = (await _store.watchPlaylists().first)
            .where((item) => item.globalCollectionId == gid)
            .firstOrNull;
        if (existing?.localId != null) return existing!.localId!;

        if (!isCurrent()) throw StateError('账号已切换');
        final mutation = await _remote.collectPlaylist(hit);
        final localId = Playlist.localIdForRemote(mutation.listId);
        await _write(
          isCurrent,
          () => _store.upsertPlaylist(
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
          ),
        );
        return localId;
      });

  Future<void> editPlaylist(
    String localId, {
    required String name,
    required String intro,
    required String tags,
    required bool private,
  }) => _mutate(localId, (isCurrent) async {
    final playlist = await _store.playlist(localId);
    if (playlist == null) throw StateError('歌单不存在');
    if (playlist.listId == null) throw StateError('歌单尚未绑定云端 ID');
    if (playlist.isCollected) throw StateError('收藏歌单不可编辑');

    final previous = playlist;
    await _write(
      isCurrent,
      () => _store.updatePlaylistMeta(
        localId,
        name: name,
        intro: intro,
        tags: tags,
        private: private,
      ),
    );
    if (!isCurrent()) return;
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
      if (isCurrent()) {
        await _write(
          isCurrent,
          () => _store.updatePlaylistMeta(
            localId,
            name: previous.name,
            intro: previous.intro ?? '',
            tags: previous.tags ?? '',
            private: previous.isPrivate,
          ),
        );
      }
      rethrow;
    }
  });

  Future<void> deletePlaylist(String localId) =>
      _mutate(localId, (isCurrent) async {
        final playlist = await _store.playlist(localId);
        if (!isCurrent() || playlist == null || playlist.isSystem) return;
        final listId = playlist.listId;
        if (listId != null) {
          await _remote.deletePlaylist(
            listId: listId,
            collected: playlist.isCollected,
          );
        }
        await _write(isCurrent, () => _store.deletePlaylistLocal(localId));
      });

  Future<void> recordPlayed(Song song) async {
    final userId = _userId;
    final generation = _generation;
    if (userId == null) return;
    bool isCurrent() => _isCurrent(generation, userId);
    final entry = await _write(isCurrent, () => _store.recordPlayed(song));
    if (!isCurrent()) return;
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

  Future<T> _write<T>(bool Function() isCurrent, Future<T> Function() write) =>
      _store.database.transaction(() async {
        if (!isCurrent()) throw StateError('账号已切换');
        return write();
      });

  Future<T> _mutate<T>(
    String key,
    Future<T> Function(bool Function()) operation,
  ) {
    final userId = _userId;
    final generation = _generation;
    if (userId == null || !ready) return Future.error(StateError('音乐库尚未准备完成'));
    bool isCurrent() => _isCurrent(generation, userId);
    final previous = _mutations[key] ?? Future<void>.value();
    final result = previous.then((_) async {
      if (!isCurrent()) throw StateError('账号已切换');
      _activeMutations += 1;
      _membershipVersion += 1;
      _trackLoader.invalidatePages();
      try {
        return await operation(isCurrent);
      } finally {
        if (_generation == generation) {
          _activeMutations -= 1;
          _membershipVersion += 1;
          _resumePendingSync();
        }
      }
    });
    late final Future<void> tail;
    tail = result
        .then<void>((_) {}, onError: (Object _, StackTrace _) {})
        .whenComplete(() {
          if (identical(_mutations[key], tail)) _mutations.remove(key);
        });
    _mutations[key] = tail;
    return result;
  }

  void _resumePendingSync() {
    if (!_resyncRequested ||
        _activeMutations != 0 ||
        _running != null ||
        !ready) {
      return;
    }
    _resyncRequested = false;
    unawaited(syncNow().catchError((_) {}));
  }

  bool _isCurrent(int generation, int userId) =>
      !_disposed &&
      _generation == generation &&
      _userId == userId &&
      (_session == null || _session.userId == userId);

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

bool _sameDay(DateTime? left, DateTime right) =>
    left != null &&
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
