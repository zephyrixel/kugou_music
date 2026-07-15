part of 'library_sync_service.dart';

extension _LibrarySyncPush on LibrarySyncService {
  Future<void> _pushReadyOperations(_SyncContext context) async {
    if (!_isCurrent(context)) return;
    final operations = await _store.claimReadyOperations();
    if (!_isCurrent(context)) return;
    final history = operations
        .where((item) => item.operation == LibraryOperation.history)
        .toList(growable: false);
    for (final operation in operations) {
      if (!_isCurrent(context)) return;
      if (operation.operation == LibraryOperation.history) continue;
      try {
        await _pushOne(context, operation);
        if (!_isCurrent(context)) return;
        await _store.completeOperation(operation.key, operation.revision);
      } catch (error) {
        if (!_isCurrent(context)) return;
        await _fail(context, operation, error);
        rethrow;
      }
    }
    if (history.isNotEmpty) await _pushHistory(context, history);
  }

  Future<void> _pushOne(
    _SyncContext context,
    PendingLibraryOperation operation,
  ) async {
    final payload = _payload(operation.payload);
    switch (operation.operation) {
      case LibraryOperation.playlistUpsert:
        await _pushPlaylist(context, operation, payload['localId']! as String);
      case LibraryOperation.playlistDelete:
        await _pushPlaylistDelete(
          context,
          operation,
          payload['localId']! as String,
          verify: payload['verify'] == true,
        );
      case LibraryOperation.playlistTrack:
        await _pushTrack(context, operation, payload);
      default:
        throw StateError('未知音乐库同步操作：${operation.operation}');
    }
  }

  Future<void> _pushPlaylist(
    _SyncContext context,
    PendingLibraryOperation operation,
    String localId,
  ) async {
    final playlist = await _store.playlist(localId);
    if (!_isCurrent(context) || playlist == null) return;
    if (playlist.remoteListId == null) {
      if (operation.attempts > 0) {
        final recovered = await _findCreatedPlaylist(context, playlist);
        if (!_isCurrent(context)) return;
        if (recovered?.remoteListId != null) {
          await _store.attachRemotePlaylist(
            localId,
            listId: recovered!.remoteListId!,
            globalCollectionId: recovered.globalCollectionId,
          );
          return;
        }
      }
      if (!_isCurrent(context)) return;
      final PlaylistMutation mutation;
      if (playlist.isCollected) {
        mutation = await _sdk.collectPlaylist(
          PlaylistSearchHit(
            globalCollectionId: playlist.globalCollectionId,
            name: playlist.name,
            creatorUserId: playlist.creatorUserId,
          ),
        );
      } else {
        mutation = await _sdk.createPlaylist(
          playlist.name,
          private: playlist.isPrivate,
        );
      }
      if (!_isCurrent(context)) return;
      await _store.attachRemotePlaylist(
        localId,
        listId: mutation.listId,
        globalCollectionId: mutation.globalCollectionId,
      );
      return;
    }
    if (!playlist.isCollected && _isCurrent(context)) {
      await _sdk.editPlaylist(
        PlaylistEditInput(
          listId: playlist.remoteListId!,
          name: playlist.name,
          intro: playlist.intro,
          tags: playlist.tags,
          private: playlist.isPrivate,
        ),
      );
    }
  }

  Future<void> _pushPlaylistDelete(
    _SyncContext context,
    PendingLibraryOperation operation,
    String localId, {
    required bool verify,
  }) async {
    final playlist = await _store.playlist(localId);
    if (!_isCurrent(context) || playlist == null) return;
    var remotePlaylist = playlist;
    if (remotePlaylist.remoteListId == null && verify) {
      remotePlaylist =
          await _findCreatedPlaylist(context, playlist) ?? playlist;
      if (!_isCurrent(context)) return;
    }
    if (remotePlaylist.remoteListId != null) {
      if (operation.attempts > 0) {
        final remote = await _fetchAllPlaylists(context);
        if (!_isCurrent(context)) return;
        final exists = remote.any(
          (item) => item.remoteListId == remotePlaylist.remoteListId,
        );
        if (!exists) {
          await _store.finalizePlaylistDelete(localId);
          return;
        }
      }
      if (!_isCurrent(context)) return;
      await _sdk.deletePlaylist(remotePlaylist.toRemote());
    }
    if (!_isCurrent(context)) return;
    await _store.finalizePlaylistDelete(localId);
  }

