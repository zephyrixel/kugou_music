import 'dart:async';
import 'dart:developer' as developer;

import 'package:kgmusic/core/logging/app_log_entry.dart';
import 'package:kgmusic/core/logging/app_log_level.dart';
import 'package:kgmusic/core/logging/app_log_store.dart';

abstract final class AppLog {
  static AppLogStore? _store;
  static AppLogLevel _level = AppLogLevel.info;

  static AppLogLevel get level => _level;

  static void initialize(AppLogStore store, AppLogLevel level) {
    _store = store;
    _level = level;
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

  static void trace(String message, {String target = 'app'}) =>
      _write(AppLogLevel.trace, message, target: target);

  static void _write(
    AppLogLevel level,
    String message, {
    required String target,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_level.allows(level)) return;
    final safeMessage = _redact(message);
    final safeError = error == null ? null : _redact(error.toString());
    final entry = AppLogEntry(
      timestamp: DateTime.now(),
      level: level,
      source: 'flutter',
      target: target,
      message: safeMessage,
      error: safeError,
      stackTrace: stackTrace?.toString(),
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
    unawaited(store.append(entry).catchError((_) {}));
  }

  static String _redact(String value) {
    var result = value.replaceAllMapped(
      RegExp(
        r'(token|signature|vip_token|authorization|cookie|password|passwd)(\s*[=:]\s*)([^\s&,;}]+)',
        caseSensitive: false,
      ),
      (match) => '${match[1]}${match[2]}***',
    );
    result = result.replaceAllMapped(
      RegExp(
        r'(sms[_-]?code|verify[_-]?code|验证码)(\s*[=:：]\s*)(\d{4,8})',
        caseSensitive: false,
      ),
      (match) => '${match[1]}${match[2]}***',
    );
    result = result.replaceAllMapped(
      RegExp(r'(?<!\d)1\d{10}(?!\d)'),
      (match) => '${match[0]!.substring(0, 3)}****${match[0]!.substring(7)}',
    );
    return result;
  }
}
