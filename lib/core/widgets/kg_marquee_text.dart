import 'dart:async';

import 'package:flutter/material.dart';

/// A single-line label that loops only when its content overflows.
class KgMarqueeText extends StatefulWidget {
  const KgMarqueeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.velocity = 28,
    this.gap = 32,
    this.startDelay = const Duration(milliseconds: 900),
  }) : assert(velocity > 0),
       assert(gap >= 0);

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final double velocity;
  final double gap;
  final Duration startDelay;

  @override
  State<KgMarqueeText> createState() => _KgMarqueeTextState();
}

class _KgMarqueeTextState extends State<KgMarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  Timer? _startTimer;
  int? _layoutSignature;
  double _distance = 0;
  bool _animate = false;

  @override
  void didUpdateWidget(covariant KgMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _stop();
      _layoutSignature = null;
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final inheritedStyle = DefaultTextStyle.of(context).style;
      final style = inheritedStyle.merge(widget.style);
      final direction = Directionality.of(context);
      final scaler = MediaQuery.textScalerOf(context);
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        maxLines: 1,
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      final availableWidth = constraints.maxWidth;
      final overflows =
          availableWidth.isFinite && painter.width > availableWidth + 0.5;
      final reduceMotion =
          MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.maybeOf(context)?.accessibleNavigation == true;
      final shouldAnimate = overflows && !reduceMotion;
      final distance = painter.width + widget.gap;
      final signature = Object.hash(
        widget.text,
        style,
        scaler,
        direction,
        availableWidth,
        shouldAnimate,
        widget.velocity,
        widget.gap,
        widget.startDelay,
      );
      if (_layoutSignature != signature) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _layoutSignature == signature) return;
          _configure(signature, distance, shouldAnimate);
        });
      }

      if (!shouldAnimate) {
        return Text(
          widget.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: widget.textAlign,
          style: style,
        );
      }

      return Semantics(
        label: widget.text,
        excludeSemantics: true,
        child: RepaintBoundary(
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.text, maxLines: 1, softWrap: false, style: style),
                  SizedBox(width: widget.gap),
                  Text(widget.text, maxLines: 1, softWrap: false, style: style),
                ],
              ),
              builder: (context, child) => OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                child: Transform.translate(
                  offset: Offset(-_controller.value * _distance, 0),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  void _configure(int signature, double distance, bool animate) {
    _stop();
    _layoutSignature = signature;
    _distance = distance;
    _animate = animate;
    if (!_animate) return;
    final milliseconds = (_distance / widget.velocity * 1000).round().clamp(
      1200,
      30000,
    );
    _controller.duration = Duration(milliseconds: milliseconds);
    _startTimer = Timer(widget.startDelay, () {
      if (mounted && _animate) _controller.repeat();
    });
  }

  void _stop() {
    _animate = false;
    _startTimer?.cancel();
    _startTimer = null;
    _controller.stop();
    _controller.reset();
  }
}
