import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/recommendation/recommendation_queue_source.dart';
import 'package:kgmusic/core/recommendation/recommendation_reporter.dart';

class RecommendationPlayback {
  const RecommendationPlayback(this._sdk, this._reporter);

  final MusicSdk _sdk;
  final RecommendationReporter _reporter;

  Future<PlaybackQueueRequest> start(RecommendationKind kind) async {
    final source = createSource(kind);
    final batch = await source.start();
    if (batch.songs.isEmpty) {
      throw StateError('${kind.title}暂时没有可播放的歌曲');
    }
    return PlaybackQueueRequest(
      origin: PlaybackQueueOrigin(kind: _originKind(kind), title: kind.title),
      songs: batch.songs,
      source: source,
      nextPage: 2,
      hasMore: true,
      pageSize: batch.songs.length,
    );
  }

  RecommendationQueueSource createSource(RecommendationKind kind) =>
      RecommendationQueueSource(_sdk, _reporter, kind: kind);

  static RecommendationKind? kindForOrigin(PlaybackQueueOriginKind kind) =>
      switch (kind) {
        PlaybackQueueOriginKind.personalFm => RecommendationKind.personalFm,
        PlaybackQueueOriginKind.heartRadio => RecommendationKind.heartRadio,
        _ => null,
      };

  static PlaybackQueueOriginKind _originKind(RecommendationKind kind) =>
      switch (kind) {
        RecommendationKind.personalFm => PlaybackQueueOriginKind.personalFm,
        RecommendationKind.heartRadio => PlaybackQueueOriginKind.heartRadio,
      };
}
