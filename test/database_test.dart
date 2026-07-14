import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/song.dart';

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

  test('local history preserves the cloud file id', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    const song = Song(
      id: 'mix:42',
      title: 'History Song',
      fileId: 88,
      hashes: AudioHashes(standard: 'hash'),
    );

    await database.recordPlayed(song);
    final restored = (await database.watchHistory().first).single;

    expect(restored.fileId, 88);
  });
}
