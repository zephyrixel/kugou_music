import 'package:drift/drift.dart';

class StoredSongs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get durationSecs => integer().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  IntColumn get privilege => integer().nullable()();
  IntColumn get albumId => integer().nullable()();
  IntColumn get mixSongId => integer().nullable()();
  TextColumn get hashStandard => text().nullable()();
  TextColumn get hashHigh => text().nullable()();
  TextColumn get hashFlac => text().nullable()();
  TextColumn get hashHiRes => text().nullable()();
  TextColumn get hashSuper => text().nullable()();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StoredPlaylists extends Table {
  TextColumn get localId => text()();
  IntColumn get remoteListId => integer().nullable()();
  TextColumn get globalCollectionId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get intro => text().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  IntColumn get count => integer().withDefault(const Constant(0))();
  IntColumn get listType => integer().nullable()();
  IntColumn get creatorUserId => integer().nullable()();
  TextColumn get creatorName => text().nullable()();
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  BoolColumn get isMyFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isDefaultCollect =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get tracksLoaded => boolean().withDefault(const Constant(false))();
  IntColumn get trackSnapshotCount => integer().nullable()();
  DateTimeColumn get tracksUpdatedAt => dateTime().nullable()();
  DateTimeColumn get fullSnapshotUpdatedAt => dateTime().nullable()();
  TextColumn get tags => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class StoredPlaylistTracks extends Table {
  TextColumn get playlistLocalId => text()();
  TextColumn get songId => text()();
  IntColumn get fileId => integer().nullable()();
  IntColumn get collectTimeSecs => integer().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {playlistLocalId, songId};
}

class StoredRecommendationProfiles extends Table {
  IntColumn get userId => integer()();
  TextColumn get songKey => text()();
  IntColumn get action => integer()();
  TextColumn get standardHash => text().nullable()();
  IntColumn get mixSongId => integer().nullable()();
  IntColumn get eventTimeMs => integer()();
  IntColumn get count => integer().withDefault(const Constant(1))();
  IntColumn get sourceBits => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {userId, songKey, action};
}

class RecommendationSyncStates extends Table {
  IntColumn get userId => integer()();
  TextColumn get dayKey => text()();
  IntColumn get successCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAllowedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

class LibrarySyncStates extends Table {
  IntColumn get singletonId => integer().withDefault(const Constant(1))();
  IntColumn get userId => integer()();
  BoolColumn get baselineComplete =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {singletonId};
}
