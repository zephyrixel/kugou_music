import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/cache/cache_coordinator.dart';
import 'package:kgmusic/core/cache/music_repository.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/features/auth/auth_controller.dart';

final musicSdkProvider = Provider<MusicSdk>(
  (ref) => throw UnimplementedError('musicSdkProvider must be overridden'),
);

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final musicRepositoryProvider = Provider<MusicRepository>(
  (ref) =>
      MusicRepository(ref.watch(musicSdkProvider), ref.watch(databaseProvider)),
);

final audioHandlerProvider = Provider<MusicAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider must be overridden'),
);

final audioCacheProvider = Provider<AudioCacheManager>(
  (ref) => throw UnimplementedError('audioCacheProvider must be overridden'),
);

final cacheCoordinatorProvider = Provider<CacheCoordinator>(
  (ref) => CacheCoordinator(
    ref.watch(databaseProvider),
    ref.watch(audioCacheProvider),
  ),
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(
    ref.watch(musicSdkProvider),
    ref.watch(secureStorageProvider),
    ref.watch(databaseProvider),
  );
  unawaited(controller.initialize());
  return controller;
});

final dailyRecommendationsProvider = StreamProvider<List<Song>>((ref) {
  final auth = ref.watch(authControllerProvider);
  return ref
      .watch(musicRepositoryProvider)
      .everydayRecommendations(userId: auth.snapshot.userId);
});

final favoritesProvider = StreamProvider<List<Song>>(
  (ref) => ref.watch(databaseProvider).watchFavorites(),
);

final historyProvider = StreamProvider<List<Song>>(
  (ref) => ref.watch(databaseProvider).watchHistory(),
);

final userProfileProvider = StreamProvider<UserProfile>((ref) {
  final auth = ref.watch(authControllerProvider);
  final userId = auth.snapshot.userId;
  if (userId == null) return const Stream.empty();
  return ref.watch(musicRepositoryProvider).userProfile(userId);
});

final userVipProvider = StreamProvider<UserVip>((ref) {
  final auth = ref.watch(authControllerProvider);
  final userId = auth.snapshot.userId;
  if (userId == null) return const Stream.empty();
  return ref.watch(musicRepositoryProvider).userVip(userId);
});

final cloudPlaylistsProvider =
    AsyncNotifierProvider<CloudPlaylistsController, CloudPlaylistPage>(
      CloudPlaylistsController.new,
    );

class CloudPlaylistsController extends AsyncNotifier<CloudPlaylistPage> {
  bool _loadingMore = false;
  int _lastPageItemCount = 0;
  int _generation = 0;
  final Map<int, CloudPlaylistPage> _pages = {};

  @override
  Future<CloudPlaylistPage> build() async {
    final generation = ++_generation;
    _loadingMore = false;
    _pages.clear();
    final auth = ref.watch(authControllerProvider);
    final userId = auth.snapshot.userId;
    if (userId == null) {
      return const CloudPlaylistPage(items: [], page: 1, pageSize: 50);
    }
    final iterator = StreamIterator(
      ref.watch(musicRepositoryProvider).cloudPlaylists(userId),
    );
    ref.onDispose(iterator.cancel);
    if (!await iterator.moveNext()) {
      return const CloudPlaylistPage(items: [], page: 1, pageSize: 50);
    }
    final result = iterator.current;
    _pages[result.page] = result;
    _updateLastPageItemCount();
    unawaited(_consumeFirstPage(iterator, generation));
    return _aggregatePages();
  }

  Future<void> _consumeFirstPage(
    StreamIterator<CloudPlaylistPage> iterator,
    int generation,
  ) async {
    try {
      await Future<void>.delayed(Duration.zero);
      while (await iterator.moveNext()) {
        if (!ref.mounted || generation != _generation) return;
        final fresh = iterator.current;
        _pages[fresh.page] = fresh;
        _updateLastPageItemCount();
        state = AsyncData(_aggregatePages());
      }
    } catch (error, stackTrace) {
      if (ref.mounted && generation == _generation) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || _loadingMore) return;
    if (!canLoadNextPage(
      loadedItemCount: current.items.length,
      lastPageItemCount: _lastPageItemCount,
      pageSize: current.pageSize,
      total: current.total,
    )) {
      return;
    }

    _loadingMore = true;
    final generation = _generation;
    try {
      final userId = ref.read(authControllerProvider).snapshot.userId;
      if (userId == null) return;
      final requestedPage = _pages.keys.isEmpty
          ? 1
          : _pages.keys.reduce((a, b) => a > b ? a : b) + 1;
      await for (final next
          in ref
              .read(musicRepositoryProvider)
              .cloudPlaylists(
                userId,
                page: requestedPage,
                pageSize: current.pageSize,
              )) {
        if (!ref.mounted || generation != _generation) return;
        _pages[next.page] = next;
        _updateLastPageItemCount();
        state = AsyncData(_aggregatePages());
      }
    } finally {
      if (generation == _generation) _loadingMore = false;
    }
  }

  String _playlistKey(CloudPlaylist playlist) =>
      playlist.listId?.toString() ??
      playlist.globalCollectionId ??
      playlist.name;

  CloudPlaylistPage _aggregatePages() {
    final snapshots = _pages.values.toList()
      ..sort((a, b) => a.page.compareTo(b.page));
    if (snapshots.isEmpty) {
      return const CloudPlaylistPage(items: [], page: 1, pageSize: 50);
    }
    final items = <CloudPlaylist>[];
    final known = <String>{};
    for (final snapshot in snapshots) {
      for (final playlist in snapshot.items) {
        if (known.add(_playlistKey(playlist))) items.add(playlist);
      }
    }
    final latest = snapshots.last;
    return CloudPlaylistPage(
      items: List.unmodifiable(items),
      page: latest.page,
      pageSize: latest.pageSize,
      total: latest.total ?? snapshots.first.total,
      totalVersion: latest.totalVersion ?? snapshots.first.totalVersion,
    );
  }

  void _updateLastPageItemCount() {
    if (_pages.isEmpty) {
      _lastPageItemCount = 0;
      return;
    }
    final lastPage = _pages.keys.reduce((a, b) => a > b ? a : b);
    final earlierKeys = <String>{};
    for (final entry in _pages.entries) {
      if (entry.key >= lastPage) continue;
      earlierKeys.addAll(entry.value.items.map(_playlistKey));
    }
    _lastPageItemCount = _pages[lastPage]!.items
        .where((item) => !earlierKeys.contains(_playlistKey(item)))
        .length;
  }
}

final cloudHistoryProvider = StreamProvider<List<Song>>((ref) {
  final userId = ref.watch(authControllerProvider).snapshot.userId;
  if (userId == null) return const Stream.empty();
  return ref.watch(musicRepositoryProvider).cloudHistory(userId);
});

final myFavoritePlaylistProvider = FutureProvider<CloudPlaylist?>((ref) async {
  final page = await ref.watch(cloudPlaylistsProvider.future);
  for (final playlist in page.items) {
    if (playlist.isMyFavorite) return playlist;
  }
  return null;
});

final myFavoriteSongsProvider = StreamProvider<List<Song>>((ref) async* {
  final auth = ref.watch(authControllerProvider);
  final playlist = await ref.watch(myFavoritePlaylistProvider.future);
  final userId = auth.snapshot.userId;
  if (playlist == null || userId == null) return;
  await for (final result
      in ref.watch(musicRepositoryProvider).playlistTracks(userId, playlist)) {
    yield result.songs;
  }
});
