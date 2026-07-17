import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kgmusic/core/logging/app_log_entry.dart';

class AppLogStore {
  AppLogStore(this.directory);

  static const _maxFileBytes = 2 * 1024 * 1024;
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
  IOSink? _sink;
  int _currentBytes = 0;

  File get _current => File('${directory.path}/${_flutterFiles.first}');

  Future<void> initialize() => _enqueue(_ensureOpen);

  Future<void> append(AppLogEntry entry) {
    final line = '${entry.toJsonLine()}\n';
    final incomingBytes = utf8.encode(line).length;
    return _enqueue(() async {
      await _ensureOpen();
      await _rotateIfNeeded(incomingBytes);
      _sink!.add(utf8.encode(line));
      _currentBytes += incomingBytes;
    });
  }

  Future<void> flush() => _enqueue(() async => _sink?.flush());

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
    await _enqueue(() async {
      await _closeSink();
      for (final name in _flutterFiles) {
        final file = File('${directory.path}/$name');
        try {
          if (await file.exists()) await file.delete();
        } on FileSystemException {
          // Best effort; callers can refresh the status after clearing.
        }
      }
      _currentBytes = 0;
    });
  }

  Future<void> _rotateIfNeeded(int incomingBytes) async {
    if (_currentBytes + incomingBytes <= _maxFileBytes) return;
    await _closeSink();
    final first = File('${directory.path}/${_flutterFiles[1]}');
    final second = File('${directory.path}/${_flutterFiles[2]}');
    if (await second.exists()) await second.delete();
    if (await first.exists()) await first.rename(second.path);
    if (await _current.exists()) await _current.rename(first.path);
    await _ensureOpen();
  }

  Future<void> _ensureOpen() async {
    if (_sink != null) return;
    await directory.create(recursive: true);
    _currentBytes = await _current.exists() ? await _current.length() : 0;
    _sink = _current.openWrite(mode: FileMode.append);
  }

  Future<void> _closeSink() async {
    final sink = _sink;
    _sink = null;
    if (sink == null) return;
    await sink.flush();
    await sink.close();
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    late final Future<T> next;
    next = _tail.catchError((_) {}).then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (_) {});
    return next;
  }
}
