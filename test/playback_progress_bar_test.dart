import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/features/player/playback_progress_bar.dart';

void main() {
  testWidgets('dragging the progress bar seeks only once on release', (
    tester,
  ) async {
    var seekCount = 0;
    Duration? soughtPosition;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackProgressBar(
            durationStream: Stream.value(const Duration(seconds: 10)),
            positionStream: Stream.value(const Duration(seconds: 2)),
            onSeek: (position) async {
              seekCount += 1;
              soughtPosition = position;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChangeStart!(2000);
    slider.onChanged!(3000);
    slider.onChanged!(5000);
    slider.onChanged!(7500);

    expect(seekCount, 0);
    slider.onChangeEnd!(7500);
    await tester.pump();

    expect(seekCount, 1);
    expect(soughtPosition, const Duration(milliseconds: 7500));
  });

  testWidgets('uses the current playback snapshot on the first frame', (
    tester,
  ) async {
    final durationController = StreamController<Duration?>();
    final positionController = StreamController<Duration>();
    final bufferedController = StreamController<Duration>();
    addTearDown(() async {
      await durationController.close();
      await positionController.close();
      await bufferedController.close();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaybackProgressBar(
            durationStream: durationController.stream,
            positionStream: positionController.stream,
            bufferedPositionStream: bufferedController.stream,
            initialDuration: const Duration(seconds: 100),
            initialPosition: const Duration(seconds: 25),
            initialBufferedPosition: const Duration(seconds: 40),
            onSeek: (_) async {},
          ),
        ),
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.max, 100000);
    expect(slider.value, 25000);
    expect(slider.onChanged, isNotNull);

    expect(slider.secondaryTrackValue, 40000);
    expect(find.text('0:25'), findsOneWidget);
    expect(find.text('1:40'), findsOneWidget);
  });
}
