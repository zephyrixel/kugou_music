import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/app/app.dart';
import 'package:kgmusic/app/bootstrap_failure.dart';
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
import 'package:kgmusic/core/platform/desktop_lifecycle_controller.dart';
import 'package:kgmusic/core/platform/platform_audio_runtime.dart';
import 'package:kgmusic/core/player/audio_service_config.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/player/playback_queue_sources.dart';
import 'package:kgmusic/core/player/playback_queue_store.dart';
import 'package:kgmusic/core/preferences/app_settings.dart';
import 'package:kgmusic/core/preferences/preference_store.dart';
import 'package:kgmusic/core/recommendation/recommendation_playback.dart';
import 'package:kgmusic/core/recommendation/recommendation_profile_store.dart';
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
  try {
    await _bootstrapApp();
  } catch (error, stackTrace) {
    _showBootstrapFailure(
      const BootstrapFailure(BootstrapFailureKind.app),
      error,
      stackTrace,
    );
  }
}

Future<void> _bootstrapApp() async {
  final preferenceStore = SharedPreferenceStore();
  AppLoggingController? logging;
  AppDatabase? database;
  MusicAudioHandler? audioHandler;
  LibraryRepository? library;
  AppErrorBus? appErrorBus;
  try {
    PlatformAudioRuntime.initialize();
  } catch (error, stackTrace) {
    _showBootstrapFailure(
      const BootstrapFailure(BootstrapFailureKind.audio),
      error,
      stackTrace,
    );
    return;
  }

  final settings = await AppSettingsController.create(preferenceStore);
  logging = await AppLoggingController.create(preferenceStore);
  installAppLogErrorHandlers();
  try {
    await RustLib.init();
  } catch (error, stackTrace) {
    _showBootstrapFailure(
      const BootstrapFailure(BootstrapFailureKind.nativeRuntime),
      error,
      stackTrace,
    );
    return;
  }
  await logging.initializeNative();
  AppLog.info('KGMusic 启动', target: 'bootstrap');

  database = AppDatabase();
  try {
    await database.customSelect('SELECT 1').getSingle();
  } catch (error, stackTrace) {
    await database.close();
    _showBootstrapFailure(
      const BootstrapFailure(BootstrapFailureKind.database),
      error,
      stackTrace,
    );
    return;
  }
  final sdk = KugouMusicSdk(const FlutterSecureStorage());
  try {
    await sdk.initialize();
  } catch (error, stackTrace) {
    await database.close();
    _showBootstrapFailure(
      BootstrapFailure(_sdkFailureKind(error)),
      error,
      stackTrace,
    );
    return;
  }
  appErrorBus = AppErrorBus();
  final libraryStore = LibraryStore(database);
  final recommendationProfileStore = RecommendationProfileStore(database);
  final recommendationReporter = RecommendationReporter(
    sdk,
    recommendationProfileStore,
    appErrorBus,
  );
  final recommendationPlayback = RecommendationPlayback(
    sdk,
    recommendationReporter,
  );
  final libraryRemote = LibraryRemote(sdk);
  library = LibraryRepository(
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
  try {
    audioHandler = await AudioService.init<MusicAudioHandler>(
      builder: () => MusicAudioHandler(
        sdk,
        library!.recordPlayed,
        audioCache,
        recordRecommendationPlayback: recommendationReporter.recordPlayback,
        queueStore: queueStore,
        queueSourceFactory: queueSourceFactory,
        initialQuality: settings.settings.defaultPlaybackQuality,
        persistPreferredQuality: settings.setDefaultPlaybackQuality,
      ),
      config: kgMusicAudioServiceConfig,
    );
  } catch (error, stackTrace) {
    await library.dispose();
    await database.close();
    _showBootstrapFailure(
      const BootstrapFailure(BootstrapFailureKind.audio),
      error,
      stackTrace,
    );
    return;
  }

  final desktopLifecycle = DesktopLifecycleController(
    audioHandler: audioHandler,
    preferences: preferenceStore,
    shutdown: () async {
      await _shutdownStep(audioHandler!.dispose);
      await _shutdownStep(library!.dispose);
      await _shutdownStep(database!.close);
      await _shutdownStep(appErrorBus!.dispose);
    },
    finalizeShutdown: () async {
      try {
        await logging!.disposeResources();
      } finally {
        RustLib.dispose();
      }
    },
  );
  try {
    await desktopLifecycle.initialize();
  } catch (error, stackTrace) {
    await desktopLifecycle.recoverFromInitializationFailure();
    AppLog.warn(
      '桌面窗口或托盘初始化失败，应用将继续运行',
      target: 'desktop.lifecycle',
      error: error,
      stackTrace: stackTrace,
    );
  }

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
        appLoggingControllerProvider.overrideWith((ref) => logging!),
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

BootstrapFailureKind _sdkFailureKind(Object error) {
  if (error is PlatformException || error is MissingPluginException) {
    return BootstrapFailureKind.secureStorage;
  }
  return BootstrapFailureKind.app;
}

Future<void> _shutdownStep(Future<void> Function() operation) async {
  try {
    await operation();
  } catch (error, stackTrace) {
    AppLog.warn(
      '退出时释放资源失败',
      target: 'desktop.lifecycle',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

void _showBootstrapFailure(
  BootstrapFailure failure,
  Object error,
  StackTrace stackTrace,
) {
  AppLog.error(
    failure.title,
    target: 'bootstrap',
    error: error,
    stackTrace: stackTrace,
  );
  runApp(BootstrapFailureApp(failure: failure));
}
