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
    final playlistColumns =
        (await database
                .customSelect('PRAGMA table_info(stored_playlists)')
                .get())
            .map((row) => row.read<String>('name'))
            .toSet();
    expect(playlistColumns, contains('track_snapshot_count'));
    expect(playlistColumns, contains('tracks_updated_at'));
    expect(
      await database.readCachedResponse('v1/user/7/cloud/playlists/1/50'),
      isNull,
    );
    expect(
      await database.readCachedResponse('v1/user/7/search/songs/x/1/30'),
      isNotNull,
    );
  });

  test('v7 升级到 v8 补齐排序列并保留既有歌单', () async {
    final sqliteDatabase = sqlite.sqlite3.openInMemory();
    // Minimal v7 shape: stored_playlists without the ordering columns.
    sqliteDatabase.execute('''
      CREATE TABLE stored_playlists (
        local_id TEXT NOT NULL PRIMARY KEY,
        remote_list_id INTEGER,
        global_collection_id TEXT,
        name TEXT NOT NULL,
        intro TEXT,
        artwork_url TEXT,
        count INTEGER NOT NULL DEFAULT 0,
        list_type INTEGER,
        creator_user_id INTEGER,
        creator_name TEXT,
        is_private INTEGER NOT NULL DEFAULT 0 CHECK (is_private IN (0, 1)),
        is_my_favorite INTEGER NOT NULL DEFAULT 0 CHECK (is_my_favorite IN (0, 1)),
        is_default_collect INTEGER NOT NULL DEFAULT 0 CHECK (is_default_collect IN (0, 1)),
        tracks_loaded INTEGER NOT NULL DEFAULT 0 CHECK (tracks_loaded IN (0, 1)),
        track_snapshot_count INTEGER,
        tracks_updated_at INTEGER,
        full_snapshot_updated_at INTEGER,
        tags TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE stored_songs (
        id TEXT NOT NULL PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        duration_secs INTEGER,
        artwork_url TEXT,
        privilege INTEGER,
        album_id INTEGER,
        mix_song_id INTEGER,
        hash_standard TEXT,
        hash_high TEXT,
        hash_flac TEXT,
        hash_hi_res TEXT,
        hash_super TEXT,
        last_played_at INTEGER,
        play_count INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE stored_playlist_tracks (
        playlist_local_id TEXT NOT NULL,
        song_id TEXT NOT NULL,
        file_id INTEGER,
        collect_time_secs INTEGER,
        position INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (playlist_local_id, song_id)
      );
      CREATE TABLE cached_responses (
        cache_key TEXT NOT NULL PRIMARY KEY,
        account_user_id INTEGER,
        codec_version INTEGER NOT NULL,
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        last_accessed_at INTEGER NOT NULL
      );
      INSERT INTO stored_playlists (local_id, name, sort_order)
      VALUES ('remote:9', '迁移前的歌单', 3);
      PRAGMA user_version = 7;
    ''');
    final database = AppDatabase.forTesting(
      NativeDatabase.opened(sqliteDatabase),
    );
    addTearDown(database.close);

    await database.customSelect('SELECT 1').get();

    final playlistColumns =
        (await database
                .customSelect('PRAGMA table_info(stored_playlists)')
                .get())
            .map((row) => row.read<String>('name'))
            .toSet();
    expect(playlistColumns, contains('created_at'));
    expect(playlistColumns, contains('updated_at'));
    expect(playlistColumns, contains('remote_sort'));

    // The pre-v8 row survives with a null timestamp and its old wire order.
    final row = await (database.select(
      database.storedPlaylists,
    )..where((item) => item.localId.equals('remote:9'))).getSingle();
    expect(row.name, '迁移前的歌单');
    expect(row.createdAt, isNull);
    expect(row.sortOrder, 3);

    final indexNames =
        (await database
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type = 'index'",
                )
                .get())
            .map((row) => row.read<String>('name'))
            .toSet();
    expect(indexNames, contains('idx_stored_playlists_order'));
    expect(indexNames, contains('idx_stored_songs_last_played_at'));
    expect(indexNames, contains('idx_playlist_tracks_playlist_position'));
    expect(indexNames, contains('idx_cached_responses_last_accessed_at'));
  });

  test('响应缓存裁剪只保留最近访问的条目', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    // Recent stamps so the retention sweep inside writeCachedResponse's
    // automatic prune leaves them alone; this test targets the count cap.
    final base = DateTime.now().subtract(const Duration(hours: 12));
    for (var i = 0; i < 10; i++) {
      await database.writeCachedResponse(
        cacheKey: 'key-$i',
        accountUserId: 1,
        codecVersion: 1,
        payload: '{}',
        updatedAt: base.add(Duration(minutes: i)),
      );
    }

    await database.pruneResponseCache(maxEntries: 3);

    final remaining = await database.select(database.cachedResponses).get();
    expect(remaining.map((row) => row.cacheKey).toSet(), {
      'key-9',
      'key-8',
      'key-7',
    });
  });

  test('条目数量未超过上限时裁剪不删除任何东西', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.writeCachedResponse(
      cacheKey: 'only',
      accountUserId: 1,
      codecVersion: 1,
      payload: '{}',
    );

    await database.pruneResponseCache();

    expect(await database.readCachedResponse('only'), isNotNull);
  });

  test('全新数据库也会建立索引', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.customSelect('SELECT 1').get();

    final indexNames =
        (await database
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type = 'index'",
                )
                .get())
            .map((row) => row.read<String>('name'))
            .toSet();
    expect(indexNames, contains('idx_stored_playlists_order'));
    expect(indexNames, contains('idx_stored_songs_last_played_at'));
  });
}
