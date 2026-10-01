import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/song_codec.dart';
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

/// Durable, account-scoped playback state. Cache maintenance never deletes it.
class PlaybackQueueStore {
  const PlaybackQueueStore(this._database);

  static const _codecVersion = 2;

  final AppDatabase _database;

  Future<PlaybackQueueSnapshot?> read(int userId) async {
    final table = _database.storedPlaybackQueues;
    final row = await (_database.select(
      table,
    )..where((row) => row.userId.equals(userId))).getSingleOrNull();
    if (row == null) return null;
    try {
      if (row.codecVersion != 1 && row.codecVersion != _codecVersion) {
        throw const FormatException('Unsupported queue version');
      }
      final map = jsonDecode(row.payload);
      if (map is! Map) throw const FormatException('Invalid queue');
      final songs = (map['songs'] as List? ?? const [])
          .whereType<Map>()
          .map(SongCodec.decode)
          .toList(growable: false);
      if (songs.isEmpty) throw const FormatException('Empty queue');
      final originMap = map['origin'] as Map?;
      final origin = PlaybackQueueOrigin(
        kind: _originKind(originMap?['kind']),
        title: originMap?['title'] as String? ?? '播放队列',
        id: originMap?['id'] as String?,
        totalCount: _asInt(originMap?['totalCount']),
        sourceBits: _asInt(originMap?['sourceBits']),
      );
      final request = PlaybackQueueRequest(
        origin: origin,
        songs: List.unmodifiable(songs),
        nextPage: (_asInt(map['nextPage']) ?? 1).clamp(1, 1 << 31),
        hasMore: map['hasMore'] == true,
        pageSize: (_asInt(map['pageSize']) ?? 50).clamp(1, 100),
      );
      return PlaybackQueueSnapshot(
        request: request,
        currentIndex: (_asInt(map['currentIndex']) ?? 0).clamp(
          0,
          songs.length - 1,
        ),
        order: _order(map['order']),
        positionMs: (_asInt(map['positionMs']) ?? 0).clamp(0, 1 << 53),
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
        'kind': request.origin.kind.name,
        'title': request.origin.title,
        'id': request.origin.id,
        'totalCount': request.origin.totalCount,
        'sourceBits': request.origin.sourceBits,
      },
      'songs': request.songs.map(SongCodec.encode).toList(growable: false),
      'currentIndex': snapshot.currentIndex,
      'order': snapshot.order.name,
      'positionMs': snapshot.positionMs,
      'nextPage': request.nextPage,
      'hasMore': request.hasMore,
      'pageSize': request.pageSize,
    });
    return _database
        .into(_database.storedPlaybackQueues)
        .insertOnConflictUpdate(
          StoredPlaybackQueuesCompanion.insert(
            userId: Value(userId),
            codecVersion: _codecVersion,
            payload: payload,
            updatedAt: _database.now(),
          ),
        )
        .then((_) {});
  }

  Future<void> clear(int userId) => (_database.delete(
    _database.storedPlaybackQueues,
  )..where((row) => row.userId.equals(userId))).go();

  Future<void> clearAll() =>
      _database.delete(_database.storedPlaybackQueues).go();
}

int? _asInt(Object? value) => value is num ? value.toInt() : null;

// Frozen v1 wire order: never decode historical data with Enum.values indexes.
const _legacyOrigins = [
  'snapshot',
  'dailyRecommendations',
  'search',
  'libraryPlaylist',
  'publicPlaylist',
  'favorites',
  'history',
  'personalFm',
  'heartRadio',
  'discovery',
];
const _legacyOrders = ['sequential', 'repeatAll', 'repeatOne', 'shuffle'];

String? _name(Object? value, List<String> legacy) {
  if (value is String) return value;
  if (value is int && value >= 0 && value < legacy.length) return legacy[value];
  return null;
}

PlaybackQueueOriginKind _originKind(Object? value) =>
    PlaybackQueueOriginKind.values.firstWhere(
      (kind) => kind.name == _name(value, _legacyOrigins),
      orElse: () => PlaybackQueueOriginKind.snapshot,
    );

PlaybackOrder _order(Object? value) => PlaybackOrder.values.firstWhere(
  (order) => order.name == _name(value, _legacyOrders),
  orElse: () => PlaybackOrder.sequential,
);
