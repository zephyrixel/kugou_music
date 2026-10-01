import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:kgmusic/core/database/library_tables.dart';

part 'app_database.g.dart';

class CachedResponses extends Table {
  TextColumn get cacheKey => text()();
  IntColumn get accountUserId => integer().nullable()();
  IntColumn get codecVersion => integer()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

/// Durable player state, deliberately outside the disposable response cache.
class StoredPlaybackQueues extends Table {
  IntColumn get userId => integer()();
  IntColumn get codecVersion => integer()();
  TextColumn get payload => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

@DriftDatabase(
  tables: [
    StoredSongs,
    StoredPlaylists,
    StoredPlaylistTracks,
    LibrarySyncStates,
    StoredRecommendationProfiles,
    RecommendationSyncStates,
    CachedResponses,
    StoredPlaybackQueues,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({DateTime Function()? now})
    : now = now ?? DateTime.now,
      super(driftDatabase(name: 'kgmusic'));
  AppDatabase.forTesting(super.executor, {DateTime Function()? now})
    : now = now ?? DateTime.now;

  final DateTime Function() now;

  @override
  int get schemaVersion => 9;

  DateTime? _lastResponsePruneAt;
  int _responseWritesSincePrune = 0;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 3) {
        await migrator.createTable(cachedResponses);
        if (from >= 2) {
          await migrator.deleteTable('cached_cloud_tracks');
          await migrator.deleteTable('cached_cloud_playlists');
        }
      }
      if (from < 4) {
        await migrator.deleteTable('library_tracks');
        await migrator.createTable(storedSongs);
        await migrator.createTable(storedPlaylists);
        await migrator.createTable(storedPlaylistTracks);
        await migrator.createTable(librarySyncStates);
        await customStatement(
          "DELETE FROM cached_responses WHERE cache_key LIKE '%/cloud/%' "
          "OR cache_key LIKE '%/playlist/owned/%'",
        );
      }
      if (from < 5) {
        // Drop outbox + rebuild library tables without soft-delete / remotePresent.
        await customStatement('DROP TABLE IF EXISTS library_outbox');
        await customStatement('DROP TABLE IF EXISTS stored_playlist_tracks');
        await customStatement('DROP TABLE IF EXISTS stored_playlists');
        await customStatement('DROP TABLE IF EXISTS stored_songs');
        await customStatement('DROP TABLE IF EXISTS library_sync_states');
        await migrator.createTable(storedSongs);
        await migrator.createTable(storedPlaylists);
        await migrator.createTable(storedPlaylistTracks);
        await migrator.createTable(librarySyncStates);
      }
      if (from >= 5 && from < 6) {
        await migrator.addColumn(
          storedPlaylists,
          storedPlaylists.trackSnapshotCount,
        );
        await migrator.addColumn(
          storedPlaylists,
          storedPlaylists.tracksUpdatedAt,
        );
      }
      if (from < 7) {
        // Versions before 5 rebuild the library tables from the current
        // definitions above, so those columns already exist in the rebuilt
        // tables. Only an existing v5/v6 table needs ALTER TABLE here.
        if (from >= 5) {
          await migrator.addColumn(
            storedPlaylists,
            storedPlaylists.fullSnapshotUpdatedAt,
          );
          await migrator.addColumn(
            storedPlaylistTracks,
            storedPlaylistTracks.collectTimeSecs,
          );
        }
        await migrator.createTable(storedRecommendationProfiles);
        await migrator.createTable(recommendationSyncStates);
      }
      if (from < 8) {
        // Playlist ordering columns. Pre-5 upgrades rebuild the table from the
        // current definition, so only an existing v5+ table needs ALTER TABLE.
        if (from >= 5) {
          await migrator.addColumn(storedPlaylists, storedPlaylists.createdAt);
          await migrator.addColumn(storedPlaylists, storedPlaylists.updatedAt);
          await migrator.addColumn(storedPlaylists, storedPlaylists.remoteSort);
        }
        await _createIndexes();
      }
      if (from < 9) {
        await migrator.createTable(storedPlaybackQueues);
        await customStatement('''
          INSERT OR REPLACE INTO stored_playback_queues
            (user_id, codec_version, payload, updated_at)
          SELECT account_user_id, codec_version, payload, updated_at
          FROM cached_responses
          WHERE cache_key = 'player/queue/v1/' || account_user_id
        ''');
        await deleteCachedResponsePrefix('player/queue/v1/');
      }
    },
    beforeOpen: (details) async {
      // createAll() does not emit the indexes declared below.
      if (details.wasCreated) await _createIndexes();
    },
  );

