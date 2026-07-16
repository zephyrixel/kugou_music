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

@DriftDatabase(
  tables: [
    StoredSongs,
    StoredPlaylists,
    StoredPlaylistTracks,
    LibrarySyncStates,
    CachedResponses,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'kgmusic'));
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

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
    },
  );

  Future<CachedResponse?> readCachedResponse(String cacheKey) async {
    final row = await (select(
      cachedResponses,
    )..where((item) => item.cacheKey.equals(cacheKey))).getSingleOrNull();
    if (row == null) return null;
    final now = DateTime.now();
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
  }) async {
    final now = DateTime.now();
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
    final cutoff = DateTime.now().subtract(retention);
    await (delete(
      cachedResponses,
    )..where((item) => item.lastAccessedAt.isSmallerThanValue(cutoff))).go();
    final rows = await (select(
      cachedResponses,
    )..orderBy([(item) => OrderingTerm.desc(item.lastAccessedAt)])).get();
    if (rows.length <= maxEntries) return;
    final staleKeys = rows
        .skip(maxEntries)
        .map((item) => item.cacheKey)
        .toList();
    await (delete(
      cachedResponses,
    )..where((item) => item.cacheKey.isIn(staleKeys))).go();
  }
}
