part of 'library_store.dart';

extension LibraryStoreSnapshot on LibraryStore {
  Future<void> replaceBaseline({
    required int userId,
    required List<LibraryPlaylist> playlists,
    required Map<String, List<Song>> loadedTracks,
    required List<LibraryHistoryEntry> history,
  }) => database.transaction(() async {
    await _clearLibraryTables();
    for (var index = 0; index < playlists.length; index++) {
      final playlist = playlists[index];
      await database
          .into(database.storedPlaylists)
          .insert(_playlistCompanion(playlist, sortOrder: index));
      final tracks = loadedTracks[playlist.localId];
      if (tracks != null) {
        await _replaceTracks(playlist.localId, tracks, remote: true);
        await _updatePlaylistTrackCount(playlist.localId);
      }
    }
    for (final entry in history) {
      await _upsertSong(
        entry.song,
        lastPlayedAt: entry.playedAt,
        playCount: entry.playCount,
      );
    }
    await database
        .into(database.librarySyncStates)
        .insert(
          LibrarySyncStatesCompanion.insert(
            userId: userId,
            baselineComplete: const Value(true),
            lastSyncedAt: Value(DateTime.now()),
          ),
        );
  });

  Future<void> applyRemoteSnapshot({
    required int userId,
    required List<LibraryPlaylist> playlists,
    required Map<String, List<Song>> loadedTracks,
    required List<LibraryHistoryEntry> history,
  }) => database.transaction(() async {
    final state = await syncState;
    if (state?.userId != userId) return;

    final existing = await database.select(database.storedPlaylists).get();
    final pendingPlaylistIds = <String>{};
    for (final operation
        in await database.select(database.libraryOutbox).get()) {
      final payload = _decodePayload(operation.payload);
      if (operation.operation == LibraryOperation.playlistUpsert ||
          operation.operation == LibraryOperation.playlistDelete) {
        final localId = payload['localId'];
        if (localId is String) pendingPlaylistIds.add(localId);
      } else if (operation.operation == LibraryOperation.playlistTrack) {
        final localId = payload['playlistLocalId'];
        if (localId is String) pendingPlaylistIds.add(localId);
      }
    }
    final mappedPlaylists = playlists
        .map((playlist) {
          final matched = existing
              .where(
                (item) =>
                    playlist.remoteListId != null &&
                    item.remoteListId == playlist.remoteListId,
              )
              .firstOrNull;
          if (matched == null || matched.localId == playlist.localId) {
            return playlist;
          }
          final tracks = loadedTracks.remove(playlist.localId);
          if (tracks != null) loadedTracks[matched.localId] = tracks;
          return LibraryPlaylist(
            localId: matched.localId,
            remoteListId: playlist.remoteListId,
            globalCollectionId: playlist.globalCollectionId,
            name: playlist.name,
            intro: playlist.intro,
            artworkUrl: playlist.artworkUrl,
            count: playlist.count,
            listType: playlist.listType,
            creatorUserId: playlist.creatorUserId,
            creatorName: playlist.creatorName,
            isPrivate: playlist.isPrivate,
            isMyFavorite: playlist.isMyFavorite,
            isDefaultCollect: playlist.isDefaultCollect,
            tracksLoaded: matched.tracksLoaded,
            tags: playlist.tags,
          );
        })
        .toList(growable: false);
    final remoteLocalIds = mappedPlaylists.map((item) => item.localId).toSet();
    for (final row in existing) {
      if (!remoteLocalIds.contains(row.localId) &&
          !pendingPlaylistIds.contains(row.localId)) {
        await _deletePlaylistRows(row.localId);
      }
    }
    for (var index = 0; index < mappedPlaylists.length; index++) {
      final playlist = mappedPlaylists[index];
      final current = existing
          .where((item) => item.localId == playlist.localId)
          .firstOrNull;
      if (!pendingPlaylistIds.contains(playlist.localId)) {
        await database
            .into(database.storedPlaylists)
            .insertOnConflictUpdate(
              _playlistCompanion(
                LibraryPlaylist(
                  localId: playlist.localId,
                  remoteListId: playlist.remoteListId,
                  globalCollectionId: playlist.globalCollectionId,
                  name: playlist.name,
                  intro: playlist.intro,
                  artworkUrl: playlist.artworkUrl,
                  count: playlist.count,
                  listType: playlist.listType,
                  creatorUserId: playlist.creatorUserId,
                  creatorName: playlist.creatorName,
                  isPrivate: playlist.isPrivate,
                  isMyFavorite: playlist.isMyFavorite,
                  isDefaultCollect: playlist.isDefaultCollect,
                  tracksLoaded:
                      loadedTracks.containsKey(playlist.localId) ||
                      (current?.tracksLoaded ?? false),
                  tags: playlist.tags,
                ),
                sortOrder: index,
              ),
            );
      }
      final tracks = loadedTracks[playlist.localId];
      if (tracks != null) {
        await _replaceTracks(playlist.localId, tracks, remote: true);
        await _updatePlaylistTrackCount(playlist.localId);
      }
    }

    for (final entry in history) {
      final current = await historyEntry(entry.song.id);
      await _upsertSong(
        entry.song,
        lastPlayedAt:
            current != null && current.playedAt.isAfter(entry.playedAt)
            ? current.playedAt
            : entry.playedAt,
        playCount: current == null
            ? entry.playCount
            : current.playCount > entry.playCount
            ? current.playCount
            : entry.playCount,
      );
    }
    await setSyncResult(userId: userId);
  });

