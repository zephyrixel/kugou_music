import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/lyric.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/lyrics_sdk.dart';

class LyricsRepository {
  LyricsRepository(this._remote, this._database, {DateTime Function()? now})
    : _now = now ?? _database.now;

  static const _codecVersion = 1;
  static const _notFoundTtl = Duration(hours: 24);

  final LyricsSdk _remote;
  final AppDatabase _database;
  final DateTime Function() _now;
  final Map<String, Future<LyricDocument?>> _inFlight = {};

  Future<LyricDocument?> load(Song song, {bool forceRefresh = false}) async {
    final key = _cacheKey(song);
    if (forceRefresh) {
      try {
        await _database.deleteCachedResponse(key);
      } catch (_) {
        // Cache maintenance must not block an explicit network refresh.
      }
    } else {
      final cached = await _readCache(key);
      if (cached.hit) return cached.document;
    }
    return _coalesced(key, () async {
      final document = await _remote.fetchLyrics(song);
      try {
        await _database.writeCachedResponse(
          cacheKey: key,
          accountUserId: null,
          codecVersion: _codecVersion,
          updatedAt: _now(),
          payload: jsonEncode(
            document == null
                ? const <String, Object?>{'found': false}
                : <String, Object?>{
                    'found': true,
                    'document': _documentToJson(document),
                  },
          ),
        );
      } catch (_) {
        // A valid remote lyric remains usable when persistence fails.
      }
      return document;
    });
  }

  Future<_CachedLyric> _readCache(String key) async {
    CachedResponse? row;
    try {
      row = await _database.readCachedResponse(key);
    } catch (_) {
      return const _CachedLyric.miss();
    }
    if (row == null) return const _CachedLyric.miss();
    if (row.codecVersion != _codecVersion) {
      await _database.deleteCachedResponse(key);
      return const _CachedLyric.miss();
    }
    try {
      final value = _map(jsonDecode(row.payload));
      final found = value['found'] == true;
      if (!found) {
        if (_now().difference(row.updatedAt) <= _notFoundTtl) {
          return const _CachedLyric.hit(null);
        }
        await _database.deleteCachedResponse(key);
        return const _CachedLyric.miss();
      }
      return _CachedLyric.hit(_documentFromJson(_map(value['document'])));
    } catch (_) {
      await _database.deleteCachedResponse(key);
      return const _CachedLyric.miss();
    }
  }

  Future<LyricDocument?> _coalesced(
    String key,
    Future<LyricDocument?> Function() load,
  ) {
    final existing = _inFlight[key];
    if (existing != null) return existing;
    late final Future<LyricDocument?> tracked;
    tracked = Future<LyricDocument?>.sync(load).whenComplete(() {
      if (identical(_inFlight[key], tracked)) _inFlight.remove(key);
    });
    _inFlight[key] = tracked;
    return tracked;
  }

  String _cacheKey(Song song) {
    final identity = song.mixSongId != null
        ? 'mix:${song.mixSongId}'
        : song.hashes.standard?.trim().isNotEmpty == true
        ? 'hash:${song.hashes.standard!.trim().toLowerCase()}'
        : song.id;
    final digest = sha256.convert(utf8.encode(identity));
    return 'v1/lyrics/$digest';
  }
}

class _CachedLyric {
  const _CachedLyric.hit(this.document) : hit = true;
  const _CachedLyric.miss() : hit = false, document = null;

  final bool hit;
  final LyricDocument? document;
}

Map<String, Object?> _documentToJson(LyricDocument document) => {
  'format': document.format.name,
  'offsetMs': document.offsetMs,
  'lines': document.lines
      .map(
        (line) => {
          'startMs': line.startMs,
          'durationMs': line.durationMs,
          'text': line.text,
          'translation': line.translation,
          'transliteration': line.transliteration,
          'words': line.words
              .map(
                (word) => {
                  'startMs': word.startMs,
                  'durationMs': word.durationMs,
                  'text': word.text,
                },
              )
              .toList(growable: false),
        },
      )
      .toList(growable: false),
};

LyricDocument _documentFromJson(Map<String, Object?> value) => LyricDocument(
  format: LyricFormat.values.firstWhere(
    (item) => item.name == value['format'],
    orElse: () => LyricFormat.plain,
  ),
  offsetMs: _int(value['offsetMs']),
  lines: _list(value['lines'])
      .map((item) {
        final line = _map(item);
        return LyricLine(
          startMs: _int(line['startMs']),
          durationMs: _int(line['durationMs']),
          text: line['text']?.toString() ?? '',
          translation: line['translation'] as String?,
          transliteration: line['transliteration'] as String?,
          words: _list(line['words'])
              .map((item) {
                final word = _map(item);
                return LyricWord(
                  startMs: _int(word['startMs']),
                  durationMs: _int(word['durationMs']),
                  text: word['text']?.toString() ?? '',
                );
              })
              .toList(growable: false),
        );
      })
      .toList(growable: false),
);

Map<String, Object?> _map(Object? value) {
  if (value is! Map) throw const FormatException('歌词缓存对象格式无效');
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<Object?> _list(Object? value) {
  if (value is! List) throw const FormatException('歌词缓存列表格式无效');
  return value.cast<Object?>();
}

int _int(Object? value) {
  if (value is num) return value.toInt();
  throw const FormatException('歌词缓存数字格式无效');
}