  Future<void> _pushTrack(
    _SyncContext context,
    PendingLibraryOperation operation,
    Map<String, Object?> payload,
  ) async {
    final localId = payload['playlistLocalId']! as String;
    final songId = payload['songId']! as String;
    final desired = payload['desired']! as bool;
    final playlist = await _store.playlist(localId);
    if (!_isCurrent(context)) return;
    if (playlist?.remoteListId == null) {
      throw StateError('歌单尚未取得云端 ID');
    }
    final song = await _store.song(songId);
    if (!_isCurrent(context) || song == null) return;
    final verify = payload['verify'] == true || operation.attempts > 0;
    Song? remoteSong;
    if (verify || (!desired && payload['fileId'] == null)) {
      final tracks = await _fetchAllPlaylistTracks(context, playlist!);
      if (!_isCurrent(context)) return;
      remoteSong = tracks.where((item) => item.id == songId).firstOrNull;
      if (desired && remoteSong != null) {
        await _store.markTrackRemote(
          localId,
          songId,
          fileId: remoteSong.fileId,
        );
        return;
      }
      if (!desired && remoteSong == null) return;
    }
    if (desired) {
      final result = await _sdk.addSongToPlaylist(
        playlist!.remoteListId!,
        song,
      );
      if (!_isCurrent(context)) return;
      await _store.markTrackRemote(
        localId,
        songId,
        fileId: result.fileIds.firstOrNull,
      );
      return;
    }

    var fileId = remoteSong?.fileId ?? payload['fileId'] as int?;
    if (fileId == null && remoteSong != null) {
      fileId = await _findTrackFileId(context, playlist!.remoteListId!, song);
      if (!_isCurrent(context)) return;
    }
    if (fileId == null) {
      throw StateError('云端歌曲存在，但无法取得删除所需的 fileId');
    }
    await _sdk.removeSongFromPlaylist(playlist!.remoteListId!, fileId);
  }

  Future<int?> _findTrackFileId(
    _SyncContext context,
    int listId,
    Song target,
  ) async {
    var page = 1;
    var loaded = 0;
    while (_isCurrent(context)) {
      final response = await _sdk.playlistTracksByListId(
        listId,
        page: page,
        pageSize: LibrarySyncService._pageSize,
      );
      if (!_isCurrent(context) || response.songs.isEmpty) return null;
      loaded += response.songs.length;
      final fileId = response.songs
          .where((song) => _sameSong(song, target) && song.fileId != null)
          .map((song) => song.fileId!)
          .firstOrNull;
      if (fileId != null) return fileId;
      if (!canLoadNextPage(
        loadedItemCount: loaded,
        lastPageItemCount: response.songs.length,
        pageSize: response.pageSize,
        total: response.total,
      )) {
        return null;
      }
      page += 1;
    }
    return null;
  }

  Future<void> _pushHistory(
    _SyncContext context,
    List<PendingLibraryOperation> operations,
  ) async {
    final uploads = <CloudHistoryUpload>[];
    final valid = <PendingLibraryOperation>[];
    for (final operation in operations) {
      if (!_isCurrent(context)) return;
      final songId = _payload(operation.payload)['songId']! as String;
      final entry = await _store.historyEntry(songId);
      if (!_isCurrent(context)) return;
      final mixSongId = entry?.song.mixSongId;
      if (entry == null || mixSongId == null) {
        await _store.completeOperation(operation.key, operation.revision);
        continue;
      }
      uploads.add(
        CloudHistoryUpload(
          mixSongId: mixSongId,
          playedAt: entry.playedAt,
          playCount: entry.playCount,
        ),
      );
      valid.add(operation);
    }
    if (uploads.isEmpty || !_isCurrent(context)) return;
    try {
      await _sdk.uploadHistory(uploads);
      if (!_isCurrent(context)) return;
      for (final operation in valid) {
        await _store.completeOperation(operation.key, operation.revision);
        if (!_isCurrent(context)) return;
      }
    } catch (error) {
      if (!_isCurrent(context)) return;
      for (final operation in valid) {
        await _fail(context, operation, error);
        if (!_isCurrent(context)) return;
      }
      rethrow;
    }
  }

  Future<LibraryPlaylist?> _findCreatedPlaylist(
    _SyncContext context,
    LibraryPlaylist local,
  ) async {
    final remote = await _fetchAllPlaylists(context);
    if (!_isCurrent(context)) return null;
    if (local.isCollected && local.globalCollectionId != null) {
      return remote
          .where(
            (item) =>
                item.globalCollectionId == local.globalCollectionId &&
                item.isCollected,
          )
          .firstOrNull;
    }
    final knownIds = await _store.knownRemotePlaylistIds();
    if (!_isCurrent(context)) return null;
    return remote
        .where(
          (item) =>
              !item.isCollected &&
              !item.isSystem &&
              item.name == local.name &&
              item.isPrivate == local.isPrivate &&
              item.remoteListId != null &&
              !knownIds.contains(item.remoteListId),
        )
        .firstOrNull;
  }

  Future<void> _fail(
    _SyncContext context,
    PendingLibraryOperation operation,
    Object error,
  ) async {
    if (!_isCurrent(context)) return;
    await _store.failOperation(
      operation,
      error.toString(),
      DateTime.now().add(
        LibrarySyncService._retryDelays[operation.attempts.clamp(
          0,
          LibrarySyncService._retryDelays.length - 1,
        )],
      ),
    );
  }
}

Map<String, Object?> _payload(String value) =>
    (jsonDecode(value) as Map).cast<String, Object?>();

bool _sameSong(Song left, Song right) {
  if (left.id == right.id) return true;
  if (left.mixSongId != null && left.mixSongId == right.mixSongId) return true;
  final hashes = _songHashes(left);
  return hashes.isNotEmpty &&
      hashes.intersection(_songHashes(right)).isNotEmpty;
}

Set<String> _songHashes(Song song) =>
    [
          song.hashes.standard,
          song.hashes.high,
          song.hashes.flac,
          song.hashes.hiRes,
          song.hashes.superHash,
        ]
        .whereType<String>()
        .map((hash) => hash.trim().toLowerCase())
        .where((hash) => hash.isNotEmpty)
        .toSet();
