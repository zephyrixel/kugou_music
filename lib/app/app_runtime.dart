import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kgmusic/app/bootstrap_failure.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/auth/account_session.dart';
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
import 'package:kgmusic/features/auth/auth_controller.dart';
import 'package:kgmusic/src/rust/frb_generated.dart';

class AppStartupException implements Exception {
  const AppStartupException(this.failure, this.cause, this.stackTrace);
  final BootstrapFailure failure;
  final Object cause;
  final StackTrace stackTrace;
}

/// The application owns resources once; providers expose them without creating
/// competing instances. Partial startup and normal shutdown share cleanup.
class AppRuntime {
  AppRuntime._();
  final _session = AccountSession();
  final _errors = AppErrorBus();
  final _storage = const FlutterSecureStorage();
  AppSettingsController? _settings;
  AppLoggingController? _logging;
  AppDatabase? _database;
  KugouMusicSdk? _sdk;
  LibraryRepository? _library;
  MusicRepository? _music;
  AudioCacheManager? _cache;
  RecommendationReporter? _reporter;
  RecommendationPlayback? _recommendation;
  PlaybackQueueSourceFactory? _sources;
  MusicAudioHandler? _audio;
  AuthController? _auth;
  DesktopLifecycleController? _desktop;
  bool _nativeReady = false;
  bool _closed = false;
  bool _finalized = false;

  static Future<AppRuntime> create() async {
    final runtime = AppRuntime._();
    try {
      await runtime._initialize();
      return runtime;
    } catch (_) {
      await runtime._release(
        '桌面集成',
        () async => runtime._desktop?.recoverFromInitializationFailure(),
      );
      await runtime.shutdown();
      await runtime.finalize();
      rethrow;
    }
  }

  Future<void> _initialize() async {
    var failure = BootstrapFailureKind.audio;
    try {
      PlatformAudioRuntime.initialize();
      failure = BootstrapFailureKind.app;
      final preferences = SharedPreferenceStore();
      _settings = await AppSettingsController.create(preferences);
      _logging = await AppLoggingController.create(preferences);
      installAppLogErrorHandlers();
      failure = BootstrapFailureKind.nativeRuntime;
      await RustLib.init();
      _nativeReady = true;
      await _logging!.initializeNative();
      failure = BootstrapFailureKind.database;
      _database = AppDatabase();
      await _database!.customSelect('SELECT 1').getSingle();
      failure = BootstrapFailureKind.app;
      _sdk = KugouMusicSdk(
        _storage,
        accountSession: _session,
        onSessionPersistenceFailure: () =>
            _errors.add('操作已完成，但登录信息暂未保存，将在下次请求时重试'),
      );
      try {
        await _sdk!.initialize();
      } on PlatformException {
        failure = BootstrapFailureKind.secureStorage;
        rethrow;
      } on MissingPluginException {
        failure = BootstrapFailureKind.secureStorage;
        rethrow;
      }
      _reporter = RecommendationReporter(
        _sdk!,
        RecommendationProfileStore(_database!),
        _errors,
        accountSession: _session,
        now: _database!.now,
      );
      _recommendation = RecommendationPlayback(_sdk!, _reporter!);
      _library = LibraryRepository(
        LibraryStore(_database!),
        LibraryRemote(_sdk!),
        recommendationReporter: _reporter,
        accountSession: _session,
      );
      _cache = await AudioCacheManager.create(
        maxBytes: _settings!.settings.audioCacheMaxBytes,
      );
      _music = MusicRepository(_sdk!, _database!, accountSession: _session);
      _sources = PlaybackQueueSourceFactory(
        musicRepository: _music!,
        libraryRepository: _library!,
        sdk: _sdk!,
        recommendationPlayback: _recommendation!,
      );
      failure = BootstrapFailureKind.audio;
      _audio = await AudioService.init<MusicAudioHandler>(
        builder: () => MusicAudioHandler(
          _sdk!,
          _library!.recordPlayed,
          _cache!,
          accountSession: _session,
          recordRecommendationPlayback: _reporter!.recordPlayback,
          queueStore: PlaybackQueueStore(_database!),
          queueSourceFactory: _sources,
          initialQuality: _settings!.settings.defaultPlaybackQuality,
          persistPreferredQuality: _settings!.setDefaultPlaybackQuality,
        ),
        config: kgMusicAudioServiceConfig,
      );
      _auth = AuthController(
        _sdk!,
        _storage,
        _database!,
        _library!,
        accountSession: _session,
        onSessionCleared: _audio!.clearQueue,
      );
      _desktop = DesktopLifecycleController(
        audioHandler: _audio!,
        preferences: preferences,
        shutdown: shutdown,
        finalizeShutdown: finalize,
      );
      try {
        await _desktop!.initialize();
      } catch (error) {
        await _release('恢复桌面关闭行为', _desktop!.recoverFromInitializationFailure);
        AppLog.warn(
          '桌面集成不可用，应用继续运行',
          target: 'desktop.lifecycle',
          error: error,
        );
      }
      AppLog.info('KGMusic 启动', target: 'bootstrap');
    } catch (error, stackTrace) {
      throw AppStartupException(BootstrapFailure(failure), error, stackTrace);
    }
  }

  Widget provide(Widget child) => ProviderScope(
    overrides: [
      accountSessionProvider.overrideWithValue(_session),
      secureStorageProvider.overrideWithValue(_storage),
      musicSdkProvider.overrideWithValue(_sdk!),
      lyricsSdkProvider.overrideWithValue(_sdk!),
      databaseProvider.overrideWithValue(_database!),
      musicRepositoryProvider.overrideWithValue(_music!),
      libraryRepositoryProvider.overrideWithValue(_library!),
      audioCacheProvider.overrideWithValue(_cache!),
      playbackQueueFactoryProvider.overrideWithValue(_sources!),
      appErrorBusProvider.overrideWithValue(_errors),
      appLoggingControllerProvider.overrideWith((ref) => _logging!),
      appSettingsControllerProvider.overrideWith((ref) => _settings!),
      recommendationReporterProvider.overrideWithValue(_reporter!),
      recommendationPlaybackProvider.overrideWithValue(_recommendation!),
      audioHandlerProvider.overrideWithValue(_audio!),
      authControllerProvider.overrideWith((ref) {
        unawaited(_auth!.initialize());
        return _auth!;
      }),
    ],
    child: child,
  );

  Future<void> shutdown() async {
    if (_closed) return;
    _closed = true;
    _auth?.dispose();
    await _release('播放器', () async => _audio?.dispose());
    await _release('SDK 请求', () async => _sdk?.close());
    await _release('推荐任务', () async => _reporter?.dispose());
    await _release('音乐库', () async => _library?.dispose());
    await _release('音频缓存', () async => _cache?.dispose());
    await _release('数据库', () async => _database?.close());
    await _release('账号状态', _session.dispose);
    await _release('提示消息', _errors.dispose);
  }

  Future<void> finalize() async {
    if (_finalized) return;
    _finalized = true;
    await _release('日志', () async => _logging?.disposeResources());
    if (_nativeReady) {
      RustLib.dispose();
      _nativeReady = false;
    }
  }

  Future<void> _release(String label, Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      AppLog.warn('释放$label失败', target: 'bootstrap', error: error);
    }
  }
}