  Future<void> clearLibrary() => database.transaction(_clearLibraryTables);

  Future<void> _clearLibraryTables() async {
    await database.delete(database.storedPlaylistTracks).go();
    await database.delete(database.storedPlaylists).go();
    await database.delete(database.storedSongs).go();
    await database.delete(database.libraryOutbox).go();
    await database.delete(database.librarySyncStates).go();
  }

  Future<void> attachRemotePlaylist(
    String localId, {
    required int listId,
    String? globalCollectionId,
  }) =>
      (database.update(
        database.storedPlaylists,
      )..where((row) => row.localId.equals(localId))).write(
        StoredPlaylistsCompanion(
          remoteListId: Value(listId),
          globalCollectionId: globalCollectionId == null
              ? const Value.absent()
              : Value(globalCollectionId),
        ),
      );

  Future<void> markTrackRemote(
    String playlistLocalId,
    String songId, {
    int? fileId,
  }) =>
      (database.update(database.storedPlaylistTracks)..where(
            (row) =>
                row.playlistLocalId.equals(playlistLocalId) &
                row.songId.equals(songId),
          ))
          .write(
            StoredPlaylistTracksCompanion(
              fileId: Value(fileId),
              remotePresent: const Value(true),
            ),
          );

  Future<void> finalizePlaylistDelete(String localId) =>
      database.transaction(() => _deletePlaylistRows(localId));

  Future<void> _deletePlaylistRows(String localId) async {
    await (database.delete(
      database.storedPlaylistTracks,
    )..where((row) => row.playlistLocalId.equals(localId))).go();
    await (database.delete(
      database.storedPlaylists,
    )..where((row) => row.localId.equals(localId))).go();
  }

  Future<void> replacePlaylistTracks(String localId, List<Song> songs) =>
      database.transaction(() async {
        await _replaceTracks(localId, songs, remote: true);
        await _updatePlaylistTrackCount(localId);
      });

  Future<void> _updatePlaylistTrackCount(String localId) async {
    final count =
        await (database.select(database.storedPlaylistTracks)
              ..where((row) => row.playlistLocalId.equals(localId)))
            .get()
            .then((rows) => rows.length);
    await (database.update(
      database.storedPlaylists,
    )..where((row) => row.localId.equals(localId))).write(
      StoredPlaylistsCompanion(
        tracksLoaded: const Value(true),
        count: Value(count),
      ),
    );
  }

  Future<void> _replaceTracks(
    String localId,
    List<Song> songs, {
    required bool remote,
  }) async {
    final pendingRows = await (database.select(
      database.libraryOutbox,
    )..where((row) => row.dedupeKey.like('track:$localId:%'))).get();
    final pending = {
      for (final row in pendingRows)
        (_decodePayload(row.payload)['songId'] as String): _decodePayload(
          row.payload,
        ),
    };
    await (database.delete(database.storedPlaylistTracks)..where(
          (row) =>
              row.playlistLocalId.equals(localId) &
              row.remotePresent.equals(true),
        ))
        .go();
    for (var index = 0; index < songs.length; index++) {
      final song = songs[index];
      final intent = pending[song.id];
      if (intent?['desired'] == false) continue;
      await _upsertSong(song);
      await database
          .into(database.storedPlaylistTracks)
          .insertOnConflictUpdate(
            StoredPlaylistTracksCompanion.insert(
              playlistLocalId: localId,
              songId: song.id,
              fileId: Value(song.fileId),
              position: Value(index),
              remotePresent: Value(remote),
            ),
          );
    }
  }

  Future<void> _upsertSong(
    Song song, {
    DateTime? lastPlayedAt,
    int? playCount,
  }) async {
    final existing = await (database.select(
      database.storedSongs,
    )..where((row) => row.id.equals(song.id))).getSingleOrNull();
    await database
        .into(database.storedSongs)
        .insertOnConflictUpdate(
          StoredSongsCompanion.insert(
            id: song.id,
            title: song.title.isEmpty ? existing?.title ?? '未知歌曲' : song.title,
            artist: Value(song.artist ?? existing?.artist),
            album: Value(song.album ?? existing?.album),
            durationSecs: Value(song.durationSecs ?? existing?.durationSecs),
            artworkUrl: Value(song.artworkUrl ?? existing?.artworkUrl),
            privilege: Value(song.privilege ?? existing?.privilege),
            albumId: Value(song.albumId ?? existing?.albumId),
            mixSongId: Value(song.mixSongId ?? existing?.mixSongId),
            hashStandard: Value(song.hashes.standard ?? existing?.hashStandard),
            hashHigh: Value(song.hashes.high ?? existing?.hashHigh),
            hashFlac: Value(song.hashes.flac ?? existing?.hashFlac),
            hashHiRes: Value(song.hashes.hiRes ?? existing?.hashHiRes),
            hashSuper: Value(song.hashes.superHash ?? existing?.hashSuper),
            lastPlayedAt: Value(lastPlayedAt ?? existing?.lastPlayedAt),
            playCount: Value(playCount ?? existing?.playCount ?? 0),
          ),
        );
  }
}
