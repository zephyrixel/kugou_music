import 'dart:async';

import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/widgets/app_error_bus.dart';

class RecommendationReporter {
  RecommendationReporter(this._sdk, this._errors);

  final RecommendationSdk _sdk;
  final AppErrorBus _errors;
  Future<void> _tail = Future<void>.value();
  final List<RecommendationHistoryEvent> _history = [];
  Timer? _historyTimer;
  int? _historySyncPoint;
  int _sessionGeneration = 0;

  Future<void> flush() async {
    await _flushHistory();
    await _tail;
  }

  void resetSession() {
    _sessionGeneration += 1;
    _historyTimer?.cancel();
    _historyTimer = null;
    _history.clear();
    _historySyncPoint = null;
  }

  void reportPlayed(Song song) => _queueHistory(
    RecommendationHistoryEvent(
      action: RecommendationHistoryAction.play,
      song: song,
    ),
  );

  void reportFavoriteChanged(Song song, {required bool liked}) {
    if (liked) {
      _queueHistory(
        RecommendationHistoryEvent(
          action: RecommendationHistoryAction.collect,
          song: song,
        ),
      );
    }
    if (liked) {
      _enqueue(
        '收藏操作',
        () => _sdk.reportRecommendationFavoriteClick(song),
        generation: _sessionGeneration,
      );
    }
  }

  void reportTrash(Song song) => _queueHistory(
    RecommendationHistoryEvent(
      action: RecommendationHistoryAction.trash,
      song: song,
    ),
  );

  void reportRepeated(List<String> hashes, {required int remainSongCount}) {
    if (hashes.isEmpty) return;
    _enqueue(
      '重复歌曲',
      () => _sdk.reportRecommendationRepeated(
        hashes,
        remainSongCount: remainSongCount,
      ),
      generation: _sessionGeneration,
    );
  }

  void reportError(String label, Object error) {
    AppLog.warn('推荐$label上报失败', target: 'recommendation.report', error: error);
    _errors.add('推荐$label上报失败：$error');
  }

  void _queueHistory(RecommendationHistoryEvent event) {
    _history.add(event);
    if (_history.length >= 20) {
      unawaited(_flushHistory());
      return;
    }
    _historyTimer ??= Timer(const Duration(milliseconds: 500), () {
      _historyTimer = null;
      unawaited(_flushHistory());
    });
  }

  Future<void> _flushHistory() async {
    _historyTimer?.cancel();
    _historyTimer = null;
    if (_history.isEmpty) return;
    final batch = List<RecommendationHistoryEvent>.of(_history);
    _history.clear();
    final generation = _sessionGeneration;
    _enqueue('历史记录', () async {
      final ack = await _sdk.reportRecommendationHistory(
        batch,
        previousSyncPoint: _historySyncPoint,
      );
      if (generation == _sessionGeneration && ack.syncPoint != null) {
        _historySyncPoint = ack.syncPoint;
      }
    }, generation: generation);
    await _tail;
  }

  void _enqueue(
    String label,
    Future<void> Function() action, {
    required int generation,
  }) {
    _tail = _tail.catchError((_) {}).then((_) async {
      if (generation != _sessionGeneration) return;
      try {
        await action();
        AppLog.debug('推荐$label上报成功', target: 'recommendation.report');
      } catch (error) {
        reportError(label, error);
      }
    });
  }
}
