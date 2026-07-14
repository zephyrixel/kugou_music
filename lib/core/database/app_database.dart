import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:kgmusic/core/models/song.dart';

part 'app_database.g.dart';

class LibraryTracks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get durationSecs => integer().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  IntColumn get privilege => integer().nullable()();
  IntColumn get albumId => integer().nullable()();
  IntColumn get mixSongId => integer().nullable()();
  IntColumn get fileId => integer().nullable()();
  TextColumn get hashStandard => text().nullable()();
  TextColumn get hashHigh => text().nullable()();
  TextColumn get hashFlac => text().nullable()();
  TextColumn get hashHiRes => text().nullable()();
  TextColumn get hashSuper => text().nullable()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

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

@DriftDatabase(tables: [LibraryTracks, CachedResponses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'kgmusic'));
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 3) {
        await migrator.addColumn(libraryTracks, libraryTracks.fileId);
        await migrator.createTable(cachedResponses);
        if (from >= 2) {
          await migrator.deleteTable('cached_cloud_tracks');
          await migrator.deleteTable('cached_cloud_playlists');
        }
      }
    },
  );

  Stream<List<Song>> watchFavorites() =>
      (select(libraryTracks)
            ..where((row) => row.favorite.equals(true))
            ..orderBy([(row) => OrderingTerm.asc(row.title)]))
          .watch()
          .map((rows) => rows.map(_rowToSong).toList(growable: false));

  Stream<List<Song>> watchHistory() =>
      (select(libraryTracks)
            ..where((row) => row.lastPlayedAt.isNotNull())
            ..orderBy([(row) => OrderingTerm.desc(row.lastPlayedAt)])
            ..limit(100))
          .watch()
          .map((rows) => rows.map(_rowToSong).toList(growable: false));

  Future<void> toggleFavorite(Song song) async {
    final existing = await (select(
      libraryTracks,
    )..where((row) => row.id.equals(song.id))).getSingleOrNull();
    await into(libraryTracks).insertOnConflictUpdate(
      _companion(
        song,
        favorite: !(existing?.favorite ?? false),
        lastPlayedAt: existing?.lastPlayedAt,
        playCount: existing?.playCount ?? 0,
      ),
    );
  }

  Future<void> recordPlayed(Song song) async {
    final existing = await (select(
      libraryTracks,
    )..where((row) => row.id.equals(song.id))).getSingleOrNull();
    await into(libraryTracks).insertOnConflictUpdate(
      _companion(
        song,
        favorite: existing?.favorite ?? false,
        lastPlayedAt: DateTime.now(),
        playCount: (existing?.playCount ?? 0) + 1,
      ),
    );
  }

  Future<CachedResponse?> readCachedResponse(String cacheKey) async {
    final row = await (select(
      cachedResponses,
    )..where((item) => item.cacheKey.equals(cacheKey))).getSingleOrNull();
    if (row == null) return null;
    await (update(cachedResponses)
          ..where((item) => item.cacheKey.equals(cacheKey)))
        .write(CachedResponsesCompanion(lastAccessedAt: Value(DateTime.now())));
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
    await pruneResponseCache();
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

  LibraryTracksCompanion _companion(
    Song song, {
    required bool favorite,
    required DateTime? lastPlayedAt,
    required int playCount,
  }) => LibraryTracksCompanion.insert(
    id: song.id,
    title: song.title,
    artist: Value(song.artist),
    album: Value(song.album),
    durationSecs: Value(song.durationSecs),
    artworkUrl: Value(song.artworkUrl),
    privilege: Value(song.privilege),
    albumId: Value(song.albumId),
    mixSongId: Value(song.mixSongId),
    fileId: Value(song.fileId),
    hashStandard: Value(song.hashes.standard),
    hashHigh: Value(song.hashes.high),
    hashFlac: Value(song.hashes.flac),
    hashHiRes: Value(song.hashes.hiRes),
    hashSuper: Value(song.hashes.superHash),
    favorite: Value(favorite),
    lastPlayedAt: Value(lastPlayedAt),
    playCount: Value(playCount),
  );
}

Song _rowToSong(LibraryTrack row) => Song(
  id: row.id,
  title: row.title,
  artist: row.artist,
  album: row.album,
  durationSecs: row.durationSecs,
  artworkUrl: row.artworkUrl,
  privilege: row.privilege,
  albumId: row.albumId,
  mixSongId: row.mixSongId,
  fileId: row.fileId,
  hashes: AudioHashes(
    standard: row.hashStandard,
    high: row.hashHigh,
    flac: row.hashFlac,
    hiRes: row.hashHiRes,
    superHash: row.hashSuper,
  ),
);
