import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/player/playback_queue_controller.dart';

void main() {
  test('queue mutations preserve the current song identity', () {
    final controller = PlaybackQueueController();
    controller.commit(const [songA, songB, songC], 1, replacingQueue: true);

    expect(controller.removeAt(0), isTrue);
    expect(controller.currentIndex, 0);
    expect(controller.songs[controller.currentIndex], songB);

    expect(controller.move(0, 2), isTrue);
    expect(controller.songs[controller.currentIndex], songB);
    expect(controller.songs, const [songC, songB]);

    expect(controller.clearUpcoming(), isFalse);
  });

  test('shuffle visits every non-current song once before exhaustion', () {
    final controller = PlaybackQueueController(random: Random(7));
    controller.commit(const [songA, songB, songC], 0, replacingQueue: true);
    controller.setOrder(PlaybackOrder.shuffle);

    final selected = <int>{
      controller.takeRandomIndex()!,
      controller.takeRandomIndex()!,
    };
    expect(selected, {1, 2});
    expect(controller.takeRandomIndex(), isNull);

    controller.append(const [songD]);
    expect(controller.takeRandomIndex(), 3);
  });

  test('restore applies persisted index and playback order', () {
    final controller = PlaybackQueueController();
    controller.restore(const [songA, songB], 1, PlaybackOrder.repeatAll);

    expect(controller.currentIndex, 1);
    expect(controller.order, PlaybackOrder.repeatAll);
    expect(controller.songs, const [songA, songB]);
  });
}

const songA = Song(
  id: 'a',
  title: 'A',
  hashes: AudioHashes(standard: 'a'),
);
const songB = Song(
  id: 'b',
  title: 'B',
  hashes: AudioHashes(standard: 'b'),
);
const songC = Song(
  id: 'c',
  title: 'C',
  hashes: AudioHashes(standard: 'c'),
);
const songD = Song(
  id: 'd',
  title: 'D',
  hashes: AudioHashes(standard: 'd'),
);
