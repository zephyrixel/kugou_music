import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';

/// Keeps branch navigators alive while animating bottom-navigation switches.
class AnimatedBranchContainer extends StatelessWidget {
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final fadeDuration = KgMotion.resolve(context, KgMotion.fast);
    final slideDuration = KgMotion.resolve(context, KgMotion.medium);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var index = 0; index < children.length; index++)
          _AnimatedBranch(
            key: ValueKey(index),
            active: index == currentIndex,
            offset: index < currentIndex
                ? const Offset(-0.025, 0)
                : const Offset(0.025, 0),
            fadeDuration: fadeDuration,
            slideDuration: slideDuration,
            child: children[index],
          ),
      ],
    );
  }
}

class _AnimatedBranch extends StatelessWidget {
  const _AnimatedBranch({
    super.key,
    required this.active,
    required this.offset,
    required this.fadeDuration,
    required this.slideDuration,
    required this.child,
  });

  final bool active;
  final Offset offset;
  final Duration fadeDuration;
  final Duration slideDuration;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !active,
    child: ExcludeSemantics(
      excluding: !active,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration: fadeDuration,
        curve: KgMotion.standard,
        child: AnimatedSlide(
          offset: active ? Offset.zero : offset,
          duration: slideDuration,
          curve: KgMotion.standard,
          child: TickerMode(
            enabled: active,
            child: RepaintBoundary(child: child),
          ),
        ),
      ),
    ),
  );
}
