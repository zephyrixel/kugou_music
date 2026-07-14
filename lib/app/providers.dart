import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';

final musicSdkProvider = Provider<MusicSdk>(
  (ref) => throw UnimplementedError('musicSdkProvider must be overridden'),
);

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final audioHandlerProvider = Provider<MusicAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider must be overridden'),
);

final dailyRecommendationsProvider = FutureProvider<List<Song>>(
  (ref) => ref.watch(musicSdkProvider).everydayRecommendations(),
);

final favoritesProvider = StreamProvider<List<Song>>(
  (ref) => ref.watch(databaseProvider).watchFavorites(),
);

final historyProvider = StreamProvider<List<Song>>(
  (ref) => ref.watch(databaseProvider).watchHistory(),
);
