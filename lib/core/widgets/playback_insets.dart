import 'package:flutter/widgets.dart';

/// Space obscured by the floating player, excluding the system safe area and
/// navigation bar (which their respective layouts already consume).
class PlaybackInsets extends InheritedWidget {
  const PlaybackInsets({
    super.key,
    required this.bottom,
    this.keyboardVisible = false,
    required super.child,
  });

  final double bottom;
  final bool keyboardVisible;

  static double bottomOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlaybackInsets>()?.bottom ?? 0;

  /// The playback shell has already consumed the keyboard's layout inset.
  static bool keyboardVisibleOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<PlaybackInsets>()
          ?.keyboardVisible ??
      MediaQuery.viewInsetsOf(context).bottom > 0;

  /// Use at the end of scrollable content, never around the entire viewport.
  static double scrollPadding(BuildContext context, {double extra = 24}) =>
      bottomOf(context) + MediaQuery.paddingOf(context).bottom + extra;

  @override
  bool updateShouldNotify(PlaybackInsets oldWidget) =>
      bottom != oldWidget.bottom ||
      keyboardVisible != oldWidget.keyboardVisible;
}
