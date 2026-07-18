import 'dart:async';
import 'dart:math';

import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/recommendation/recommendation_profile_store.dart';
import 'package:kgmusic/core/widgets/app_error_bus.dart';

class RecommendationReporter {
  RecommendationReporter(
    this._sdk,
    this._store,
    this._errors, {
    DateTime Function()? now,
    int Function()? jitterSeconds,
  }) : _now = now ?? DateTime.now,
       _jitterSeconds = jitterSeconds ?? (() => Random().nextInt(61));

  final RecommendationSdk _sdk;
  final RecommendationProfileStore _store;
  final AppErrorBus _errors;
  final DateTime Function() _now;
  final int Function() _jitterSeconds;

  Future<void> _feedbackTail = Future<void>.value();
  Future<void>? _syncInFlight;
  int? _userId;
  int _sessionGeneration = 0;
  bool _profileSyncPending = false;
  bool _profileReadySignalPending = false;
  int _profileTriggerVersion = 0;

  void activate(int userId) {
    if (_userId == userId) return;
    _sessionGeneration += 1;
    _userId = userId;
    _profileSyncPending = false;
    _profileReadySignalPending = false;
  }

  Future<void> deactivate({bool clearProfile = true}) async {
    final userId = _userId;
    _sessionGeneration += 1;
    _userId = null;
    _profileSyncPending = false;
    _profileReadySignalPending = false;
    if (clearProfile && userId != null) await _store.clearProfile(userId);
  }

