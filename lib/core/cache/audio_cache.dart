// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CachedAudioHandle {
  const CachedAudioHandle({required this.source, required this.file});

  final LockCachingAudioSource source;
  final File file;
}

class AudioCacheUsage {
  const AudioCacheUsage({required this.totalBytes, required this.maxBytes});

  final int totalBytes;
  final int maxBytes;
}

abstract interface class AudioCache {
  Future<CachedAudioHandle> sourceFor(Song song, PlayableResolution resolution);
  void setActive(CachedAudioHandle? handle);
}

class AudioCacheManager implements AudioCache {
  AudioCacheManager._(this._directory, this._maxBytes);

  static const defaultMaxBytes = 1024 * 1024 * 1024;

  final Directory _directory;
  int _maxBytes;
  String? _activePath;
  final Set<String> _downloadingPaths = {};
  final Set<String> _pendingClearPaths = {};
  bool _prunePending = false;
  bool _pruneRequested = false;
  Future<void>? _pruneOperation;

  int get maxBytes => _maxBytes;

  static Future<AudioCacheManager> create({
    Directory? directory,
    int maxBytes = defaultMaxBytes,
  }) async {
    final root =
        directory ??
        Directory(
          p.join((await _temporaryDirectory()).path, 'kgmusic_audio_v1'),
        );
    await root.create(recursive: true);
    final manager = AudioCacheManager._(root, maxBytes);
    await manager._removeStalePartials();
    await manager.prune();
    return manager;
  }

  @override
  Future<CachedAudioHandle> sourceFor(
    Song song,
    PlayableResolution resolution,
  ) async {
    final key = _resourceKey(song, resolution);
    final extension = _extension(resolution.url, resolution.quality);
    final file = File(p.join(_directory.path, '$key$extension'));
    final exists = await file.exists();
    if (exists) await file.setLastModified(DateTime.now());
    AppLog.debug(
      '音频缓存 ${exists ? '命中' : '未命中'} song=${song.id} '
      'quality=${resolution.quality.name}',
      target: 'player.cache',
    );

    final source = LockCachingAudioSource(
      Uri.parse(resolution.url),
      cacheFile: file,
    );
    if (!exists) {
      _downloadingPaths.add(file.path);
      unawaited(_watchCompletion(source, file.path));
    }
    return CachedAudioHandle(source: source, file: file);
  }

  @override
  void setActive(CachedAudioHandle? handle) {
    final previousPath = _activePath;
    _activePath = handle?.file.path;
    final clearPrevious =
        previousPath != null &&
        previousPath != _activePath &&
        _pendingClearPaths.remove(previousPath) &&
        !_downloadingPaths.contains(previousPath);
    if (clearPrevious) {
      unawaited(_deletePendingFile(previousPath));
    } else if (_prunePending && previousPath != _activePath) {
      unawaited(prune());
    }
  }

  Future<void> setMaxBytes(int maxBytes) async {
    if (maxBytes <= 0) {
      throw ArgumentError.value(maxBytes, 'maxBytes', 'must be positive');
    }
    _maxBytes = maxBytes;
    await prune();
  }

  Future<AudioCacheUsage> usage() async {
    if (!await _directory.exists()) {
      return AudioCacheUsage(totalBytes: 0, maxBytes: _maxBytes);
    }
    var totalBytes = 0;
    await for (final entity in _directory.list()) {
      if (entity is! File) continue;
      try {
        totalBytes += await entity.length();
      } on FileSystemException {
        // A concurrent cleanup may remove a file between listing and stat.
      }
    }
    return AudioCacheUsage(totalBytes: totalBytes, maxBytes: _maxBytes);
  }

  Future<void> prune() {
    _pruneRequested = true;
    final activeOperation = _pruneOperation;
    if (activeOperation != null) return activeOperation;

    late final Future<void> operation;
    operation = _drainPruneRequests().whenComplete(() {
      if (identical(_pruneOperation, operation)) _pruneOperation = null;
    });
    _pruneOperation = operation;
    return operation;
  }

  Future<void> _drainPruneRequests() async {
    while (_pruneRequested) {
      _pruneRequested = false;
      await _pruneOnce();
    }
  }

