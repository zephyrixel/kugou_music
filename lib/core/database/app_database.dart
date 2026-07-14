import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';

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

class CachedCloudPlaylists extends Table {
  IntColumn get accountUserId => integer()();
  IntColumn get listId => integer()();
  TextColumn get globalCollectionId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get intro => text().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  IntColumn get trackCount => integer().nullable()();
  IntColumn get listType => integer().nullable()();
  IntColumn get creatorUserId => integer().nullable()();
  TextColumn get creatorName => text().nullable()();
  BoolColumn get isPrivate => boolean()();
  BoolColumn get isMyFavorite => boolean()();
  BoolColumn get isDefaultCollect => boolean()();
  TextColumn get tags => text().nullable()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {accountUserId, listId};
}

class CachedCloudTracks extends Table {
  IntColumn get accountUserId => integer()();
  IntColumn get listId => integer()();
  TextColumn get songId => text()();
  IntColumn get fileId => integer().nullable()();
  IntColumn get position => integer()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {accountUserId, listId, songId};
}

@DriftDatabase(tables: [LibraryTracks, CachedCloudPlaylists, CachedCloudTracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'kgmusic'));
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(cachedCloudPlaylists);
        await migrator.createTable(cachedCloudTracks);
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

  Future<void> cacheCloudPlaylists(
    int userId,
    List<CloudPlaylist> playlists,
  ) async {
    final now = DateTime.now();
    await transaction(() async {
      await (delete(
        cachedCloudPlaylists,
      )..where((row) => row.accountUserId.equals(userId))).go();
      await batch((batch) {
        batch.insertAllOnConflictUpdate(
          cachedCloudPlaylists,
          playlists
              .where((item) => item.listId != null)
              .map(
                (item) => CachedCloudPlaylistsCompanion.insert(
                  accountUserId: userId,
                  listId: item.listId!,
                  globalCollectionId: Value(item.globalCollectionId),
                  name: item.name,
                  intro: Value(item.intro),
                  artworkUrl: Value(item.artworkUrl),
                  trackCount: Value(item.count),
                  listType: Value(item.listType),
                  creatorUserId: Value(item.creatorUserId),
                  creatorName: Value(item.creatorName),
                  isPrivate: item.isPrivate,
                  isMyFavorite: item.isMyFavorite,
                  isDefaultCollect: item.isDefaultCollect,
                  tags: Value(item.tags),
                  syncedAt: now,
                ),
              ),
        );
      });
    });
  }

  Stream<List<CloudPlaylist>> watchCachedCloudPlaylists(int userId) =>
      (select(cachedCloudPlaylists)
            ..where((row) => row.accountUserId.equals(userId))
            ..orderBy([(row) => OrderingTerm.asc(row.listId)]))
          .watch()
          .map(
            (rows) => rows
                .map(
                  (row) => CloudPlaylist(
                    listId: row.listId,
                    globalCollectionId: row.globalCollectionId,
                    name: row.name,
                    intro: row.intro,
                    artworkUrl: row.artworkUrl,
                    count: row.trackCount,
                    listType: row.listType,
                    creatorUserId: row.creatorUserId,
                    creatorName: row.creatorName,
                    isPrivate: row.isPrivate,
                    isMyFavorite: row.isMyFavorite,
                    isDefaultCollect: row.isDefaultCollect,
                    tags: row.tags,
                  ),
                )
                .toList(growable: false),
          );

  Future<void> cacheCloudTracks(
    int userId,
    int listId,
    List<Song> songs,
  ) async {
    final now = DateTime.now();
    await transaction(() async {
      await (delete(cachedCloudTracks)..where(
            (row) =>
                row.accountUserId.equals(userId) & row.listId.equals(listId),
          ))
          .go();
      for (var index = 0; index < songs.length; index++) {
        final song = songs[index];
        final existing = await (select(
          libraryTracks,
        )..where((row) => row.id.equals(song.id))).getSingleOrNull();
        await into(libraryTracks).insertOnConflictUpdate(
          _companion(
            song,
            favorite: existing?.favorite ?? false,
            lastPlayedAt: existing?.lastPlayedAt,
            playCount: existing?.playCount ?? 0,
          ),
        );
        await into(cachedCloudTracks).insertOnConflictUpdate(
          CachedCloudTracksCompanion.insert(
            accountUserId: userId,
            listId: listId,
            songId: song.id,
            fileId: Value(song.fileId),
            position: index,
            syncedAt: now,
          ),
        );
      }
    });
  }

  Future<void> clearCloudCache() async {
    await transaction(() async {
      await delete(cachedCloudTracks).go();
      await delete(cachedCloudPlaylists).go();
    });
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
  hashes: AudioHashes(
    standard: row.hashStandard,
    high: row.hashHigh,
    flac: row.hashFlac,
    hiRes: row.hashHiRes,
    superHash: row.hashSuper,
  ),
);
