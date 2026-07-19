import 'dart:ui';

const _minimumVisibleTitleBarWidth = 120.0;
const _minimumVisibleTitleBarHeight = 24.0;
const _titleBarHeight = 48.0;

bool isRestorableWindowBounds(Rect windowBounds, Iterable<Rect> workAreas) {
  if (!windowBounds.isFinite || windowBounds.isEmpty) return false;
  final titleBar = Rect.fromLTWH(
    windowBounds.left,
    windowBounds.top,
    windowBounds.width,
    windowBounds.height.clamp(0, _titleBarHeight),
  );
  for (final workArea in workAreas) {
    if (!workArea.isFinite || workArea.isEmpty) continue;
    final overlap = titleBar.intersect(workArea);
    if (overlap.width >= _minimumVisibleTitleBarWidth &&
        overlap.height >= _minimumVisibleTitleBarHeight) {
      return true;
    }
  }
  return false;
}
