import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/app/app.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/library/library_sync_service.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  final database = AppDatabase();
  final sdk = KugouMusicSdk(const FlutterSecureStorage());
  await sdk.initialize();
  final libraryStore = LibraryStore(database);
  final librarySync = LibrarySyncService(sdk, libraryStore);
  final library = LibraryRepository(libraryStore, librarySync);
  final audioCache = await AudioCacheManager.create();
  final audioHandler = await AudioService.init<MusicAudioHandler>(
    builder: () => MusicAudioHandler(sdk, library, audioCache),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.zephyrixel.kgmusic.playback',
      androidNotificationChannelName: 'KGMusic 播放',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        musicSdkProvider.overrideWithValue(sdk),
        databaseProvider.overrideWithValue(database),
        libraryRepositoryProvider.overrideWithValue(library),
        audioCacheProvider.overrideWithValue(audioCache),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: KgMusicApp(),
    ),
  );
}
