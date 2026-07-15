part of 'library_store.dart';

extension LibraryStoreActions on LibraryStore {
  Future<bool> setTrackMembership(
    String playlistLocalId,
    Song song, {
    required bool present,
  }) => database.transaction(() async {
    final playlistRow = await (database.select(
      database.storedPlaylists,
    )..where((row) => row.localId.equals(playlistLocalId))).getSingleOrNull();
    if (playlistRow == null || playlistRow.deleted) return false;
    final existing = await playlistTrack(playlistLocalId, song.id);
    if ((existing != null) == present) return false;

    final key = 'track:$playlistLocalId:${song.id}';
    if (present) {
      await _upsertSong(song);
      final position = await _nextFrontPosition(playlistLocalId);
      final pending = await _outbox(key);
      final pendingPayload = pending == null
          ? const <String, Object?>{}
          : _decodePayload(pending.payload);
      final remotePresent = pendingPayload['desired'] == false;
      await database
          .into(database.storedPlaylistTracks)
          .insert(
            StoredPlaylistTracksCompanion.insert(
              playlistLocalId: playlistLocalId,
              songId: song.id,
              fileId: Value(
                remotePresent ? pendingPayload['fileId'] as int? : null,
              ),
              position: Value(position),
              remotePresent: Value(remotePresent),
            ),
          );
      await _enqueue(
        key: key,
        operation: LibraryOperation.playlistTrack,
        payload: {
          'playlistLocalId': playlistLocalId,
          'songId': song.id,
          'desired': true,
          'verify': pending != null,
        },
      );
    } else {
      await (database.delete(database.storedPlaylistTracks)..where(
            (row) =>
                row.playlistLocalId.equals(playlistLocalId) &
                row.songId.equals(song.id),
          ))
          .go();
      final pending = await _outbox(key);
      await _enqueue(
        key: key,
        operation: LibraryOperation.playlistTrack,
        payload: {
          'playlistLocalId': playlistLocalId,
          'songId': song.id,
          'desired': false,
          'fileId': existing!.fileId,
          'verify': pending != null || existing.fileId == null,
        },
      );
    }
    await (database.update(
      database.storedPlaylists,
    )..where((row) => row.localId.equals(playlistLocalId))).write(
      StoredPlaylistsCompanion(
        count: Value(
          present
              ? playlistRow.count + 1
              : (playlistRow.count - 1).clamp(0, 1 << 31),
        ),
      ),
    );
    return true;
  });

  Future<bool> toggleFavorite(Song song) async {
    final favorite =
        await (database.select(database.storedPlaylists)..where(
              (row) =>
                  row.isMyFavorite.equals(true) & row.deleted.equals(false),
            ))
            .getSingleOrNull();
    if (favorite == null) throw StateError('账号没有可用的“我喜欢”歌单');
    final existing = await playlistTrack(favorite.localId, song.id);
    return setTrackMembership(
      favorite.localId,
      song,
      present: existing == null,
    );
  }

  Future<String> createPlaylist(String name, {required bool private}) =>
      database.transaction(() async {
        final now = DateTime.now().microsecondsSinceEpoch;
        final localId = 'local:$now';
        final playlistCount = await _playlistCount();
        await database
            .into(database.storedPlaylists)
            .insert(
              StoredPlaylistsCompanion.insert(
                localId: localId,
                name: name,
                isPrivate: Value(private),
                tracksLoaded: const Value(true),
                sortOrder: Value(playlistCount),
              ),
            );
        await _enqueue(
          key: 'playlist:$localId',
          operation: LibraryOperation.playlistUpsert,
          payload: {'localId': localId},
        );
        return localId;
      });

  Future<String> collectPlaylist(LibraryPlaylist playlist) =>
      database.transaction(() async {
        final existing =
            await (database.select(database.storedPlaylists)..where(
                  (row) => row.globalCollectionId.equals(
                    playlist.globalCollectionId!,
                  ),
                ))
                .getSingleOrNull();
        if (existing != null && !existing.deleted) return existing.localId;
        final localId = 'collected:${playlist.globalCollectionId}';
        final playlistCount = await _playlistCount();
        await database
            .into(database.storedPlaylists)
            .insertOnConflictUpdate(
              _playlistCompanion(
                LibraryPlaylist(
                  localId: localId,
                  globalCollectionId: playlist.globalCollectionId,
                  name: playlist.name,
                  intro: playlist.intro,
                  artworkUrl: playlist.artworkUrl,
                  count: playlist.count,
                  listType: 1,
                  creatorUserId: playlist.creatorUserId,
                  creatorName: playlist.creatorName,
                  isPrivate: false,
                  isMyFavorite: false,
                  isDefaultCollect: false,
                  tracksLoaded: false,
                  tags: playlist.tags,
                ),
                sortOrder: playlistCount,
              ),
            );
        await _enqueue(
          key: 'playlist:$localId',
          operation: LibraryOperation.playlistUpsert,
          payload: {'localId': localId},
        );
        return localId;
      });

  Future<void> editPlaylist(
    String localId, {
    required String name,
    required String intro,
    required String tags,
    required bool private,
  }) => database.transaction(() async {
    await (database.update(
      database.storedPlaylists,
    )..where((row) => row.localId.equals(localId))).write(
      StoredPlaylistsCompanion(
        name: Value(name),
        intro: Value(intro),
        tags: Value(tags),
        isPrivate: Value(private),
      ),
    );
    await _enqueue(
      key: 'playlist:$localId',
      operation: LibraryOperation.playlistUpsert,
      payload: {'localId': localId},
    );
  });

  Future<void> deletePlaylist(String localId) => database.transaction(() async {
    final row = await (database.select(
      database.storedPlaylists,
    )..where((item) => item.localId.equals(localId))).getSingleOrNull();
    if (row == null ||
        row.deleted ||
        row.isMyFavorite ||
        row.isDefaultCollect) {
      return;
    }
    final pendingPlaylist = await _outbox('playlist:$localId');
    await _deleteOutboxPrefix('track:$localId:');
    await (database.update(database.storedPlaylists)
          ..where((item) => item.localId.equals(localId)))
        .write(const StoredPlaylistsCompanion(deleted: Value(true)));
    await _enqueue(
      key: 'playlist:$localId',
      operation: LibraryOperation.playlistDelete,
      payload: {
        'localId': localId,
        'verify':
            row.remoteListId == null && (pendingPlaylist?.attempts ?? 0) > 0,
      },
    );
  });

  Future<void> recordPlayed(Song song, {DateTime? playedAt}) =>
      database.transaction(() async {
        final existing = await (database.select(
          database.storedSongs,
        )..where((row) => row.id.equals(song.id))).getSingleOrNull();
        final count = (existing?.playCount ?? 0) + 1;
        await _upsertSong(
          song,
          lastPlayedAt: playedAt ?? DateTime.now(),
          playCount: count,
        );
        if (song.mixSongId == null) return;
        await _enqueue(
          key: 'history:${song.id}',
          operation: LibraryOperation.history,
          payload: {'songId': song.id},
        );
      });
}
