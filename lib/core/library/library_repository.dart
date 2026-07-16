import 'dart:async';

import 'package:kgmusic/core/library/library_models.dart';
import 'package:kgmusic/core/library/library_remote.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/library/playlist_track_loader.dart';
import 'package:kgmusic/core/models/history_entry.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/recommendation/recommendation_reporter.dart';

/// Feature-facing library API: Drift read model + online write-back.
class LibraryRepository {
  LibraryRepository(
    LibraryStore store,
    LibraryRemote remote, [
    RecommendationReporter? reporter,
  ]) : _store = store,
       _remote = remote,
       _reporter = reporter,
       _trackLoader = PlaylistTrackLoader(store, remote);

  final LibraryStore _store;
  final LibraryRemote _remote;
  final RecommendationReporter? _reporter;
  final PlaylistTrackLoader _trackLoader;

  final StreamController<LibrarySyncStatus> _statuses =
      StreamController.broadcast(sync: true);
  LibrarySyncStatus _status = const LibrarySyncStatus.idle();
  int _generation = 0;
  int? _userId;
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
    final playlist = await _store.playlist(localId);
    if (playlist == null) throw StateError('歌单不存在');
    final local = await _store.playlistTracksPage(
      localId,
      page: page,
      pageSize: pageSize,
    );
    final start = (page - 1) * pageSize;
    final localIsComplete =
        local.length == pageSize ||
        playlist.tracksLoaded ||
        (playlist.count > 0 && start + local.length >= playlist.count);
    if (localIsComplete) {
      return SearchPage(
        songs: local,
        page: page,
        pageSize: pageSize,
        total: playlist.count,
      );
    }

    final remote = await _remote.fetchTracksPage(
      playlist,
      page: page,
      pageSize: pageSize,
    );
    await _store.appendPlaylistTracks(
      localId,
      remote.songs,
      startPosition: start,
      totalCount: remote.total,
    );
    if (!canLoadNextPage(
      loadedItemCount: start + remote.songs.length,
      lastPageItemCount: remote.songs.length,
      pageSize: remote.pageSize,
      total: remote.total,
    )) {
      await _store.markPlaylistTracksLoaded(
        localId,
        count: start + remote.songs.length,
      );
    }
    return remote;
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
    await _sync(generation, userId, wipe: needBaseline);
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
                lastSyncedAt: DateTime.now(),
              ),
            );
          } catch (error) {
            if (!_isCurrent(generation, userId)) return;
            await _store.setSyncResult(userId: userId, error: error.toString());
            if (!_isCurrent(generation, userId)) return;
            _emit(
              LibrarySyncStatus(
                phase: LibrarySyncPhase.failed,
                message: error.toString(),
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

  /// Load playlist tracks page-by-page into Drift (UI updates via watch after each page).
  ///
  /// Coalesces concurrent callers for the same [localId]. When [force], clears
  /// and restarts even if already loaded.
  Future<void> ensurePlaylistLoaded(
    String localId, {
    bool force = false,
  }) async {
    final generation = _generation;
    final userId = _userId;
    if (userId == null) return;
    await _trackLoader.ensure(
      localId,
      force: force,
      isCurrent: () => _isCurrent(generation, userId),
    );
  }

  Future<void> ensureFavoriteLoaded({bool force = false}) async {
    final favorite = await _store.favoritePlaylist();
    if (favorite?.localId == null) return;
    await ensurePlaylistLoaded(favorite!.localId!, force: force);
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
