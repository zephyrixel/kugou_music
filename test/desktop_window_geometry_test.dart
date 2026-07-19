import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/platform/desktop_window_geometry.dart';

void main() {
  const primary = Rect.fromLTWH(0, 0, 1920, 1040);
  const secondary = Rect.fromLTWH(-1280, 0, 1280, 984);

  test('accepts a window whose title bar is reachable', () {
    expect(
      isRestorableWindowBounds(
        const Rect.fromLTWH(-1200, 100, 900, 700),
        const [primary, secondary],
      ),
      isTrue,
    );
  });

  test('rejects a stale position outside all current displays', () {
    expect(
      isRestorableWindowBounds(const Rect.fromLTWH(4000, 200, 900, 700), const [
        primary,
        secondary,
      ]),
      isFalse,
    );
  });

  test('rejects a window with too little title bar visible to recover', () {
    expect(
      isRestorableWindowBounds(
        const Rect.fromLTWH(1850, 1020, 900, 700),
        const [primary],
      ),
      isFalse,
    );
  });
}