  Future<void> _pruneOnce() async {
    if (!await _directory.exists()) {
      _prunePending = false;
      return;
    }
    final files = await _audioFiles();
    var total = files.fold<int>(0, (sum, file) => sum + file.lengthSync());
    if (total <= _maxBytes) {
      _prunePending = false;
      return;
    }

    files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    for (final file in files) {
      if (total <= _maxBytes) break;
      if (_isProtected(file.path)) continue;
      final length = file.lengthSync();
      await _deleteWithSidecars(file);
      total -= length;
    }
    _prunePending = total > _maxBytes;
  }

  Future<void> clear() async {
    if (!await _directory.exists()) return;
    _pendingClearPaths.addAll(_downloadingPaths);
    if (_activePath != null) _pendingClearPaths.add(_activePath!);
    for (final file in await _directory.list().where(_isFile).toList()) {
      if (_isProtected(file.path)) continue;
      await _deleteWithSidecars(File(file.path));
    }
  }

  Future<List<File>> _audioFiles() async =>
      (await _directory.list().where(_isFile).toList())
          .map((entity) => File(entity.path))
          .where((file) => !_isSidecar(file.path))
          .where((file) => !file.path.endsWith('.part'))
          .toList(growable: false);

  Future<void> _watchCompletion(
    LockCachingAudioSource source,
    String path,
  ) async {
    try {
      await source.downloadProgressStream.firstWhere((value) => value >= 1);
    } catch (_) {
      // The next source request can restart an interrupted download.
    } finally {
      _downloadingPaths.remove(path);
      if (_pendingClearPaths.contains(path) && path != _activePath) {
        _pendingClearPaths.remove(path);
        await _deleteWithSidecars(File(path));
        if (_prunePending) await prune();
      } else {
        await prune();
      }
    }
  }

  Future<void> _removeStalePartials() async {
    if (!await _directory.exists()) return;
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    await for (final entity in _directory.list()) {
      if (entity is! File || !entity.path.endsWith('.part')) continue;
      if ((await entity.lastModified()).isBefore(cutoff)) {
        await _deleteFile(entity);
      }
    }
  }

  Future<void> _deleteWithSidecars(File file) async {
    await _deleteFile(file);
    for (final suffix in const ['.mime', '.part']) {
      await _deleteFile(File('${file.path}$suffix'));
    }
  }

  Future<void> _deletePendingFile(String path) async {
    await _deleteWithSidecars(File(path));
    if (_prunePending) await prune();
  }

  Future<void> _deleteFile(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Cache cleanup is best effort.
    }
  }

  bool _isProtected(String path) {
    final protectedPaths = <String>{?_activePath, ..._downloadingPaths};
    return protectedPaths.any(
      (base) => path == base || path == '$base.mime' || path == '$base.part',
    );
  }

  bool _isFile(FileSystemEntity entity) => entity is File;

  bool _isSidecar(String path) =>
      path.endsWith('.mime') || path.endsWith('.part');

  String _resourceKey(Song song, PlayableResolution resolution) {
    final hash = resolution.quality.hashFor(song)?.trim().toLowerCase();
    final uri = Uri.tryParse(resolution.url);
    final fallback = uri == null ? resolution.url : '${uri.host}${uri.path}';
    final source = hash?.isNotEmpty == true ? hash : '${song.id}|$fallback';
    final preview = resolution is PreviewResolution
        ? 'preview:${resolution.endMs ?? 0}'
        : 'full';
    return sha256
        .convert(
          utf8.encode('${song.id}|${resolution.quality.name}|$source|$preview'),
        )
        .toString();
  }

  String _extension(String url, AudioQuality quality) {
    final path = Uri.tryParse(url)?.path ?? '';
    final extension = p.extension(path).toLowerCase();
    if (const {
      '.mp3',
      '.flac',
      '.m4a',
      '.aac',
      '.ogg',
      '.wav',
    }.contains(extension)) {
      return extension;
    }
    return switch (quality) {
      AudioQuality.flac ||
      AudioQuality.hiRes ||
      AudioQuality.superQuality => '.flac',
      _ => '.mp3',
    };
  }
}

Future<Directory> _temporaryDirectory() async {
  return getTemporaryDirectory();
}
