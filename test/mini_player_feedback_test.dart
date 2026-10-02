import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/features/player/mini_player.dart';
import 'package:kgmusic/features/player/player_screen.dart';

import 'support/ui_app_harness.dart';

void main() {
  testWidgets(
    'body ink spans the complete dock while transport ink stays local',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final ink = _RecordingInk();
      final harness = await UiAppHarness.create();
      addTearDown(harness.dispose);
      await tester.pumpWidget(
        harness.app(theme: buildKgTheme().copyWith(splashFactory: ink)),
      );
      await tester.pumpAndSettle();
      final dock = tester.getRect(find.byType(MiniPlayer));
      final press = await tester.startGesture(
        Offset(dock.left + 80, dock.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 180));
      expect(ink.bounds.last, rectMoreOrLessEquals(dock));
      await press.cancel();
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsNothing);

      await tester.tap(find.byTooltip('播放'));
      await tester.pumpAndSettle();
      expect(ink.bounds.last.width, lessThanOrEqualTo(48));
      expect(harness.handler.playCalls, 1);
      expect(find.byType(PlayerScreen), findsNothing);
      await tester.tap(find.byTooltip('播放队列'));
      await tester.pumpAndSettle();
      expect(find.text('播放队列'), findsOneWidget);
      expect(find.byType(PlayerScreen), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tapAt(Offset(dock.left + 80, dock.center.dy));
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsOneWidget);
    },
  );

  testWidgets('a loading transport button never falls through to opening', (
    tester,
  ) async {
    final harness = await UiAppHarness.create();
    addTearDown(harness.dispose);
    harness.handler.playbackState.add(
      PlaybackState(processingState: AudioProcessingState.loading),
    );
    await tester.pumpWidget(harness.app());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byTooltip('正在加载'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PlayerScreen), findsNothing);
    expect(harness.handler.playCalls, 0);
    harness.handler.playbackState.add(
      PlaybackState(processingState: AudioProcessingState.ready),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('播放'));
    await tester.pumpAndSettle();
    expect(harness.handler.playCalls, 1);
  });
}

/// Records the bounds of the actual ink feature, then paints the normal ripple.
class _RecordingInk extends InteractiveInkFeatureFactory {
  final bounds = <Rect>[];

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    final rect = rectCallback?.call() ?? Offset.zero & referenceBox.size;
    bounds.add(rect.shift(referenceBox.localToGlobal(Offset.zero)));
    return InkRipple.splashFactory.create(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}
