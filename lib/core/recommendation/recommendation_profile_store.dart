import 'package:drift/drift.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/models/song.dart';

abstract final class RecommendationProfilePolicy {
  static const completePlayback = Duration(seconds: 120);
  // Lite reads this from config; the native default is 400. The app keeps the
  // documented default because the bridge does not expose that remote config.
  static const historyLimit = 400;
  static const dailySyncLimit = 5;
}

class RecommendationProfileSnapshot {
  const RecommendationProfileSnapshot({
    required this.ready,
    required this.items,
  });

  const RecommendationProfileSnapshot.notReady()
    : ready = false,
      items = const [];

  final bool ready;
  final List<RecommendationProfileItem> items;
}

class RecommendationSyncPolicyState {
  const RecommendationSyncPolicyState({
    required this.dayKey,
    required this.syncCount,
    this.nextAllowedAt,
  });

  final String dayKey;
  final int syncCount;
  final DateTime? nextAllowedAt;
}

class RecommendationProfileStore {
  const RecommendationProfileStore(this._database);

  final AppDatabase _database;

  Future<void> recordPlayback({
    required int userId,
    required Song song,
    required Duration listened,
    required int sourceBits,
    required DateTime occurredAt,
  }) {
    if (listened <= Duration.zero) return Future.value();
    final action = listened > RecommendationProfilePolicy.completePlayback
        ? RecommendationProfileAction.playComplete
        : RecommendationProfileAction.playShort;
    return _record(
      userId: userId,
      song: song,
      action: action,
      sourceBits: sourceBits,
      occurredAt: occurredAt,
    );
  }

  Future<void> recordTrash({
    required int userId,
    required Song song,
    required DateTime occurredAt,
  }) => _record(
    userId: userId,
    song: song,
    action: RecommendationProfileAction.trash,
    sourceBits: 0,
    occurredAt: occurredAt,
  );

  Future<void> _record({
    required int userId,
    required Song song,
    required RecommendationProfileAction action,
    required int sourceBits,
    required DateTime occurredAt,
  }) async {
    final hash = _normalizedHash(song.hashes.standard);
    final mixSongId = song.mixSongId;
    final songKey = hash == null
        ? mixSongId == null
              ? null
              : 'mix:$mixSongId'
        : 'hash:$hash';
    if (songKey == null) return;

    await _database.transaction(() async {
      final existing =
          await (_database.select(_database.storedRecommendationProfiles)
                ..where(
                  (row) =>
                      row.userId.equals(userId) &
                      row.songKey.equals(songKey) &
                      row.action.equals(action.wireValue),
                ))
              .getSingleOrNull();
      await _database
          .into(_database.storedRecommendationProfiles)
          .insertOnConflictUpdate(
            StoredRecommendationProfilesCompanion.insert(
              userId: userId,
              songKey: songKey,
              action: action.wireValue,
              standardHash: Value(hash ?? existing?.standardHash),
              mixSongId: Value(mixSongId ?? existing?.mixSongId),
              eventTimeMs: occurredAt.millisecondsSinceEpoch,
              count: Value((existing?.count ?? 0) + 1),
              sourceBits: Value((existing?.sourceBits ?? 0) | sourceBits),
            ),
          );
    });
  }

  Future<RecommendationProfileSnapshot> snapshot(int userId) async {
    // Playlist rows are a local read model without a user column. Only use the
    // favorite row when the library baseline proves it belongs to this
    // account; this prevents an account switch from leaking the previous
    // account's collection into the next FM profile.
    final syncState = await (_database.select(
      _database.librarySyncStates,
    )..where((row) => row.singletonId.equals(1))).getSingleOrNull();
    final favorite =
        syncState?.userId == userId && syncState?.baselineComplete == true
        ? await (_database.select(
            _database.storedPlaylists,
          )..where((row) => row.isMyFavorite.equals(true))).getSingleOrNull()
        : null;
    if (favorite != null && !favorite.tracksLoaded) {
      return const RecommendationProfileSnapshot.notReady();
    }

    final items = <RecommendationProfileItem>[];
    if (favorite != null) {
      final query =
          _database.select(_database.storedPlaylistTracks).join([
            innerJoin(
              _database.storedSongs,
              _database.storedSongs.id.equalsExp(
                _database.storedPlaylistTracks.songId,
              ),
            ),
          ])..where(
            _database.storedPlaylistTracks.playlistLocalId.equals(
              favorite.localId,
            ),
          );
      final fallbackTime =
          (favorite.fullSnapshotUpdatedAt ??
                  favorite.tracksUpdatedAt ??
                  DateTime.now())
              .millisecondsSinceEpoch;
      for (final row in await query.get()) {
        final song = row.readTable(_database.storedSongs);
        final track = row.readTable(_database.storedPlaylistTracks);
        final item = RecommendationProfileItem(
          action: RecommendationProfileAction.collect,
          standardHash: _normalizedHash(song.hashStandard),
          mixSongId: song.mixSongId,
          eventTimeMs: track.collectTimeSecs == null
              ? fallbackTime
              : track.collectTimeSecs! * 1000,
          count: 1,
          flagBits: RecommendationProfileItem.myFavoriteFlag,
          sourceBits: 0,
        );
        if (item.hasIdentity) items.add(item);
      }
    }

    final localRows = await (_database.select(
      _database.storedRecommendationProfiles,
    )..where((row) => row.userId.equals(userId))).get();
    for (final row in localRows) {
      final action = RecommendationProfileAction.values
          .where((value) => value.wireValue == row.action)
          .firstOrNull;
      if (action == null) continue;
      final item = RecommendationProfileItem(
        action: action,
        standardHash: row.standardHash,
        mixSongId: row.mixSongId,
        eventTimeMs: row.eventTimeMs,
        count: row.count,
        sourceBits: row.sourceBits,
      );
      if (item.hasIdentity) items.add(item);
    }
    return RecommendationProfileSnapshot(
      ready: true,
      items: List.unmodifiable(items),
    );
  }

  Future<RecommendationSyncPolicyState> syncPolicy(
    int userId,
    String dayKey,
  ) async {
    final row = await (_database.select(
      _database.recommendationSyncStates,
    )..where((item) => item.userId.equals(userId))).getSingleOrNull();
    if (row == null || row.dayKey != dayKey) {
      return RecommendationSyncPolicyState(dayKey: dayKey, syncCount: 0);
    }
    return RecommendationSyncPolicyState(
      dayKey: row.dayKey,
      syncCount: row.successCount,
      nextAllowedAt: row.nextAllowedAt,
    );
  }

  Future<void> saveSyncPolicy(
    int userId,
    RecommendationSyncPolicyState state,
  ) => _database
      .into(_database.recommendationSyncStates)
      .insertOnConflictUpdate(
        RecommendationSyncStatesCompanion.insert(
          userId: Value(userId),
          dayKey: state.dayKey,
          successCount: Value(state.syncCount),
          nextAllowedAt: Value(state.nextAllowedAt),
        ),
      );

  Future<void> clearProfile(int userId) => (_database.delete(
    _database.storedRecommendationProfiles,
  )..where((row) => row.userId.equals(userId))).go();
}

String? _normalizedHash(String? value) {
  final normalized = value?.trim().toLowerCase();
  return normalized?.isNotEmpty == true ? normalized : null;
}
