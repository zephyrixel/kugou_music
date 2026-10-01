import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

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
  bool _disposed = false;
  int _pendingWrites = 0;
  int _dropped = 0;
  Object? _sinkError;

  File get _current => File('${directory.path}/${_flutterFiles.first}');

  Future<void> initialize() {
    if (_disposed) return Future.error(_disposedError());
    return _enqueue(_ensureOpen);
  }

  Future<void> append(AppLogEntry entry) {
    if (_disposed) return Future.error(_disposedError());
    if (_pendingWrites >= 256) {
      _dropped++;
      return Future<void>.value();
    }
    _pendingWrites++;
    return _enqueue(() async {
      await _ensureOpen();
      final dropped = _dropped;
      _dropped = 0;
      if (dropped > 0) {
        final summary = AppLogEntry(
          timestamp: entry.timestamp,
          level: entry.level,
          source: 'flutter',
          target: 'logging',
          message: '日志写入繁忙，已丢弃 $dropped 条记录',
        );
        await _appendLine(summary.toJsonLine());
      }
      await _appendLine(entry.toJsonLine());
    }).whenComplete(() => _pendingWrites--);
  }

  Future<void> _appendLine(String line) async {
    final bytes = utf8.encode('$line\n');
    await _rotateIfNeeded(bytes.length);
    _sink!.add(bytes);
    _currentBytes += bytes.length;
  }

  Future<void> flush() => _enqueue(() async => _sink?.flush());

  Future<void> dispose() {
    if (_disposed) return _tail;
    _disposed = true;
    return _enqueue(_closeSink);
  }

  Future<List<AppLogEntry>> readEntries({int? limit}) async {
    await flush();
    final path = directory.path;
    return Isolate.run(() => _readRecent(path, limit));
  }

  /// Merge the two chronological sources with only one entry buffered per
  /// source. Export does not materialize or sort the full log history.
  Stream<AppLogEntry> chronologicalEntries() async* {
    await flush();
    final flutter = StreamIterator(
      _readFiles(directory.path, _flutterFiles.reversed),
    );
    final native = StreamIterator(
      _readFiles(directory.path, _nativeFiles.reversed),
    );
    try {
      var hasFlutter = await flutter.moveNext();
      var hasNative = await native.moveNext();
      while (hasFlutter || hasNative) {
        if (hasFlutter &&
            (!hasNative ||
                !flutter.current.timestamp.isAfter(native.current.timestamp))) {
          yield flutter.current;
          hasFlutter = await flutter.moveNext();
        } else {
          yield native.current;
          hasNative = await native.moveNext();
        }
      }
    } finally {
      await flutter.cancel();
      await native.cancel();
    }
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
    if (_disposed) throw _disposedError();
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
    if (_sinkError != null) throw _sinkError!;
    if (_sink != null) return;
    await directory.create(recursive: true);
    _currentBytes = await _current.exists() ? await _current.length() : 0;
    final sink = _current.openWrite(mode: FileMode.append);
    _sink = sink;
    unawaited(
      sink.done.catchError((Object error) {
        _sinkError = error;
      }),
    );
  }

  Future<void> _closeSink() async {
    final sink = _sink;
    _sink = null;
    if (sink == null) return;
    try {
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    late final Future<T> next;
    next = _tail.catchError((_) {}).then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (_) {});
    return next;
  }

  StateError _disposedError() => StateError('AppLogStore is disposed');
}

Stream<AppLogEntry> _readFiles(String path, Iterable<String> names) async* {
  for (final name in names) {
    final file = File('$path/$name');
    try {
      if (!await file.exists()) continue;
      await for (final line
          in file
              .openRead()
              .transform(const Utf8Decoder(allowMalformed: true))
              .transform(const LineSplitter())) {
        final entry = AppLogEntry.tryParse(line);
        if (entry != null) yield entry;
      }
    } on FileSystemException {
      /* Rotation may replace a file during a read. */
    }
  }
}

Future<List<AppLogEntry>> _readRecent(String path, int? limit) async {
  if (limit != null && limit <= 0) return const [];
  var sequence = 0;
  final entries = SplayTreeSet<({int sequence, AppLogEntry entry})>((a, b) {
    final byTime = a.entry.timestamp.compareTo(b.entry.timestamp);
    return byTime == 0 ? a.sequence.compareTo(b.sequence) : byTime;
  });
  await for (final entry in _readFiles(path, [
    ...AppLogStore._flutterFiles,
    ...AppLogStore._nativeFiles,
  ])) {
    entries.add((sequence: sequence++, entry: entry));
    if (limit != null && entries.length > limit) entries.remove(entries.first);
  }
  return entries
      .toList()
      .reversed
      .map((value) => value.entry)
      .toList(growable: false);
}
