import 'dart:async';

import 'package:drift/native.dart';
import 'package:kgmusic/core/auth/account_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/cache/music_repository.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/discovery_card.dart';
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

  test('synchronous SDK failures preserve their original error', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final failure = StateError('transport');
    final remote = _FakeMusicSdk(() => throw failure);
    final repository = MusicRepository(remote, database);
    await expectLater(
      repository.everydayRecommendations(userId: 7).last,
      throwsA(same(failure)),
    );
  });

  test(
    'a response from a previous session cannot refill account cache',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final session = AccountSession()
        ..update(
          const AuthSnapshot(
            authenticated: true,
            fingerprintRegistered: true,
            userId: 7,
          ),
        );
      addTearDown(session.dispose);
      final result = Completer<List<Song>>();
      final started = Completer<void>();
      final repository = MusicRepository(
        _FakeMusicSdk(() {
          started.complete();
          return result.future;
        }),
        database,
        accountSession: session,
      );
      final values = repository.everydayRecommendations(userId: 7).toList();
      await started.future;
      session.invalidate();
      await database.clearAccountCache();
      session.update(
        const AuthSnapshot(
          authenticated: true,
          fingerprintRegistered: true,
          userId: 7,
        ),
      );
      result.complete(const [freshSong]);
      expect(await values, isEmpty);
      expect(await database.readCachedResponse('v1/user/7/daily'), isNull);
    },
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
      var now = DateTime.utc(2026, 7, 16, 8);
      final database = AppDatabase.forTesting(
        NativeDatabase.memory(),
        now: () => now,
      );
      addTearDown(database.close);
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

  test('discovery cache is isolated by account and card id', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final remote = _FakeMusicSdk(
      () async => const [],
      discoveryLoader: (cardId, pageSize) async => DiscoveryCard(
        id: cardId,
        title: 'Card $cardId',
        songs: const [freshSong],
      ),
    );
    final repository = MusicRepository(remote, database);

    await repository.discoveryCard(3001, userId: 1).last;
    await repository.discoveryCard(3001, userId: 1).last;
    await repository.discoveryCard(3004, userId: 1).last;
    await repository.discoveryCard(3001, userId: 2).last;

    expect(remote.discoveryCalls, 3);
  });
}

class _FakeMusicSdk implements BrowseSdk {
  _FakeMusicSdk(this._dailyLoader, {this.discoveryLoader});

  final Future<List<Song>> Function() _dailyLoader;
  final Future<DiscoveryCard> Function(int cardId, int pageSize)?
  discoveryLoader;
  int dailyCalls = 0;
  int discoveryCalls = 0;

  @override
  Future<List<Song>> everydayRecommendations() {
    dailyCalls += 1;
    return _dailyLoader();
  }

  @override
  Future<DiscoveryCard> discoveryCard(int cardId, {int pageSize = 10}) async {
    discoveryCalls += 1;
    return discoveryLoader?.call(cardId, pageSize) ??
        DiscoveryCard(id: cardId, title: 'Discovery', songs: const []);
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
