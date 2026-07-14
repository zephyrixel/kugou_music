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

@DriftDatabase(tables: [LibraryTracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'kgmusic'));
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

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
