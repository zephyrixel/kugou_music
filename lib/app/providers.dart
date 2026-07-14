import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

final audioHandlerProvider = Provider<MusicAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider must be overridden'),
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

final dailyRecommendationsProvider = FutureProvider<List<Song>>(
  (ref) => ref.watch(musicSdkProvider).everydayRecommendations(),
);

final favoritesProvider = StreamProvider<List<Song>>(
  (ref) => ref.watch(databaseProvider).watchFavorites(),
);

final historyProvider = StreamProvider<List<Song>>(
  (ref) => ref.watch(databaseProvider).watchHistory(),
);

final userProfileProvider = FutureProvider<UserProfile>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(musicSdkProvider).userProfile();
});

final userVipProvider = FutureProvider<UserVip>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(musicSdkProvider).userVip();
});

final cloudPlaylistsProvider =
    AsyncNotifierProvider<CloudPlaylistsController, CloudPlaylistPage>(
      CloudPlaylistsController.new,
    );

class CloudPlaylistsController extends AsyncNotifier<CloudPlaylistPage> {
  bool _loadingMore = false;
  int _lastPageItemCount = 0;

  @override
  Future<CloudPlaylistPage> build() async {
    final auth = ref.watch(authControllerProvider);
    final result = await ref.watch(musicSdkProvider).cloudPlaylists();
    _lastPageItemCount = result.items.length;
    await _cache(auth.snapshot.userId, result.items);
    return result;
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
    try {
      final next = await ref
          .read(musicSdkProvider)
          .cloudPlaylists(page: current.page + 1, pageSize: current.pageSize);
      _lastPageItemCount = next.items.length;
      final merged = <CloudPlaylist>[...current.items];
      final known = current.items.map(_playlistKey).toSet();
      for (final playlist in next.items) {
        if (known.add(_playlistKey(playlist))) merged.add(playlist);
      }
      if (merged.length == current.items.length) _lastPageItemCount = 0;
      final result = CloudPlaylistPage(
        items: List.unmodifiable(merged),
        page: next.page,
        pageSize: next.pageSize,
        total: next.total ?? current.total,
        totalVersion: next.totalVersion ?? current.totalVersion,
      );
      await _cache(
        ref.read(authControllerProvider).snapshot.userId,
        result.items,
      );
      state = AsyncData(result);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> _cache(int? userId, List<CloudPlaylist> playlists) async {
    if (userId == null) return;
    await ref.read(databaseProvider).cacheCloudPlaylists(userId, playlists);
  }

  String _playlistKey(CloudPlaylist playlist) =>
      playlist.listId?.toString() ??
      playlist.globalCollectionId ??
      playlist.name;
}

final cloudHistoryProvider = FutureProvider<List<Song>>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(musicSdkProvider).cloudHistory();
});

final myFavoritePlaylistProvider = FutureProvider<CloudPlaylist?>((ref) async {
  final page = await ref.watch(cloudPlaylistsProvider.future);
  for (final playlist in page.items) {
    if (playlist.isMyFavorite) return playlist;
  }
  return null;
});

final myFavoriteSongsProvider = FutureProvider<List<Song>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final playlist = await ref.watch(myFavoritePlaylistProvider.future);
  if (playlist == null) return const [];
  final result = await ref.watch(musicSdkProvider).playlistTracks(playlist);
  final userId = auth.snapshot.userId;
  if (userId != null && playlist.listId != null) {
    await ref
        .read(databaseProvider)
        .cacheCloudTracks(userId, playlist.listId!, result.songs);
  }
  return result.songs;
});
