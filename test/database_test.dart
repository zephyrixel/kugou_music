import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('response cache is account scoped and clearable', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.writeCachedResponse(
      cacheKey: 'v1/user/42/cloud/playlists/1/50',
      accountUserId: 42,
      codecVersion: 1,
      payload: '{"items":[]}',
    );
    await database.writeCachedResponse(
      cacheKey: 'v1/guest/search/songs/example/1/30',
      accountUserId: null,
      codecVersion: 1,
      payload: '{"items":[]}',
    );

    expect(
      (await database.readCachedResponse(
        'v1/user/42/cloud/playlists/1/50',
      ))!.payload,
      '{"items":[]}',
    );
    await database.clearAccountCache(userId: 42);
    expect(
      await database.readCachedResponse('v1/user/42/cloud/playlists/1/50'),
      isNull,
    );
    expect(
      await database.readCachedResponse('v1/guest/search/songs/example/1/30'),
      isNotNull,
    );

    await database.clearResponseCache();
    expect(
      await database.readCachedResponse('v1/guest/search/songs/example/1/30'),
      isNull,
    );
  });

  test('library records local history without outbox', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final store = LibraryStore(database);
    const song = Song(
      id: 'mix:42',
      title: 'History Song',
      mixSongId: 42,
      hashes: AudioHashes(standard: 'hash'),
    );

    await store.replaceLibrary(
      userId: 7,
      playlists: const [],
      history: const [],
    );
    await store.recordPlayed(song);
    await store.recordPlayed(song);
    final restored = (await store.watchHistory().first).single;

    expect(restored.song.mixSongId, 42);
    expect(restored.playCount, 2);
  });

  test('schema upgrades drop outbox and legacy library tables', () async {
    final sqliteDatabase = sqlite.sqlite3.openInMemory();
    sqliteDatabase.execute('''
      CREATE TABLE library_tracks (
        id TEXT NOT NULL PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        duration_secs INTEGER,
        artwork_url TEXT,
        privilege INTEGER,
        album_id INTEGER,
        mix_song_id INTEGER,
        file_id INTEGER,
        hash_standard TEXT,
        hash_high TEXT,
        hash_flac TEXT,
        hash_hi_res TEXT,
        hash_super TEXT,
        favorite INTEGER NOT NULL DEFAULT 0 CHECK (favorite IN (0, 1)),
        last_played_at INTEGER,
        play_count INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE library_outbox (
        dedupe_key TEXT NOT NULL PRIMARY KEY,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        revision INTEGER NOT NULL DEFAULT 1,
        attempts INTEGER NOT NULL DEFAULT 0,
        next_attempt_at INTEGER,
        last_error TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
      CREATE TABLE cached_responses (
        cache_key TEXT NOT NULL PRIMARY KEY,
        account_user_id INTEGER,
        codec_version INTEGER NOT NULL,
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        last_accessed_at INTEGER NOT NULL
      );
      INSERT INTO library_tracks (id, title, favorite)
      VALUES ('mix:1', 'Legacy Favorite', 1);
      INSERT INTO cached_responses
        (cache_key, account_user_id, codec_version, payload, updated_at, last_accessed_at)
      VALUES
        ('v1/user/7/cloud/playlists/1/50', 7, 1, '{}', 0, 0),
        ('v1/user/7/search/songs/x/1/30', 7, 1, '{}', 0, 0);
      PRAGMA user_version = 3;
    ''');
    final database = AppDatabase.forTesting(
      NativeDatabase.opened(sqliteDatabase),
    );
    addTearDown(database.close);

    await database.customSelect('SELECT 1').get();

    final tableNames =
        (await database
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type = 'table'",
                )
                .get())
            .map((row) => row.read<String>('name'))
            .toSet();
    expect(tableNames, contains('stored_songs'));
    expect(tableNames, contains('library_sync_states'));
    expect(tableNames, isNot(contains('library_outbox')));
    expect(tableNames, isNot(contains('library_tracks')));
    expect(
      await database.readCachedResponse('v1/user/7/cloud/playlists/1/50'),
      isNull,
    );
    expect(
      await database.readCachedResponse('v1/user/7/search/songs/x/1/30'),
      isNotNull,
    );
  });
}
