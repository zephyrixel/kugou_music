import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/recommendation/recommendation_play_tracker.dart';

void main() {
  test('长歌曲播放满30秒后只上报一次', () async {
    final reported = <Song>[];
    final tracker = RecommendationPlayTracker((song) async {
      reported.add(song);
    });

    tracker.activate(longSong, duration: const Duration(minutes: 4));
    tracker.update(position: const Duration(seconds: 29), playing: true);
    tracker.update(position: const Duration(seconds: 30), playing: true);
    tracker.update(position: const Duration(minutes: 1), playing: true);

    expect(reported, [longSong]);
  });

  test('短歌曲播放到一半后上报，暂停状态不触发', () async {
    final reported = <Song>[];
    final tracker = RecommendationPlayTracker((song) async {
      reported.add(song);
    });

    tracker.activate(shortSong, duration: const Duration(seconds: 20));
    tracker.update(position: const Duration(seconds: 12), playing: false);
    expect(reported, isEmpty);

    tracker.update(position: const Duration(seconds: 10), playing: true);
    expect(reported, [shortSong]);
  });

  test('音质切换保留状态，新一轮播放会重新计数', () async {
    final reported = <Song>[];
    final tracker = RecommendationPlayTracker((song) async {
      reported.add(song);
    });

    tracker.activate(longSong, duration: const Duration(minutes: 4));
    tracker.update(position: const Duration(seconds: 20), playing: true);
    tracker.activate(
      longSong,
      duration: const Duration(minutes: 4),
      newPlayback: false,
    );
    tracker.update(position: const Duration(seconds: 30), playing: true);
    tracker.activate(longSong, duration: const Duration(minutes: 4));
    tracker.update(position: const Duration(seconds: 30), playing: true);

    expect(reported, [longSong, longSong]);
  });
}

const longSong = Song(
  id: 'long',
  title: 'Long',
  hashes: AudioHashes(standard: 'long-hash'),
);

const shortSong = Song(
  id: 'short',
  title: 'Short',
  hashes: AudioHashes(standard: 'short-hash'),
);
