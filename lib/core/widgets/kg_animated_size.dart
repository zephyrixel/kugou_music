import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';

/// Bypass AnimatedSize entirely when motion is disabled. A zero-duration
/// controller can dirty itself while measuring a newly sized child.
class KgAnimatedSize extends StatelessWidget {
  const KgAnimatedSize({
    super.key,
    required this.child,
    this.duration = KgMotion.medium,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) || duration == Duration.zero
      ? child
      : AnimatedSize(
          duration: duration,
          curve: KgMotion.standard,
          alignment: alignment,
          child: child,
        );
}
