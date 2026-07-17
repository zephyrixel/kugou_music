import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/logging/app_log_entry.dart';
import 'package:kgmusic/core/logging/app_log_exporter.dart';
import 'package:kgmusic/core/logging/app_log_level.dart';
import 'package:kgmusic/core/logging/app_log_store.dart';
import 'package:kgmusic/core/native/rust_bridge.dart' as bridge;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLoggingController extends ChangeNotifier {
  AppLoggingController._(this.store, this._preferences, this._level);

  static const _levelKey = 'app_log_level';

  final AppLogStore store;
  final SharedPreferences? _preferences;
  AppLogLevel _level;
  bool _nativeAvailable = false;
  String? _nativeError;

  AppLogLevel get level => _level;
  bool get nativeAvailable => _nativeAvailable;
  String? get nativeError => _nativeError;
  bool get traceActive => _level == AppLogLevel.trace;

  AppLogExporter get exporter => AppLogExporter(
    store,
    flushNative: () async {
      if (!_nativeAvailable) return;
      try {
        await bridge.flushNativeLogs();
      } catch (error) {
        throw AppLoggingException(_bridgeMessage(error));
      }
    },
  );

  static Future<AppLoggingController> create() async {
    Directory directory;
    try {
      final support = await getApplicationSupportDirectory();
      directory = Directory('${support.path}/logs');
    } catch (_) {
      directory = Directory('${Directory.systemTemp.path}/kgmusic-logs');
    }
    final store = AppLogStore(directory);
    try {
      await store.initialize();
    } catch (_) {
      // File logging is best effort and must never prevent application startup.
    }
    SharedPreferences? preferences;
    try {
      preferences = await SharedPreferences.getInstance();
    } catch (_) {
      // Keep the default level when platform preferences are unavailable.
    }
    final persisted = AppLogLevel.parse(preferences?.getString(_levelKey));
    final startupLevel = persisted == AppLogLevel.trace
        ? AppLogLevel.debug
        : persisted;
    final controller = AppLoggingController._(store, preferences, startupLevel);
    AppLog.initialize(store, startupLevel);
    return controller;
  }

  Future<void> initializeNative() async {
    try {
      await bridge.initializeNativeLogging(
        directory: store.directory.path,
        level: _nativeLevel(_level),
      );
      _nativeAvailable = true;
      _nativeError = null;
      AppLog.info('Native 日志已初始化', target: 'bootstrap');
    } catch (error, stackTrace) {
      _nativeAvailable = false;
      _nativeError = error is bridge.BridgeError
          ? error.message
          : error.toString();
      AppLog.warn(
        'Native 日志初始化失败，应用将继续运行',
        target: 'bootstrap',
        error: _nativeError,
        stackTrace: stackTrace,
      );
    }
    notifyListeners();
  }

  Future<void> setLevel(AppLogLevel level) async {
    _level = level;
    AppLog.setLevel(level);
    final persistedLevel = level == AppLogLevel.trace
        ? AppLogLevel.debug
        : level;
    await _preferences?.setString(_levelKey, persistedLevel.name);
    Object? nativeFailure;
    if (_nativeAvailable) {
      try {
        await bridge.setNativeLogLevel(level: _nativeLevel(level));
        _nativeError = null;
      } catch (error) {
        _nativeError = _bridgeMessage(error);
        nativeFailure = AppLoggingException(_nativeError!);
      }
    }
    notifyListeners();
    AppLog.info('日志等级已切换为 ${level.label}', target: 'logging');
    if (nativeFailure != null) throw nativeFailure;
  }

  Future<List<AppLogEntry>> loadRecent({int limit = 1000}) =>
      store.readEntries(limit: limit);

  Future<int> totalBytes() => store.totalBytes();

  Future<void> clear() async {
    await store.clearFlutterLogs();
    if (_nativeAvailable) {
      try {
        await bridge.clearNativeLogs();
      } catch (error) {
        throw AppLoggingException(_bridgeMessage(error));
      }
    }
    notifyListeners();
  }

  static String _bridgeMessage(Object error) =>
      error is bridge.BridgeError ? error.message : error.toString();

  static bridge.AppLogLevelDto _nativeLevel(AppLogLevel level) =>
      switch (level) {
        AppLogLevel.off => bridge.AppLogLevelDto.off,
        AppLogLevel.error => bridge.AppLogLevelDto.error,
        AppLogLevel.warn => bridge.AppLogLevelDto.warn,
        AppLogLevel.info => bridge.AppLogLevelDto.info,
        AppLogLevel.debug => bridge.AppLogLevelDto.debug,
        AppLogLevel.trace => bridge.AppLogLevelDto.trace,
      };
}

class AppLoggingException implements Exception {
  const AppLoggingException(this.message);

  final String message;

  @override
  String toString() => message;
}
