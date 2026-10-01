import 'dart:async';

import 'package:kgmusic/core/logging/log_redaction.dart';
import 'dart:developer' as developer;

import 'package:kgmusic/core/logging/app_log_entry.dart';
import 'package:kgmusic/core/logging/app_log_level.dart';
import 'package:kgmusic/core/logging/app_log_store.dart';

abstract final class AppLog {
  static AppLogStore? _store;
  static AppLogLevel _level = AppLogLevel.info;

  static void initialize(AppLogStore store, AppLogLevel level) {
    _store = store;
    _level = level;
  }

  static void detach(AppLogStore store) {
    if (identical(_store, store)) _store = null;
  }

  static void setLevel(AppLogLevel level) => _level = level;

  static void error(
    String message, {
    String target = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) => _write(
    AppLogLevel.error,
    message,
    target: target,
    error: error,
    stackTrace: stackTrace,
  );

  static void warn(
    String message, {
    String target = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) => _write(
    AppLogLevel.warn,
    message,
    target: target,
    error: error,
    stackTrace: stackTrace,
  );

  static void info(String message, {String target = 'app'}) =>
      _write(AppLogLevel.info, message, target: target);

  static void debug(String message, {String target = 'app'}) =>
      _write(AppLogLevel.debug, message, target: target);

  static void _write(
    AppLogLevel level,
    String message, {
    required String target,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_level.allows(level)) return;
    final safeMessage = redactLogText(message);
    final safeError = error == null ? null : redactLogText(error.toString());
    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      level: level,
      source: 'flutter',
      target: target,
      message: safeMessage,
      error: safeError,
      stackTrace: stackTrace == null
          ? null
          : redactLogText(stackTrace.toString()),
    );
    final store = _store;
    if (store == null) {
      developer.log(
        safeMessage,
        name: target,
        error: safeError,
        stackTrace: stackTrace,
        level: level.priority * 200,
      );
      return;
    }
    unawaited(
      store.append(entry).catchError((Object writeError) {
        developer.log(
          'Failed to persist application log',
          name: 'logging',
          error: writeError,
        );
      }),
    );
  }
}
