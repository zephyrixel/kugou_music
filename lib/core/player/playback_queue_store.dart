import 'dart:convert';

import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';

class PlaybackQueueSnapshot {
  const PlaybackQueueSnapshot({
    required this.request,
    required this.currentIndex,
    required this.order,
    this.positionMs = 0,
  });

  final PlaybackQueueRequest request;
  final int currentIndex;
  final PlaybackOrder order;
  final int positionMs;
}

/// Persists only the local playback session. It is deliberately stored as one
/// cached response so queue persistence does not introduce another database
/// table or a second music-library model.
class PlaybackQueueStore {
  const PlaybackQueueStore(this._database);

  static const _keyPrefix = 'player/queue/v1/';
  static const _codecVersion = 1;

  final AppDatabase _database;

  Future<PlaybackQueueSnapshot?> read(int userId) async {
    final row = await _database.readCachedResponse('$_keyPrefix$userId');
    if (row == null || row.codecVersion != _codecVersion) return null;
    try {
      final map = jsonDecode(row.payload);
      if (map is! Map) return null;
      final songs = (map['songs'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => _songFromJson(item))
          .toList(growable: false);
      final originMap = map['origin'] as Map?;
      final origin = PlaybackQueueOrigin(
        kind:
            PlaybackQueueOriginKind.values[(_asInt(originMap?['kind']) ?? 0)
                .clamp(0, PlaybackQueueOriginKind.values.length - 1)],
        title: originMap?['title'] as String? ?? '播放队列',
        id: originMap?['id'] as String?,
        totalCount: _asInt(originMap?['totalCount']),
      );
      final request = PlaybackQueueRequest(
        origin: origin,
        songs: songs,
        nextPage: _asInt(map['nextPage']) ?? 1,
        hasMore: map['hasMore'] == true,
        pageSize: _asInt(map['pageSize']) ?? 50,
      );
      return PlaybackQueueSnapshot(
        request: request,
        currentIndex: _asInt(map['currentIndex']) ?? -1,
        order:
            PlaybackOrder.values[(_asInt(map['order']) ?? 0).clamp(
              0,
              PlaybackOrder.values.length - 1,
            )],
        positionMs: _asInt(map['positionMs']) ?? 0,
      );
    } catch (_) {
      await clear(userId);
      return null;
    }
  }

  Future<void> write(int userId, PlaybackQueueSnapshot snapshot) {
    final request = snapshot.request;
    final payload = jsonEncode({
      'origin': {
        'kind': request.origin.kind.index,
        'title': request.origin.title,
        'id': request.origin.id,
        'totalCount': request.origin.totalCount,
      },
      'songs': request.songs.map(_songToJson).toList(growable: false),
      'currentIndex': snapshot.currentIndex,
      'order': snapshot.order.index,
      'positionMs': snapshot.positionMs,
      'nextPage': request.nextPage,
      'hasMore': request.hasMore,
      'pageSize': request.pageSize,
    });
    return _database.writeCachedResponse(
      cacheKey: '$_keyPrefix$userId',
      accountUserId: userId,
      codecVersion: _codecVersion,
      payload: payload,
    );
  }

  Future<void> clear(int userId) =>
      _database.deleteCachedResponse('$_keyPrefix$userId');
}

Map<String, Object?> _songToJson(Song value) => {
  'id': value.id,
  'title': value.title,
  'artist': value.artist,
  'album': value.album,
  'durationSecs': value.durationSecs,
  'artworkUrl': value.artworkUrl,
  'privilege': value.privilege,
  'albumId': value.albumId,
  'mixSongId': value.mixSongId,
  'fileId': value.fileId,
  'hashes': {
    'standard': value.hashes.standard,
    'high': value.hashes.high,
    'flac': value.hashes.flac,
    'hiRes': value.hashes.hiRes,
    'super': value.hashes.superHash,
  },
};

Song _songFromJson(Map value) {
  final hashes = value['hashes'] as Map? ?? const {};
  return Song(
    id: value['id'] as String? ?? 'unknown',
    title: value['title'] as String? ?? '未知歌曲',
    artist: value['artist'] as String?,
    album: value['album'] as String?,
    durationSecs: _asInt(value['durationSecs']),
    artworkUrl: value['artworkUrl'] as String?,
    privilege: _asInt(value['privilege']),
    albumId: _asInt(value['albumId']),
    mixSongId: _asInt(value['mixSongId']),
    fileId: _asInt(value['fileId']),
    hashes: AudioHashes(
      standard: hashes['standard'] as String?,
      high: hashes['high'] as String?,
      flac: hashes['flac'] as String?,
      hiRes: hashes['hiRes'] as String?,
      superHash: hashes['super'] as String?,
    ),
  );
}

int? _asInt(Object? value) => value is num ? value.toInt() : null;
