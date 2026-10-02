import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/features/player/player_visual_pager.dart';

import 'support/player_ui_harness.dart';

void main() {
  testWidgets('cover shadow paints past the pager and leaves with the cover', (
    tester,
  ) async {
    final disabled = debugDisableShadows;
    debugDisableShadows = false;
    try {
      final handler = PlayerUiHandler();
      addTearDown(handler.close);
      final canvas = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildKgTheme(),
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: canvas,
                child: ColoredBox(
                  color: const Color(0xFF808080),
                  child: SizedBox(
                    width: 350,
                    height: 420,
                    child: PlayerVisualPager(
                      handler: handler,
                      item: handler.mediaItem.value!,
                      song: null,
                      compact: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          canvas.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final pageBottom = boundary
          .globalToLocal(tester.getBottomLeft(find.byType(PageView)))
          .dy
          .floor();
      Future<List<int>> sample() async => (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final width = image.width;
        final values = [
          for (final y in [pageBottom - 2, pageBottom + 2])
            pixels.getUint8((y * width + width ~/ 2) * 4),
        ];
        image.dispose();
        return values;
      }))!;

      final cover = await sample();
      // Both sides of the viewport edge receive the same soft shadow. This checks
      // a small painted region, without locking its radius, color or page pixels.
      expect(cover[0], lessThan(128));
      expect(cover[1], lessThan(128));
      expect((cover[0] - cover[1]).abs(), lessThan(128 - cover[0]));
      await tester.tap(find.text('歌词'));
      await tester.pumpAndSettle();
      expect(await sample(), [128, 128]);
      await tester.tap(find.text('封面'));
      await tester.pumpAndSettle();
      expect((await sample())[1], lessThan(128));
      expect(tester.takeException(), isNull);
    } finally {
      debugDisableShadows = disabled;
    }
  });
}
