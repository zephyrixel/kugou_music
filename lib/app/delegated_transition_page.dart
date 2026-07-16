import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';

/// A custom transition page that can also animate the route below it.
class DelegatedCustomTransitionPage<T> extends CustomTransitionPage<T> {
  const DelegatedCustomTransitionPage({
    required super.child,
    required super.transitionsBuilder,
    required this.delegatedTransitionsBuilder,
    super.transitionDuration,
    super.reverseTransitionDuration,
    super.maintainState,
    super.fullscreenDialog,
    super.opaque,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final DelegatedTransitionBuilder delegatedTransitionsBuilder;

  @override
  Route<T> createRoute(BuildContext context) =>
      _DelegatedCustomTransitionPageRoute<T>(this);
}

class PlayerTransitionPage<T> extends DelegatedCustomTransitionPage<T> {
  const PlayerTransitionPage({required super.child, super.key})
    : super(
        transitionDuration: KgMotion.slow,
        reverseTransitionDuration: KgMotion.medium,
        transitionsBuilder: _buildPlayerTransition,
        delegatedTransitionsBuilder: _buildPlayerDelegatedTransition,
      );
}

Widget _buildPlayerTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (MediaQuery.disableAnimationsOf(context)) return child;
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  final transitionChild = _SnapshotDuringTransition(
    animation: animation,
    child: child,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.018),
        end: Offset.zero,
      ).animate(curved),
      child: transitionChild,
    ),
  );
}

Widget? _buildPlayerDelegatedTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  bool allowSnapshotting,
  Widget? child,
) {
  if (child == null) return null;
  if (MediaQuery.disableAnimationsOf(context)) return child;
  final transitionChild = _SnapshotDuringTransition(
    animation: secondaryAnimation,
    child: child,
  );
  final opacity = Tween(begin: 1.0, end: 0.0).animate(
    CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0, 0.86, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.14, 1, curve: Curves.easeInCubic),
    ),
  );
  return FadeTransition(opacity: opacity, child: transitionChild);
}

/// Freezes expensive route layers only while the short page transition runs.
///
/// This follows Flutter's Android zoom transition strategy: blur and complex
/// descendants are rasterized once in memory, animated as a texture, then
/// replaced by the live widget tree when the transition completes.
class _SnapshotDuringTransition extends StatefulWidget {
  const _SnapshotDuringTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  State<_SnapshotDuringTransition> createState() =>
      _SnapshotDuringTransitionState();
}

class _SnapshotDuringTransitionState extends State<_SnapshotDuringTransition> {
  late final SnapshotController _controller = SnapshotController(
    allowSnapshotting: _shouldSnapshot,
  );

  bool get _shouldSnapshot =>
      !kIsWeb &&
      (widget.animation.status == AnimationStatus.forward ||
          widget.animation.status == AnimationStatus.reverse);

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_handleStatus);
  }

  @override
  void didUpdateWidget(covariant _SnapshotDuringTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_handleStatus);
      widget.animation.addStatusListener(_handleStatus);
      _controller.allowSnapshotting = _shouldSnapshot;
    }
  }

  void _handleStatus(AnimationStatus status) {
    _controller.allowSnapshotting = _shouldSnapshot;
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SnapshotWidget(
    controller: _controller,
    mode: SnapshotMode.permissive,
    autoresize: true,
    child: widget.child,
  );
}

class _DelegatedCustomTransitionPageRoute<T> extends PageRoute<T> {
  _DelegatedCustomTransitionPageRoute(this.page) : super(settings: page);

  final DelegatedCustomTransitionPage<T> page;

  @override
  bool get barrierDismissible => page.barrierDismissible;

  @override
  Color? get barrierColor => page.barrierColor;

  @override
  String? get barrierLabel => page.barrierLabel;

  @override
  Duration get transitionDuration => page.transitionDuration;

  @override
  Duration get reverseTransitionDuration => page.reverseTransitionDuration;

  @override
  bool get maintainState => page.maintainState;

  @override
  bool get fullscreenDialog => page.fullscreenDialog;

  @override
  bool get opaque => page.opaque;

  @override
  DelegatedTransitionBuilder get delegatedTransition =>
      page.delegatedTransitionsBuilder;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      Semantics(scopesRoute: true, explicitChildNodes: true, child: page.child);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => page.transitionsBuilder(context, animation, secondaryAnimation, child);
}
