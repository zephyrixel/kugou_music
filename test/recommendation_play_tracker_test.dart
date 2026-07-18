import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/recommendation/recommendation_play_tracker.dart';

void main() {
  test('只累计实际播放的墙钟时长，暂停和 seek 不增加时长', () async {
    var elapsed = Duration.zero;
    final observations = <_Observation>[];
    final tracker = RecommendationPlayTracker((
      song, {
      required listened,
      required sourceBits,
    }) async {
      observations.add(_Observation(song, listened, sourceBits));
    }, elapsedNow: () => elapsed);

    tracker.activate(longSong, sourceBits: 1);
    tracker.update(playing: true);
    elapsed += const Duration(seconds: 50);
    tracker.update(playing: false);
    elapsed += const Duration(minutes: 10);
    tracker.update(
      playing: false,
    ); // seek/pause events do not add elapsed time.
    tracker.update(playing: true);
    elapsed += const Duration(seconds: 71);
    await tracker.finish();

    expect(observations.single.listened, const Duration(seconds: 121));
    expect(observations.single.sourceBits, 1);
  });

  test('音质切换保留会话并合并来源位', () async {
    var elapsed = Duration.zero;
    final observations = <_Observation>[];
    final tracker = RecommendationPlayTracker((
      song, {
      required listened,
      required sourceBits,
    }) async {
      observations.add(_Observation(song, listened, sourceBits));
    }, elapsedNow: () => elapsed);

    tracker.activate(longSong, sourceBits: 1);
    tracker.update(playing: true);
    elapsed += const Duration(seconds: 30);
    tracker.update(playing: false);
    tracker.activate(longSong, sourceBits: 128, newPlayback: false);
    tracker.update(playing: true);
    elapsed += const Duration(seconds: 20);
    await tracker.finish();

    expect(observations.single.listened, const Duration(seconds: 50));
    expect(observations.single.sourceBits, 129);
  });

  test('结束后的重复 finish 不会重复落库', () async {
    var elapsed = Duration.zero;
    final observations = <_Observation>[];
    final tracker = RecommendationPlayTracker((
      song, {
      required listened,
      required sourceBits,
    }) async {
      observations.add(_Observation(song, listened, sourceBits));
    }, elapsedNow: () => elapsed);

    tracker.activate(longSong, sourceBits: 8);
    tracker.update(playing: true);
    elapsed += const Duration(seconds: 5);
    await tracker.finish();
    await tracker.finish();

    expect(observations, hasLength(1));
  });
}

class _Observation {
  const _Observation(this.song, this.listened, this.sourceBits);

  final Song song;
  final Duration listened;
  final int sourceBits;
}

const longSong = Song(
  id: 'long',
  title: 'Long',
  hashes: AudioHashes(standard: 'long-hash'),
);
