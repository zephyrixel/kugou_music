import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/app/app.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/cache/music_repository.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_remote.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/logging/app_log_handlers.dart';
import 'package:kgmusic/core/logging/app_logging_controller.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/audio_service_config.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/player/playback_queue_sources.dart';
import 'package:kgmusic/core/player/playback_queue_store.dart';
import 'package:kgmusic/core/preferences/app_settings.dart';
import 'package:kgmusic/core/preferences/preference_store.dart';
import 'package:kgmusic/core/recommendation/recommendation_playback.dart';
import 'package:kgmusic/core/recommendation/recommendation_reporter.dart';
import 'package:kgmusic/core/widgets/app_error_bus.dart';
import 'package:kgmusic/src/rust/frb_generated.dart';

Future<void> main() async {
  await runZonedGuarded(_bootstrap, (error, stackTrace) {
    AppLog.error(
      '应用发生未捕获异常',
      target: 'bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferenceStore = SharedPreferenceStore();
  final settings = await AppSettingsController.create(preferenceStore);
  final logging = await AppLoggingController.create(preferenceStore);
  installAppLogErrorHandlers();
  await RustLib.init();
  await logging.initializeNative();
  AppLog.info('KGMusic 启动', target: 'bootstrap');

  final database = AppDatabase();
  final sdk = KugouMusicSdk(const FlutterSecureStorage());
  await sdk.initialize();
  final appErrorBus = AppErrorBus();
  final recommendationReporter = RecommendationReporter(sdk, appErrorBus);
  final recommendationPlayback = RecommendationPlayback(
    sdk,
    recommendationReporter,
  );
  final libraryStore = LibraryStore(database);
  final libraryRemote = LibraryRemote(sdk);
  final library = LibraryRepository(
    libraryStore,
    libraryRemote,
    recommendationReporter: recommendationReporter,
  );
  final audioCache = await AudioCacheManager.create(
    maxBytes: settings.settings.audioCacheMaxBytes,
  );
  final musicRepository = MusicRepository(sdk, database);
  final queueStore = PlaybackQueueStore(database);
  final queueSourceFactory = PlaybackQueueSourceFactory(
    musicRepository: musicRepository,
    libraryRepository: library,
    sdk: sdk,
    recommendationPlayback: recommendationPlayback,
  );
  final audioHandler = await AudioService.init<MusicAudioHandler>(
    builder: () => MusicAudioHandler(
      sdk,
      library.recordPlayed,
      audioCache,
      reportRecommendationPlayed: library.reportRecommendationPlayed,
      queueStore: queueStore,
      queueSourceFactory: queueSourceFactory,
      initialQuality: settings.settings.defaultPlaybackQuality,
      persistPreferredQuality: settings.setDefaultPlaybackQuality,
    ),
    config: kgMusicAudioServiceConfig,
  );

  runApp(
    ProviderScope(
      overrides: [
        musicSdkProvider.overrideWithValue(sdk),
        lyricsSdkProvider.overrideWithValue(sdk),
        databaseProvider.overrideWithValue(database),
        musicRepositoryProvider.overrideWithValue(musicRepository),
        libraryRepositoryProvider.overrideWithValue(library),
        audioCacheProvider.overrideWithValue(audioCache),
        playbackQueueFactoryProvider.overrideWithValue(queueSourceFactory),
        appErrorBusProvider.overrideWithValue(appErrorBus),
        appLoggingControllerProvider.overrideWith((ref) => logging),
        appSettingsControllerProvider.overrideWith((ref) => settings),
        recommendationReporterProvider.overrideWithValue(
          recommendationReporter,
        ),
        recommendationPlaybackProvider.overrideWithValue(
          recommendationPlayback,
        ),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const KgMusicApp(),
    ),
  );
}
