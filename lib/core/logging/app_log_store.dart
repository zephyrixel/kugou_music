import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kgmusic/core/logging/app_log_entry.dart';

class AppLogStore {
  AppLogStore(this.directory);

  static const maxFileBytes = 2 * 1024 * 1024;
  static const _flutterFiles = [
    'flutter-current.jsonl',
    'flutter-1.jsonl',
    'flutter-2.jsonl',
  ];
  static const _nativeFiles = [
    'native-current.jsonl',
    'native-1.jsonl',
    'native-2.jsonl',
  ];

  final Directory directory;
  Future<void> _tail = Future<void>.value();

  File get _current => File('${directory.path}/${_flutterFiles.first}');

  Future<void> initialize() => directory.create(recursive: true);

  Future<void> append(AppLogEntry entry) {
    final line = '${entry.toJsonLine()}\n';
    final incomingBytes = utf8.encode(line).length;
    final next = _tail.catchError((_) {}).then((_) async {
      await initialize();
      await _rotateIfNeeded(incomingBytes);
      await _current.writeAsString(line, mode: FileMode.append, flush: false);
    });
    _tail = next;
    return next;
  }

  Future<void> flush() => _tail.catchError((_) {});

  Future<List<AppLogEntry>> readEntries({int? limit}) async {
    await flush();
    final entries = <AppLogEntry>[];
    for (final name in [..._flutterFiles, ..._nativeFiles]) {
      final file = File('${directory.path}/$name');
      if (!await file.exists()) continue;
      try {
        await for (final line
            in file
                .openRead()
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          final entry = AppLogEntry.tryParse(line);
          if (entry != null) entries.add(entry);
        }
      } on FileSystemException {
        // A native write or rotation may race with reading. The next refresh
        // will retry without making diagnostics affect the application.
      }
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (limit != null && entries.length > limit) {
      return entries.sublist(0, limit);
    }
    return entries;
  }

  Future<int> totalBytes() async {
    await flush();
    var total = 0;
    for (final name in [..._flutterFiles, ..._nativeFiles]) {
      final file = File('${directory.path}/$name');
      if (await file.exists()) total += await file.length();
    }
    return total;
  }

  Future<void> clearFlutterLogs() async {
    await flush();
    for (final name in _flutterFiles) {
      final file = File('${directory.path}/$name');
      try {
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // Best effort; callers can refresh the status after clearing.
      }
    }
  }

  Future<void> _rotateIfNeeded(int incomingBytes) async {
    final currentBytes = await _current.exists() ? await _current.length() : 0;
    if (currentBytes + incomingBytes <= maxFileBytes) return;
    final first = File('${directory.path}/${_flutterFiles[1]}');
    final second = File('${directory.path}/${_flutterFiles[2]}');
    if (await second.exists()) await second.delete();
    if (await first.exists()) await first.rename(second.path);
    if (await _current.exists()) await _current.rename(first.path);
  }
}
