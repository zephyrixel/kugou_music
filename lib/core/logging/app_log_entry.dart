import 'dart:convert';
import 'package:kgmusic/core/logging/log_redaction.dart';

import 'package:kgmusic/core/logging/app_log_level.dart';

class AppLogEntry {
  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.target,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final AppLogLevel level;
  final String source;
  final String target;
  final String message;
  final String? error;
  final String? stackTrace;

  String toJsonLine() => jsonEncode({
    'timestampMs': timestamp.millisecondsSinceEpoch,
    'level': level.name,
    'source': source,
    'target': target,
    'message': redactLogText(message),
    if (error != null) 'error': redactLogText(error!),
    if (stackTrace != null) 'stackTrace': redactLogText(stackTrace!),
  });

  static AppLogEntry? tryParse(String line) {
    try {
      final value = jsonDecode(line);
      if (value is! Map<String, dynamic>) return null;
      final timestamp = value['timestampMs'];
      final message = value['message'];
      if (timestamp is! num || message is! String) return null;
      return AppLogEntry(
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()),
        level: AppLogLevel.parse(value['level'] as String?),
        source: value['source'] as String? ?? 'unknown',
        target: value['target'] as String? ?? 'unknown',
        message: message,
        error: value['error'] as String?,
        stackTrace: value['stackTrace'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  String get details => [message, ?error, ?stackTrace].join('\n');
}