  Future<void> recordPlayback(
    Song song, {
    required Duration listened,
    required int sourceBits,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    await _store.recordPlayback(
      userId: userId,
      song: song,
      listened: listened,
      sourceBits: sourceBits,
      occurredAt: _now(),
    );
  }

  Future<void> recordTrash(Song song) async {
    final userId = _userId;
    if (userId == null) return;
    await _store.recordTrash(userId: userId, song: song, occurredAt: _now());
  }

  void reportFavoriteChanged(Song song, {required bool liked}) {
    if (!liked) return;
    _enqueueFeedback(
      '收藏操作',
      () => _sdk.reportRecommendationFavoriteClick(song),
    );
  }

  void reportRepeated(List<String> hashes, {required int remainSongCount}) {
    if (hashes.isEmpty) return;
    _enqueueFeedback(
      '重复歌曲',
      () => _sdk.reportRecommendationRepeated(
        hashes,
        remainSongCount: remainSongCount,
      ),
    );
  }

  void onPersonalFmSuccess({required int? syncNeed, required int? syncPoint}) {
    if (syncNeed != 1 || syncPoint != 0 || _userId == null) return;
    _profileTriggerVersion += 1;
    _profileSyncPending = true;
    _startProfileSync();
  }

  void notifyProfileReady() {
    if (!_profileSyncPending) return;
    if (_syncInFlight != null) {
      _profileReadySignalPending = true;
      return;
    }
    _startProfileSync();
  }

  Future<void> flush() async {
    // A completion callback may schedule the next profile packet in a
    // microtask (for example when the favorite snapshot became ready while a
    // report was in flight). Drain until both tails remain stable.
    while (true) {
      final feedback = _feedbackTail;
      await feedback;
      final sync = _syncInFlight;
      if (sync != null) {
        await sync;
        continue;
      }
      await Future<void>.delayed(Duration.zero);
      if (identical(_feedbackTail, feedback) &&
          _syncInFlight == null &&
          !_profileReadySignalPending) {
        return;
      }
    }
  }

  void reportError(String label, Object error) {
    AppLog.warn('推荐$label失败', target: 'recommendation.report', error: error);
    _errors.add('推荐反馈暂未同步，不影响继续播放');
  }

  void _startProfileSync() {
    if (_syncInFlight != null) return;
    final generation = _sessionGeneration;
    final triggerVersion = _profileTriggerVersion;
    late final Future<void> tracked;
    tracked = _syncProfile(generation)
        .catchError((Object error) {
          if (generation == _sessionGeneration) {
            reportError('画像同步', error);
          }
        })
        .whenComplete(() {
          if (!identical(_syncInFlight, tracked)) return;
          _syncInFlight = null;
          // If the account changed while the old request was in flight, the
          // new account may already have queued a profile sync. The old
          // request cannot be cancelled, so hand the slot to the new session
          // as soon as it releases.
          final retry =
              _profileSyncPending &&
              (_profileReadySignalPending ||
                  generation != _sessionGeneration ||
                  triggerVersion != _profileTriggerVersion);
          _profileReadySignalPending = false;
          if (retry) scheduleMicrotask(_startProfileSync);
        });
    _syncInFlight = tracked;
  }

  Future<void> _syncProfile(int generation) async {
    final userId = _userId;
    if (userId == null || generation != _sessionGeneration) return;
    final snapshot = await _store.snapshot(userId);
    if (generation != _sessionGeneration || _userId != userId) return;
    if (!snapshot.ready) return;
    _profileSyncPending = false;
    if (snapshot.items.isEmpty) return;

    final now = _now();
    final dayKey = _dayKey(now);
    final policy = await _store.syncPolicy(userId, dayKey);
    if (generation != _sessionGeneration || _userId != userId) return;
    if (policy.syncCount >= RecommendationProfilePolicy.dailySyncLimit) {
      return;
    }
    final nextAllowedAt = policy.nextAllowedAt;
    if (nextAllowedAt != null && now.isBefore(nextAllowedAt)) return;

    final items = [...snapshot.items]
      ..sort((left, right) {
        final byTime = right.eventTimeMs.compareTo(left.eventTimeMs);
        if (byTime != 0) return byTime;
        final byAction = left.action.wireValue.compareTo(
          right.action.wireValue,
        );
        if (byAction != 0) return byAction;
        return (left.standardHash ?? '').compareTo(right.standardHash ?? '');
      });

    final syncCount = policy.syncCount + 1;
    final jitter = _jitterSeconds().clamp(0, 60);
    await _store.saveSyncPolicy(
      userId,
      RecommendationSyncPolicyState(
        dayKey: dayKey,
        syncCount: syncCount,
        nextAllowedAt: now.add(
          Duration(minutes: policy.syncCount * 5, seconds: jitter),
        ),
      ),
    );
    if (generation != _sessionGeneration || _userId != userId) return;

    var previousSyncPoint = 0;
    String? lastUploadHash;
    for (
      var offset = 0;
      offset < items.length;
      offset += RecommendationProfilePolicy.historyLimit
    ) {
      final end = min(
        offset + RecommendationProfilePolicy.historyLimit,
        items.length,
      );
      final slice = items.sublist(offset, end);
      final wireItems = slice.reversed.toList(growable: false);
      final nextSyncPoint = slice.last.eventTimeMs;
      await _sdk.reportRecommendationHistory(
        wireItems,
        complete: end == items.length,
        previousSyncPoint: previousSyncPoint,
        nextSyncPoint: nextSyncPoint,
        lastUploadHash: lastUploadHash,
      );
      if (generation != _sessionGeneration || _userId != userId) return;
      previousSyncPoint = nextSyncPoint;
      final hash = wireItems.first.standardHash?.trim();
      lastUploadHash = hash?.isNotEmpty == true ? hash : null;
    }
    AppLog.debug(
      '推荐画像同步完成 rows=${items.length} count=$syncCount',
      target: 'recommendation.report',
    );
  }

  void _enqueueFeedback(String label, Future<void> Function() action) {
    final generation = _sessionGeneration;
    _feedbackTail = _feedbackTail.catchError((_) {}).then((_) async {
      if (generation != _sessionGeneration || _userId == null) return;
      try {
        await action();
        AppLog.debug('推荐$label上报成功', target: 'recommendation.report');
      } catch (error) {
        reportError('$label上报', error);
      }
    });
  }
}

String _dayKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
