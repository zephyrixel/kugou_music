import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';

Future<T?> showKgModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: isScrollControlled,
  sheetAnimationStyle: AnimationStyle(
    duration: KgMotion.resolve(context, KgMotion.sheetEnter),
    reverseDuration: KgMotion.resolve(context, KgMotion.sheetExit),
    curve: KgMotion.emphasized,
    reverseCurve: KgMotion.standard,
  ),
  builder: builder,
);

/// Retains DialogRoute's safe area, focus traversal and barrier semantics.
Future<T?> showKgDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(
    _KgDialogRoute<T>(
      context: context,
      builder: builder,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      duration: KgMotion.resolve(context, KgMotion.dialogEnter),
      reverseDuration: KgMotion.resolve(context, KgMotion.dialogExit),
    ),
  );
}

class _KgDialogRoute<T> extends DialogRoute<T> {
  _KgDialogRoute({
    required super.context,
    required super.builder,
    required super.themes,
    required Duration duration,
    required this.reverseDuration,
  }) : super(
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
         animationStyle: AnimationStyle(duration: duration),
       );

  final Duration reverseDuration;

  @override
  Duration get reverseTransitionDuration => reverseDuration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final progress = animation.drive(CurveTween(curve: KgMotion.standard));
    return FadeTransition(
      opacity: progress,
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(progress),
        child: child,
      ),
    );
  }
}
