import 'package:drift/drift.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/history_entry.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';

/// Drift-backed read model for the local music library (no outbox).
class LibraryStore {
  const LibraryStore(this.database);

  final AppDatabase database;

  Stream<List<Playlist>> watchPlaylists() =>
      (database.select(database.storedPlaylists)
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .watch()
          .map((rows) => rows.map(_playlistFromRow).toList(growable: false));

  Stream<List<Song>> watchFavoriteSongs() {
    final query = database.select(database.storedPlaylistTracks).join([
      innerJoin(
        database.storedPlaylists,
        database.storedPlaylists.localId.equalsExp(
              database.storedPlaylistTracks.playlistLocalId,
            ) &
            database.storedPlaylists.isMyFavorite.equals(true),
      ),
      innerJoin(
        database.storedSongs,
        database.storedSongs.id.equalsExp(database.storedPlaylistTracks.songId),
      ),
    ])..orderBy([OrderingTerm.asc(database.storedPlaylistTracks.position)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => _songFromRow(
              row.readTable(database.storedSongs),
              fileId: row.readTable(database.storedPlaylistTracks).fileId,
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<Set<String>> watchFavoriteSongIds() => watchFavoriteSongs().map(
    (songs) => songs.map((song) => song.id).toSet(),
  );

  Stream<List<HistoryEntry>> watchHistory() =>
      (database.select(database.storedSongs)
            ..where((row) => row.lastPlayedAt.isNotNull())
            ..orderBy([(row) => OrderingTerm.desc(row.lastPlayedAt)])
            ..limit(100))
          .watch()
          .map(
            (rows) => rows
                .map(
                  (row) => HistoryEntry(
                    song: _songFromRow(row),
                    playedAt: row.lastPlayedAt!,
                    playCount: row.playCount,
                  ),
                )
                .toList(growable: false),
          );

  Stream<List<Song>> watchPlaylistTracks(String localId) {
    final query =
        database.select(database.storedPlaylistTracks).join([
            innerJoin(
              database.storedSongs,
              database.storedSongs.id.equalsExp(
                database.storedPlaylistTracks.songId,
              ),
            ),
          ])
          ..where(database.storedPlaylistTracks.playlistLocalId.equals(localId))
          ..orderBy([OrderingTerm.asc(database.storedPlaylistTracks.position)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => _songFromRow(
              row.readTable(database.storedSongs),
              fileId: row.readTable(database.storedPlaylistTracks).fileId,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<LibrarySyncState?> get syncState => (database.select(
    database.librarySyncStates,
  )..where((row) => row.singletonId.equals(1))).getSingleOrNull();

  Future<Playlist?> playlist(String localId) async {
    final row = await (database.select(
      database.storedPlaylists,
    )..where((item) => item.localId.equals(localId))).getSingleOrNull();
    return row == null ? null : _playlistFromRow(row);
  }

  Future<Playlist?> favoritePlaylist() async {
    final row =
        await (database.select(database.storedPlaylists)
              ..where((item) => item.isMyFavorite.equals(true)))
            .getSingleOrNull();
    return row == null ? null : _playlistFromRow(row);
  }

  Future<bool> isTrackMember(String playlistLocalId, String songId) async {
    final row =
        await (database.select(database.storedPlaylistTracks)..where(
              (item) =>
                  item.playlistLocalId.equals(playlistLocalId) &
                  item.songId.equals(songId),
            ))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> clearLibrary() => database.transaction(() async {
    await database.delete(database.storedPlaylistTracks).go();
    await database.delete(database.storedPlaylists).go();
    await database.delete(database.storedSongs).go();
    await database.delete(database.librarySyncStates).go();
  });

  /// Full replace of library metadata + history (baseline or refresh).
  Future<void> replaceLibrary({
    required int userId,
    required List<Playlist> playlists,
    required List<HistoryEntry> history,
  }) => database.transaction(() async {
    final previous = await database.select(database.storedPlaylists).get();
    final tracksLoadedByLocalId = {
      for (final row in previous)
        if (row.tracksLoaded) row.localId: true,
    };
    final previousTracks = <String, List<StoredPlaylistTrack>>{};
    for (final row in previous) {
      if (tracksLoadedByLocalId[row.localId] != true) continue;
      previousTracks[row.localId] = await (database.select(
        database.storedPlaylistTracks,
      )..where((t) => t.playlistLocalId.equals(row.localId))).get();
    }

    await database.delete(database.storedPlaylistTracks).go();
    await database.delete(database.storedPlaylists).go();

    for (var index = 0; index < playlists.length; index++) {
      final playlist = playlists[index];
      final localId = playlist.localId!;
      final keepTracks = tracksLoadedByLocalId[localId] == true;
      await database
          .into(database.storedPlaylists)
          .insert(
            _playlistCompanion(
              playlist.copyWith(tracksLoaded: keepTracks),
              sortOrder: index,
            ),
          );
      final tracks = previousTracks[localId];
      if (keepTracks && tracks != null) {
        for (final track in tracks) {
          await database
              .into(database.storedPlaylistTracks)
              .insert(
                StoredPlaylistTracksCompanion.insert(
                  playlistLocalId: localId,
                  songId: track.songId,
                  fileId: Value(track.fileId),
                  position: Value(track.position),
                ),
              );
        }
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
        .insertOnConflictUpdate(
          LibrarySyncStatesCompanion.insert(
            userId: userId,
            baselineComplete: const Value(true),
            lastSyncedAt: Value(DateTime.now()),
            lastError: const Value(null),
          ),
        );
  });

  Future<void> setSyncResult({required int userId, String? error}) =>
      (database.update(database.librarySyncStates)..where(
            (row) => row.singletonId.equals(1) & row.userId.equals(userId),
          ))
          .write(
            LibrarySyncStatesCompanion(
              lastSyncedAt: error == null
                  ? Value(DateTime.now())
                  : const Value.absent(),
              lastError: Value(error),
            ),
          );

  /// Clear tracks and mark unloaded — first step of progressive page load.
  /// Keeps [StoredPlaylists.count] so the header does not flash to 0.
  Future<void> clearPlaylistTracks(String localId) =>
      database.transaction(() async {
        await (database.delete(
          database.storedPlaylistTracks,
        )..where((row) => row.playlistLocalId.equals(localId))).go();
        await (database.update(
          database.storedPlaylists,
        )..where((row) => row.localId.equals(localId))).write(
          const StoredPlaylistsCompanion(tracksLoaded: Value(false)),
        );
      });

  /// Append one page of tracks at contiguous positions starting at [startPosition].
  Future<void> appendPlaylistTracks(
    String localId,
    List<Song> songs, {
    required int startPosition,
    int? totalCount,
  }) => database.transaction(() async {
    for (var index = 0; index < songs.length; index++) {
      final song = songs[index];
      await _upsertSong(song);
      await database
          .into(database.storedPlaylistTracks)
          .insertOnConflictUpdate(
            StoredPlaylistTracksCompanion.insert(
              playlistLocalId: localId,
              songId: song.id,
              fileId: Value(song.fileId),
              position: Value(startPosition + index),
            ),
          );
    }
    final count = totalCount ?? (startPosition + songs.length);
    await (database.update(
      database.storedPlaylists,
    )..where((row) => row.localId.equals(localId))).write(
      StoredPlaylistsCompanion(count: Value(count)),
    );
  });

  Future<void> markPlaylistTracksLoaded(
    String localId, {
    required int count,
  }) =>
      (database.update(
        database.storedPlaylists,
      )..where((row) => row.localId.equals(localId))).write(
        StoredPlaylistsCompanion(
          tracksLoaded: const Value(true),
          count: Value(count),
        ),
      );

  /// Full replace (tests / one-shot callers). Prefer progressive append for UI.
  Future<void> replacePlaylistTracks(String localId, List<Song> songs) async {
    await clearPlaylistTracks(localId);
    await appendPlaylistTracks(localId, songs, startPosition: 0);
    await markPlaylistTracksLoaded(localId, count: songs.length);
  }

  Future<void> upsertPlaylist(Playlist playlist, {int? sortOrder}) async {
    final count = sortOrder ?? await _playlistCount();
    await database
        .into(database.storedPlaylists)
        .insertOnConflictUpdate(
          _playlistCompanion(playlist, sortOrder: count),
        );
  }

  Future<void> updatePlaylistMeta(
    String localId, {
    required String name,
    required String intro,
    required String tags,
    required bool private,
  }) =>
      (database.update(
        database.storedPlaylists,
      )..where((row) => row.localId.equals(localId))).write(
        StoredPlaylistsCompanion(
          name: Value(name),
          intro: Value(intro),
          tags: Value(tags),
          isPrivate: Value(private),
        ),
      );

  Future<void> deletePlaylistLocal(String localId) =>
      database.transaction(() async {
        await (database.delete(
          database.storedPlaylistTracks,
        )..where((row) => row.playlistLocalId.equals(localId))).go();
        await (database.delete(
          database.storedPlaylists,
        )..where((row) => row.localId.equals(localId))).go();
      });

  /// Optimistic membership change. Returns previous membership for rollback.
  Future<({bool wasPresent, int? fileId, int previousCount})>
  setTrackMembershipLocal(
    String playlistLocalId,
    Song song, {
    required bool present,
  }) => database.transaction(() async {
    final playlistRow = await (database.select(
      database.storedPlaylists,
    )..where((row) => row.localId.equals(playlistLocalId))).getSingleOrNull();
    if (playlistRow == null) {
      throw StateError('歌单不存在：$playlistLocalId');
    }
    final existing =
        await (database.select(database.storedPlaylistTracks)..where(
              (row) =>
                  row.playlistLocalId.equals(playlistLocalId) &
                  row.songId.equals(song.id),
            ))
            .getSingleOrNull();
    final wasPresent = existing != null;
    if (wasPresent == present) {
      return (
        wasPresent: wasPresent,
        fileId: existing?.fileId,
        previousCount: playlistRow.count,
      );
    }

    if (present) {
      await _upsertSong(song);
      final position = await _nextFrontPosition(playlistLocalId);
      await database
          .into(database.storedPlaylistTracks)
          .insert(
            StoredPlaylistTracksCompanion.insert(
              playlistLocalId: playlistLocalId,
              songId: song.id,
              fileId: Value(song.fileId),
              position: Value(position),
            ),
          );
    } else {
      await (database.delete(database.storedPlaylistTracks)..where(
            (row) =>
                row.playlistLocalId.equals(playlistLocalId) &
                row.songId.equals(song.id),
          ))
          .go();
    }

    final nextCount = present
        ? playlistRow.count + 1
        : (playlistRow.count - 1).clamp(0, 1 << 31);
    await (database.update(
      database.storedPlaylists,
    )..where((row) => row.localId.equals(playlistLocalId))).write(
      StoredPlaylistsCompanion(count: Value(nextCount)),
    );
    return (
      wasPresent: wasPresent,
      fileId: existing?.fileId,
      previousCount: playlistRow.count,
    );
  });

  Future<void> restoreTrackMembership(
    String playlistLocalId,
    Song song, {
    required bool present,
    int? fileId,
    required int count,
  }) => database.transaction(() async {
    await (database.delete(database.storedPlaylistTracks)..where(
          (row) =>
              row.playlistLocalId.equals(playlistLocalId) &
              row.songId.equals(song.id),
        ))
        .go();
    if (present) {
      await _upsertSong(song);
      final position = await _nextFrontPosition(playlistLocalId);
      await database
          .into(database.storedPlaylistTracks)
          .insert(
            StoredPlaylistTracksCompanion.insert(
              playlistLocalId: playlistLocalId,
              songId: song.id,
              fileId: Value(fileId ?? song.fileId),
              position: Value(position),
            ),
          );
    }
    await (database.update(
      database.storedPlaylists,
    )..where((row) => row.localId.equals(playlistLocalId))).write(
      StoredPlaylistsCompanion(count: Value(count)),
    );
  });

  Future<void> markTrackFileId(
    String playlistLocalId,
    String songId, {
    int? fileId,
  }) =>
      (database.update(database.storedPlaylistTracks)..where(
            (row) =>
                row.playlistLocalId.equals(playlistLocalId) &
                row.songId.equals(songId),
          ))
          .write(StoredPlaylistTracksCompanion(fileId: Value(fileId)));

  Future<HistoryEntry> recordPlayed(Song song, {DateTime? playedAt}) =>
      database.transaction(() async {
        final existing = await (database.select(
          database.storedSongs,
        )..where((row) => row.id.equals(song.id))).getSingleOrNull();
        final count = (existing?.playCount ?? 0) + 1;
        final at = playedAt ?? DateTime.now();
        await _upsertSong(song, lastPlayedAt: at, playCount: count);
        return HistoryEntry(song: song, playedAt: at, playCount: count);
      });

  Future<int> _nextFrontPosition(String playlistLocalId) async {
    final first =
        await (database.select(database.storedPlaylistTracks)
              ..where((row) => row.playlistLocalId.equals(playlistLocalId))
              ..orderBy([(row) => OrderingTerm.asc(row.position)])
              ..limit(1))
            .getSingleOrNull();
    // Remote snapshots use 0..n. Local inserts use decreasing negatives so
    // newest-first stays O(1) without rewriting the whole list.
    return first == null ? 0 : first.position - 1;
  }

  Future<int> _playlistCount() async =>
      (await database.select(database.storedPlaylists).get()).length;

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

StoredPlaylistsCompanion _playlistCompanion(
  Playlist playlist, {
  int? sortOrder,
}) => StoredPlaylistsCompanion.insert(
  localId: playlist.localId!,
  remoteListId: Value(playlist.listId),
  globalCollectionId: Value(playlist.globalCollectionId),
  name: playlist.name,
  intro: Value(playlist.intro),
  artworkUrl: Value(playlist.artworkUrl),
  count: Value(playlist.count),
  listType: Value(playlist.listType),
  creatorUserId: Value(playlist.creatorUserId),
  creatorName: Value(playlist.creatorName),
  isPrivate: Value(playlist.isPrivate),
  isMyFavorite: Value(playlist.isMyFavorite),
  isDefaultCollect: Value(playlist.isDefaultCollect),
  tracksLoaded: Value(playlist.tracksLoaded),
  tags: Value(playlist.tags),
  sortOrder: Value(sortOrder ?? 0),
);

Playlist _playlistFromRow(StoredPlaylist row) => Playlist(
  localId: row.localId,
  listId: row.remoteListId,
  globalCollectionId: row.globalCollectionId,
  name: row.name,
  intro: row.intro,
  artworkUrl: row.artworkUrl,
  count: row.count,
  listType: row.listType,
  creatorUserId: row.creatorUserId,
  creatorName: row.creatorName,
  isPrivate: row.isPrivate,
  isMyFavorite: row.isMyFavorite,
  isDefaultCollect: row.isDefaultCollect,
  tracksLoaded: row.tracksLoaded,
  tags: row.tags,
);

Song _songFromRow(StoredSong row, {int? fileId}) => Song(
  id: row.id,
  title: row.title,
  artist: row.artist,
  album: row.album,
  durationSecs: row.durationSecs,
  artworkUrl: row.artworkUrl,
  privilege: row.privilege,
  albumId: row.albumId,
  mixSongId: row.mixSongId,
  fileId: fileId,
  hashes: AudioHashes(
    standard: row.hashStandard,
    high: row.hashHigh,
    flac: row.hashFlac,
    hiRes: row.hashHiRes,
    superHash: row.hashSuper,
  ),
);
