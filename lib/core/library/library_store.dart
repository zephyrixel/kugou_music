import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_models.dart';
import 'package:kgmusic/core/models/song.dart';

part 'library_store_actions.dart';
part 'library_store_snapshot.dart';

abstract final class LibraryOperation {
  static const playlistUpsert = 'playlistUpsert';
  static const playlistDelete = 'playlistDelete';
  static const playlistTrack = 'playlistTrack';
  static const history = 'history';
}

class LibraryStore {
  const LibraryStore(this.database);

  final AppDatabase database;

  Stream<List<LibraryPlaylist>> watchPlaylists() =>
      (database.select(database.storedPlaylists)
            ..where((row) => row.deleted.equals(false))
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
            database.storedPlaylists.isMyFavorite.equals(true) &
            database.storedPlaylists.deleted.equals(false),
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

  Stream<List<LibraryHistoryEntry>> watchHistory() =>
      (database.select(database.storedSongs)
            ..where((row) => row.lastPlayedAt.isNotNull())
            ..orderBy([(row) => OrderingTerm.desc(row.lastPlayedAt)])
            ..limit(100))
          .watch()
          .map(
            (rows) => rows
                .map(
                  (row) => LibraryHistoryEntry(
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

  Stream<int> watchPendingCount() => database
      .select(database.libraryOutbox)
      .watch()
      .map((rows) => rows.length);

  Stream<LibrarySyncState?> watchSyncState() => (database.select(
    database.librarySyncStates,
  )..where((row) => row.singletonId.equals(1))).watchSingleOrNull();

  Future<LibrarySyncState?> get syncState => (database.select(
    database.librarySyncStates,
  )..where((row) => row.singletonId.equals(1))).getSingleOrNull();

  Future<LibraryPlaylist?> playlist(String localId) async {
    final row = await (database.select(
      database.storedPlaylists,
    )..where((item) => item.localId.equals(localId))).getSingleOrNull();
    return row == null ? null : _playlistFromRow(row);
  }

  Future<LibraryPlaylist?> favoritePlaylist() async {
    final row =
        await (database.select(database.storedPlaylists)..where(
              (item) =>
                  item.isMyFavorite.equals(true) & item.deleted.equals(false),
            ))
            .getSingleOrNull();
    return row == null ? null : _playlistFromRow(row);
  }

  Future<List<int>> knownRemotePlaylistIds() async =>
      (await (database.select(database.storedPlaylists)..where(
                (row) =>
                    row.remoteListId.isNotNull() & row.deleted.equals(false),
              ))
              .get())
          .map((row) => row.remoteListId!)
          .toList(growable: false);

  Future<Song?> song(String id) async {
    final row = await (database.select(
      database.storedSongs,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    return row == null ? null : _songFromRow(row);
  }

  Future<StoredPlaylistTrack?> playlistTrack(
    String playlistLocalId,
    String songId,
  ) =>
      (database.select(database.storedPlaylistTracks)..where(
            (row) =>
                row.playlistLocalId.equals(playlistLocalId) &
                row.songId.equals(songId),
          ))
          .getSingleOrNull();

  Future<int> _nextFrontPosition(String playlistLocalId) async {
    final first =
        await (database.select(database.storedPlaylistTracks)
              ..where((row) => row.playlistLocalId.equals(playlistLocalId))
              ..orderBy([(row) => OrderingTerm.asc(row.position)])
              ..limit(1))
            .getSingleOrNull();
    // Remote snapshots use 0..n. Pending local inserts use decreasing negative
    // positions so newest-first stays O(1) without rewriting the whole list.
    return first == null ? 0 : first.position - 1;
  }

  Future<LibraryHistoryEntry?> historyEntry(String songId) async {
    final row =
        await (database.select(database.storedSongs)..where(
              (song) => song.id.equals(songId) & song.lastPlayedAt.isNotNull(),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return LibraryHistoryEntry(
      song: _songFromRow(row),
      playedAt: row.lastPlayedAt!,
      playCount: row.playCount,
    );
  }

  Future<List<PendingLibraryOperation>> readyOperations({
    int limit = 50,
  }) async {
    final now = DateTime.now();
    final rows =
        await (database.select(database.libraryOutbox)
              ..where(
                (row) =>
                    row.nextAttemptAt.isNull() |
                    row.nextAttemptAt.isSmallerOrEqualValue(now),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.createdAt)])
              ..limit(limit))
            .get();
    final operations = rows
        .map(
          (row) => PendingLibraryOperation(
            key: row.dedupeKey,
            operation: row.operation,
            payload: row.payload,
            revision: row.revision,
            attempts: row.attempts,
          ),
        )
        .toList(growable: false);
    operations.sort(
      (a, b) => _operationPriority(
        a.operation,
      ).compareTo(_operationPriority(b.operation)),
    );
    return operations;
  }

  Future<List<PendingLibraryOperation>> claimReadyOperations({
    int limit = 50,
  }) => database.transaction(() async {
    final operations = await readyOperations(limit: limit);
    for (final operation in operations) {
      await (database.update(database.libraryOutbox)..where(
            (row) =>
                row.dedupeKey.equals(operation.key) &
                row.revision.equals(operation.revision),
          ))
          .write(
            LibraryOutboxCompanion(attempts: Value(operation.attempts + 1)),
          );
    }
    return operations;
  });

  Future<int> pendingCount() async =>
      (await database.select(database.libraryOutbox).get()).length;

  Future<DateTime?> nextRetryAt() async {
    final row =
        await (database.select(database.libraryOutbox)
              ..where((item) => item.nextAttemptAt.isNotNull())
              ..orderBy([(item) => OrderingTerm.asc(item.nextAttemptAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.nextAttemptAt;
  }

  Future<void> retryNow() => (database.update(
    database.libraryOutbox,
  )).write(const LibraryOutboxCompanion(nextAttemptAt: Value(null)));

  Future<void> completeOperation(String key, int revision) =>
      (database.delete(database.libraryOutbox)..where(
            (row) => row.dedupeKey.equals(key) & row.revision.equals(revision),
          ))
          .go();

  Future<void> failOperation(
    PendingLibraryOperation operation,
    String error,
    DateTime retryAt,
  ) =>
      (database.update(database.libraryOutbox)..where(
            (row) =>
                row.dedupeKey.equals(operation.key) &
                row.revision.equals(operation.revision),
          ))
          .write(
            LibraryOutboxCompanion(
              attempts: Value(operation.attempts + 1),
              nextAttemptAt: Value(retryAt),
              lastError: Value(error),
            ),
          );

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

  Future<LibraryOutboxData?> _outbox(String key) => (database.select(
    database.libraryOutbox,
  )..where((row) => row.dedupeKey.equals(key))).getSingleOrNull();

  Future<int> _playlistCount() async =>
      (await database.select(database.storedPlaylists).get()).length;

  Future<void> _enqueue({
    required String key,
    required String operation,
    required Map<String, Object?> payload,
  }) async {
    final existing = await _outbox(key);
    final now = DateTime.now();
    await database
        .into(database.libraryOutbox)
        .insertOnConflictUpdate(
          LibraryOutboxCompanion.insert(
            dedupeKey: key,
            operation: operation,
            payload: jsonEncode(payload),
            revision: Value((existing?.revision ?? 0) + 1),
            attempts: const Value(0),
            nextAttemptAt: const Value(null),
            lastError: const Value(null),
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
  }

  Future<void> _deleteOutboxPrefix(String prefix) => (database.delete(
    database.libraryOutbox,
  )..where((row) => row.dedupeKey.like('$prefix%'))).go();
}

StoredPlaylistsCompanion _playlistCompanion(
  LibraryPlaylist playlist, {
  int? sortOrder,
}) => StoredPlaylistsCompanion.insert(
  localId: playlist.localId,
  remoteListId: Value(playlist.remoteListId),
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

LibraryPlaylist _playlistFromRow(StoredPlaylist row) => LibraryPlaylist(
  localId: row.localId,
  remoteListId: row.remoteListId,
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

Map<String, Object?> _decodePayload(String payload) =>
    (jsonDecode(payload) as Map).cast<String, Object?>();

int _operationPriority(String operation) => switch (operation) {
  LibraryOperation.playlistUpsert => 0,
  LibraryOperation.playlistTrack => 1,
  LibraryOperation.playlistDelete => 2,
  LibraryOperation.history => 3,
  _ => 4,
};