  /// Hot ORDER BY / join-predicate columns. Without these every Drift stream
  /// emission re-runs a full scan plus a filesort.
  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_stored_songs_last_played_at '
      'ON stored_songs (last_played_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_playlist_tracks_playlist_position '
      'ON stored_playlist_tracks (playlist_local_id, position)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_stored_playlists_order '
      'ON stored_playlists (is_my_favorite DESC, is_default_collect DESC, '
      'created_at DESC, sort_order ASC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cached_responses_last_accessed_at '
      'ON cached_responses (last_accessed_at DESC)',
    );
  }

  Future<CachedResponse?> readCachedResponse(String cacheKey) async {
    final row = await (select(
      cachedResponses,
    )..where((item) => item.cacheKey.equals(cacheKey))).getSingleOrNull();
    if (row == null) return null;
    final now = this.now();
    if (now.difference(row.lastAccessedAt) >= const Duration(hours: 1)) {
      await (update(cachedResponses)
            ..where((item) => item.cacheKey.equals(cacheKey)))
          .write(CachedResponsesCompanion(lastAccessedAt: Value(now)));
    }
    return row;
  }

  Future<void> writeCachedResponse({
    required String cacheKey,
    required int? accountUserId,
    required int codecVersion,
    required String payload,
    DateTime? updatedAt,
  }) async {
    final now = updatedAt ?? this.now();
    await into(cachedResponses).insertOnConflictUpdate(
      CachedResponsesCompanion.insert(
        cacheKey: cacheKey,
        accountUserId: Value(accountUserId),
        codecVersion: codecVersion,
        payload: payload,
        updatedAt: now,
        lastAccessedAt: now,
      ),
    );
    _responseWritesSincePrune += 1;
    final lastPrune = _lastResponsePruneAt;
    if (_responseWritesSincePrune >= 25 ||
        lastPrune == null ||
        now.difference(lastPrune) >= const Duration(hours: 1)) {
      await pruneResponseCache();
      _lastResponsePruneAt = now;
      _responseWritesSincePrune = 0;
    }
  }

  Future<void> deleteCachedResponse(String cacheKey) => (delete(
    cachedResponses,
  )..where((item) => item.cacheKey.equals(cacheKey))).go();

  Future<void> deleteCachedResponsePrefix(String prefix) => (delete(
    cachedResponses,
  )..where((item) => item.cacheKey.like('$prefix%'))).go();

  Future<void> clearAccountCache({int? userId}) {
    final query = delete(cachedResponses);
    query.where(
      (item) => userId == null
          ? item.accountUserId.isNotNull()
          : item.accountUserId.equals(userId),
    );
    return query.go();
  }

  Future<void> clearResponseCache() => delete(cachedResponses).go();

  Future<void> pruneResponseCache({
    int maxEntries = 500,
    Duration retention = const Duration(days: 30),
  }) async {
    final cutoff = now().subtract(retention);
    await (delete(
      cachedResponses,
    )..where((item) => item.lastAccessedAt.isSmallerThanValue(cutoff))).go();
    // Key-only projection: the rows carry full payload JSON, so selecting them
    // just to count would pull megabytes into memory every prune. SQLite needs
    // an explicit LIMIT before OFFSET applies, so ask for everything past the
    // keep-window with a bound large enough to never truncate.
    final staleKeys =
        await (selectOnly(cachedResponses)
              ..addColumns([cachedResponses.cacheKey])
              ..orderBy([OrderingTerm.desc(cachedResponses.lastAccessedAt)])
              ..limit(1 << 30, offset: maxEntries))
            .map((row) => row.read(cachedResponses.cacheKey)!)
            .get();
    if (staleKeys.isEmpty) return;
    await (delete(
      cachedResponses,
    )..where((item) => item.cacheKey.isIn(staleKeys))).go();
  }
}
