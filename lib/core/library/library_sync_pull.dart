part of 'library_sync_service.dart';

extension _LibrarySyncPull on LibrarySyncService {
  Future<void> _buildBaseline(_SyncContext context) async {
    _emitFor(
      context,
      const LibrarySyncStatus(
        phase: LibrarySyncPhase.syncing,
        message: '正在初始化音乐库',
      ),
    );
    try {
      await _pullRemote(context, baseline: true);
      if (!_isCurrent(context)) return;
      _emitFor(
        context,
        LibrarySyncStatus(
          phase: LibrarySyncPhase.idle,
          lastSyncedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      if (!_isCurrent(context)) return;
      _emitFor(
        context,
        LibrarySyncStatus(
          phase: LibrarySyncPhase.failed,
          message: error.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<void> _pullRemote(
    _SyncContext context, {
    required bool baseline,
  }) async {
    final playlists = await _fetchAllPlaylists(context);
    if (!_isCurrent(context)) return;
    final loadedRemoteIds = baseline
        ? const <int>{}
        : await _store.loadedRemotePlaylistIds();
    if (!_isCurrent(context)) return;

    final loadedTracks = <String, List<Song>>{};
    for (final playlist in playlists) {
      if (!_isCurrent(context)) return;
      if (playlist.isMyFavorite ||
          loadedRemoteIds.contains(playlist.remoteListId)) {
        loadedTracks[playlist.localId] = await _fetchAllPlaylistTracks(
          context,
          playlist,
        );
      }
    }
    final history = await _fetchHistory(context);
    if (!_isCurrent(context)) return;
    if (baseline) {
      await _store.replaceBaseline(
        userId: context.userId,
        playlists: playlists,
        loadedTracks: loadedTracks,
        history: history,
      );
    } else {
      await _store.applyRemoteSnapshot(
        userId: context.userId,
        playlists: playlists,
        loadedTracks: loadedTracks,
        history: history,
      );
    }
  }

  Future<List<LibraryPlaylist>> _fetchAllPlaylists(_SyncContext context) async {
    final result = <LibraryPlaylist>[];
    final known = <String>{};
    var page = 1;
    while (_isCurrent(context)) {
      final response = await _sdk.cloudPlaylists(
        page: page,
        pageSize: LibrarySyncService._pageSize,
      );
      if (!_isCurrent(context) || response.items.isEmpty) break;
      for (final item in response.items) {
        final playlist = _fromRemotePlaylist(item);
        if (known.add(playlist.localId)) result.add(playlist);
      }
      if (!canLoadNextPage(
        loadedItemCount: result.length,
        lastPageItemCount: response.items.length,
        pageSize: response.pageSize,
        total: response.total,
      )) {
        break;
      }
      page += 1;
    }
    return result;
  }

  Future<List<Song>> _fetchAllPlaylistTracks(
    _SyncContext context,
    LibraryPlaylist playlist,
  ) async {
    final result = <Song>[];
    final known = <String>{};
    var page = 1;
    while (_isCurrent(context)) {
      final response = await _sdk.playlistTracks(
        playlist.toRemote(),
        page: page,
        pageSize: LibrarySyncService._pageSize,
      );
      if (!_isCurrent(context) || response.songs.isEmpty) break;
      for (final song in response.songs) {
        if (known.add(song.id)) result.add(song);
      }
      if (!canLoadNextPage(
        loadedItemCount: result.length,
        lastPageItemCount: response.songs.length,
        pageSize: response.pageSize,
        total: response.total,
      )) {
        break;
      }
      page += 1;
    }
    return result;
  }

  Future<List<LibraryHistoryEntry>> _fetchHistory(_SyncContext context) async {
    // Upstream cloud history pages are oldest→newest (`ot` asc); `bp` continues
    // toward newer plays. We page until the limit, then sort newest-first for UI
    // (official「最近播放」). Do not append pages raw without this sort.
    final entries = <String, LibraryHistoryEntry>{};
    String? cursor;
    while (_isCurrent(context) &&
        entries.length < LibrarySyncService._historyLimit) {
      final response = await _sdk.cloudHistory(cursor: cursor);
      if (!_isCurrent(context)) break;
      for (final item in response.items) {
        final current = entries[item.song.id];
        if (current == null || item.playedAt.isAfter(current.playedAt)) {
          entries[item.song.id] = LibraryHistoryEntry(
            song: item.song,
            playedAt: item.playedAt,
            playCount: item.playCount,
          );
        }
      }
      final next = response.cursor;
      if (!response.hasMore || next == null || next.isEmpty || next == cursor) {
        break;
      }
      cursor = next;
    }
    final result = entries.values.toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return result
        .take(LibrarySyncService._historyLimit)
        .toList(growable: false);
  }

  Future<void> _ensurePlaylistLoaded(
    String localId, {
    bool force = false,
  }) async {
    final context = _context;
    if (context == null || !_isCurrent(context)) return;
    final playlist = await _store.playlist(localId);
    if (!_isCurrent(context) ||
        playlist == null ||
        playlist.remoteListId == null ||
        (playlist.tracksLoaded && !force)) {
      return;
    }
    final tracks = await _fetchAllPlaylistTracks(context, playlist);
    if (!_isCurrent(context)) return;
    await _store.replacePlaylistTracks(localId, tracks);
  }
}

LibraryPlaylist _fromRemotePlaylist(CloudPlaylist value) => LibraryPlaylist(
  localId: value.listId != null
      ? 'remote:${value.listId}'
      : 'gid:${value.globalCollectionId}',
  remoteListId: value.listId,
  globalCollectionId: value.globalCollectionId,
  name: value.name,
  intro: value.intro,
  artworkUrl: value.artworkUrl,
  count: value.count ?? 0,
  listType: value.listType,
  creatorUserId: value.creatorUserId,
  creatorName: value.creatorName,
  isPrivate: value.isPrivate,
  isMyFavorite: value.isMyFavorite,
  isDefaultCollect: value.isDefaultCollect,
  tracksLoaded: value.isMyFavorite,
  tags: value.tags,
);
