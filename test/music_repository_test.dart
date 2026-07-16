import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/cache/music_repository.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';

void main() {
  const cachedSong = Song(
    id: 'cached',
    title: 'Cached',
    hashes: AudioHashes(standard: 'cached-hash'),
  );
  const freshSong = Song(
    id: 'fresh',
    title: 'Fresh',
    hashes: AudioHashes(standard: 'fresh-hash'),
  );

  test('repository emits cached data before the refreshed response', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await MusicRepository(
      _FakeMusicSdk(() async => const [cachedSong]),
      database,
    ).everydayRecommendations(userId: 42).last;

    final remote = _FakeMusicSdk(() async => const [freshSong]);
    final values = await MusicRepository(
      remote,
      database,
      now: () => DateTime.now().add(const Duration(hours: 7)),
    ).everydayRecommendations(userId: 42).toList();

    expect(values.map((songs) => songs.single.title), ['Cached', 'Fresh']);
    expect(remote.dailyCalls, 1);
  });

  test('retryable refresh failure keeps cached data', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await MusicRepository(
      _FakeMusicSdk(() async => const [cachedSong]),
      database,
    ).everydayRecommendations(userId: 42).last;
    final remote = _FakeMusicSdk(
      () => Future.error(const MusicSdkException('offline', retryable: true)),
    );

    final values = await MusicRepository(
      remote,
      database,
    ).everydayRecommendations(userId: 42).toList();

    expect(values.single.single.title, 'Cached');
  });

  test('authentication failures are not hidden by cached data', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await MusicRepository(
      _FakeMusicSdk(() async => const [cachedSong]),
      database,
    ).everydayRecommendations(userId: 42).last;
    final remote = _FakeMusicSdk(
      () => Future.error(const MusicSdkException('expired', expired: true)),
    );

    await expectLater(
      MusicRepository(
        remote,
        database,
        now: () => DateTime.now().add(const Duration(hours: 7)),
      ).everydayRecommendations(userId: 42),
      emitsInOrder([
        predicate<List<Song>>((songs) => songs.single.title == 'Cached'),
        emitsError(isA<MusicSdkException>()),
      ]),
    );
  });

  test('identical concurrent requests share one remote call', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final completer = Completer<List<Song>>();
    final remote = _FakeMusicSdk(() => completer.future);
    final repository = MusicRepository(remote, database);

    final first = repository.everydayRecommendations(userId: 7).last;
    final second = repository.everydayRecommendations(userId: 7).last;
    await Future<void>.delayed(Duration.zero);
    expect(remote.dailyCalls, 1);
    completer.complete(const [freshSong]);

    expect((await first).single.title, 'Fresh');
    expect((await second).single.title, 'Fresh');
  });

  test(
    'fresh cache suppresses repeated network requests until its TTL expires',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      var now = DateTime.utc(2026, 7, 16, 8);
      final remote = _FakeMusicSdk(() async => const [freshSong]);
      final repository = MusicRepository(remote, database, now: () => now);

      await repository.everydayRecommendations(userId: 42).last;
      await repository.everydayRecommendations(userId: 42).last;
      expect(remote.dailyCalls, 1);

      now = now.add(const Duration(hours: 7));
      await repository.everydayRecommendations(userId: 42).last;
      expect(remote.dailyCalls, 2);
    },
  );
}

class _FakeMusicSdk implements BrowseSdk {
  _FakeMusicSdk(this._dailyLoader);

  final Future<List<Song>> Function() _dailyLoader;
  int dailyCalls = 0;

  @override
  Future<List<Song>> everydayRecommendations() {
    dailyCalls += 1;
    return _dailyLoader();
  }

  @override
  Future<SearchPage> search(
    String keyword, {
    int page = 1,
    int pageSize = 30,
  }) async => SearchPage(songs: const [], page: page, pageSize: pageSize);

  @override
  Future<PlaylistSearchPage> searchPlaylists(
    String keyword, {
    int page = 1,
    int pageSize = 30,
  }) async =>
      PlaylistSearchPage(items: const [], page: page, pageSize: pageSize);

  @override
  Future<SearchPage> publicPlaylistTracks(
    String globalCollectionId, {
    int page = 1,
    int pageSize = 50,
  }) async => SearchPage(songs: const [], page: page, pageSize: pageSize);

  @override
  Future<UserProfile> userProfile() async =>
      const UserProfile(displayName: 'test');

  @override
  Future<UserVip> userVip() async => const UserVip();
}
