import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';

/// Uses the control's own Material states; never adds a competing recognizer.
/// Only paint scales, so the control keeps its original touch target.
class KgPressFeedback extends StatelessWidget {
  const KgPressFeedback({
    super.key,
    required this.states,
    required this.child,
    this.pressedScale = 0.96,
  });

  final Set<WidgetState> states;
  final Widget child;
  final double pressedScale;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final pressed =
        states.contains(WidgetState.pressed) &&
        !states.contains(WidgetState.disabled);
    return AnimatedScale(
      scale: pressed ? pressedScale : 1,
      duration: pressed ? KgMotion.press : KgMotion.medium,
      curve: pressed ? KgMotion.standard : KgMotion.rebound,
      child: child,
    );
  }
}

/// Fades obsolete content out without keeping its actions or focus alive.
class KgStateTransition extends StatelessWidget {
  const KgStateTransition({
    super.key,
    required this.child,
    this.duration = KgMotion.fast,
    this.alignment = Alignment.topLeft,
    this.retainOutgoing = true,
  });

  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  /// Live scroll views must detach before the next result view mounts.
  final bool retainOutgoing;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: KgMotion.standard,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [
          for (final outgoing in retainOutgoing ? previous : const <Widget>[])
            ExcludeFocus(
              child: ExcludeSemantics(
                child: IgnorePointer(
                  child: TickerMode(enabled: false, child: outgoing),
                ),
              ),
            ),
          ?current,
        ],
      ),
      child: child,
    );
  }
}

/// A bounded, one-time entrance for the first few groups of a page.
/// Keep this mounted around loading/data so refreshes do not replay it.
class KgEntrance extends StatefulWidget {
  const KgEntrance({
    super.key,
    required this.child,
    this.order = 0,
    this.ready = true,
  }) : assert(order >= 0 && order < 4);

  final Widget child;
  final int order;
  final bool ready;

  @override
  State<KgEntrance> createState() => _KgEntranceState();
}

class _KgEntranceState extends State<KgEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _start();
  }

  @override
  void didUpdateWidget(KgEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    _start();
  }

  void _start() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _controller.value = 1;
    } else if (!_started && widget.ready) {
      _started = true;
      _controller.duration = Duration(milliseconds: 240 + widget.order * 40);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    final delay = widget.order * 40 / (240 + widget.order * 40);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final progress = Interval(
          delay,
          1,
          curve: KgMotion.standard,
        ).transform(_controller.value);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }
}
