import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/widgets/app_error_bus.dart';

class RecommendationReporter {
  RecommendationReporter(this._sdk, this._errors);

  final MusicSdk _sdk;
  final AppErrorBus _errors;
  Future<void> _tail = Future<void>.value();

  Future<void> flush() => _tail;

  void reportPlayed(Song song) => _enqueue(
    '播放记录',
    () => _sdk.reportRecommendationHistory([
      RecommendationHistoryEvent(
        action: RecommendationHistoryAction.play,
        song: song,
      ),
    ]),
  );

  void reportFavoriteChanged(Song song, {required bool liked}) {
    if (liked) {
      _enqueue(
        '收藏记录',
        () => _sdk.reportRecommendationHistory([
          RecommendationHistoryEvent(
            action: RecommendationHistoryAction.collect,
            song: song,
          ),
        ]),
      );
    }
    _enqueue('收藏操作', () => _sdk.reportRecommendationFavoriteClick(song));
  }

  void reportTrash(Song song) => _enqueue(
    '不感兴趣',
    () => _sdk.reportRecommendationHistory([
      RecommendationHistoryEvent(
        action: RecommendationHistoryAction.trash,
        song: song,
      ),
    ]),
  );

  void reportRepeated(List<String> hashes, {required int remainSongCount}) {
    if (hashes.isEmpty) return;
    _enqueue(
      '重复歌曲',
      () => _sdk.reportRecommendationRepeated(
        hashes,
        remainSongCount: remainSongCount,
      ),
    );
  }

  void reportError(String label, Object error) {
    _errors.add('推荐$label上报失败：$error');
  }

  void _enqueue(String label, Future<void> Function() action) {
    _tail = _tail.catchError((_) {}).then((_) async {
      try {
        await action();
      } catch (error) {
        reportError(label, error);
      }
    });
  }
}
