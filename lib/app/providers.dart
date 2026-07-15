import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/cache/cache_coordinator.dart';
import 'package:kgmusic/core/cache/lyrics_repository.dart';
import 'package:kgmusic/core/cache/music_repository.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_models.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/history_entry.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/native/lyrics_sdk.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/features/auth/auth_controller.dart';

final musicSdkProvider = Provider<MusicSdk>(
  (ref) => throw UnimplementedError('musicSdkProvider must be overridden'),
);

final lyricsSdkProvider = Provider<LyricsSdk>(
  (ref) => throw UnimplementedError('lyricsSdkProvider must be overridden'),
);

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) =>
      throw UnimplementedError('libraryRepositoryProvider must be overridden'),
);

final musicRepositoryProvider = Provider<MusicRepository>(
  (ref) =>
      MusicRepository(ref.watch(musicSdkProvider), ref.watch(databaseProvider)),
);

final lyricsRepositoryProvider = Provider<LyricsRepository>(
  (ref) => LyricsRepository(
    ref.watch(lyricsSdkProvider),
    ref.watch(databaseProvider),
  ),
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
    ref.watch(libraryRepositoryProvider),
    onSessionCleared: () => ref.watch(audioHandlerProvider).clearQueue(),
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

final favoriteSongsProvider = StreamProvider<List<Song>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchFavorites(),
);

final favoriteSongIdsProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchFavoriteIds(),
);

final historyEntriesProvider = StreamProvider<List<HistoryEntry>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchHistory(),
);

final libraryPlaylistsProvider = StreamProvider<List<Playlist>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchPlaylists(),
);

final libraryPlaylistTracksProvider = StreamProvider.family<List<Song>, String>(
  (ref, localId) =>
      ref.watch(libraryRepositoryProvider).watchPlaylistTracks(localId),
);

final librarySyncStatusProvider = StreamProvider<LibrarySyncStatus>(
  (ref) => ref.watch(libraryRepositoryProvider).syncStatuses,
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
