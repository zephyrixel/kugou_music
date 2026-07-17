import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/logging/app_log_entry.dart';
import 'package:kgmusic/core/logging/app_log_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AppLogExporter {
  AppLogExporter(this.store, {required this.flushNative});

  final AppLogStore store;
  final Future<void> Function() flushNative;

  Future<File> _buildExport() async {
    await flushNative();
    final entries = await store.readEntries();
    entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final temporary = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${temporary.path}/kgmusic-logs-$timestamp.txt');
    await file.writeAsString(_format(entries), flush: true);
    return file;
  }

  Future<void> share() => _runLogged(
    '分享诊断日志失败',
    () => _withExport((file) async {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'KGMusic 诊断日志',
          text: '日志可能包含用于故障排查的网络与设备信息，请仅发送给可信对象。',
          files: [XFile(file.path, mimeType: 'text/plain')],
        ),
      );
    }),
  );

  Future<bool> saveAs() => _runLogged(
    '保存诊断日志失败',
    () => _withExport((file) async {
      final location = await getSaveLocation(
        suggestedName: file.uri.pathSegments.last,
        acceptedTypeGroups: const [
          XTypeGroup(label: '文本日志', extensions: ['txt']),
        ],
      );
      if (location == null) return false;
      await file.copy(location.path);
      return true;
    }),
  );

  Future<T> _withExport<T>(Future<T> Function(File file) action) async {
    final file = await _buildExport();
    try {
      return await action(file);
    } finally {
      await _deleteTemporary(file);
    }
  }

  Future<T> _runLogged<T>(String message, Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      AppLog.warn(
        message,
        target: 'logging.export',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String _format(List<AppLogEntry> entries) {
    final buffer = StringBuffer()
      ..writeln('KGMusic diagnostics')
      ..writeln('Exported: ${DateTime.now().toIso8601String()}')
      ..writeln(
        'Warning: trace logs may contain tokens, cookies and HTTP payloads.',
      )
      ..writeln();
    for (final entry in entries) {
      buffer
        ..write(entry.timestamp.toIso8601String())
        ..write(' [${entry.level.name.toUpperCase()}]')
        ..write(' [${entry.source}/${entry.target}] ')
        ..writeln(entry.message);
      if (entry.error case final value?) buffer.writeln('  error: $value');
      if (entry.stackTrace case final value?) buffer.writeln(value);
    }
    return buffer.toString();
  }

  Future<void> _deleteTemporary(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // The OS share target may retain the file briefly. Temporary storage will
      // clean it later if immediate deletion is not possible.
    }
  }
}
