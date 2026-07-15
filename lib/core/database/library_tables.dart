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
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get tags => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class StoredPlaylistTracks extends Table {
  TextColumn get playlistLocalId => text()();
  TextColumn get songId => text()();
  IntColumn get fileId => integer().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  BoolColumn get remotePresent =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {playlistLocalId, songId};
}

class LibraryOutbox extends Table {
  TextColumn get dedupeKey => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {dedupeKey};
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
