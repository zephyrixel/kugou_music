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
    final fadeDuration = KgMotion.resolve(context, KgMotion.navigation);
    final slideDuration = KgMotion.resolve(context, KgMotion.navigation);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var index = 0; index < children.length; index++)
          _AnimatedBranch(
            key: ValueKey(index),
            active: index == currentIndex,
            offset: index < currentIndex
                ? Offset(-16 / MediaQuery.sizeOf(context).width, 0)
                : Offset(16 / MediaQuery.sizeOf(context).width, 0),
            fadeDuration: fadeDuration,
            slideDuration: slideDuration,
            child: children[index],
          ),
      ],
    );
  }
}

class _AnimatedBranch extends StatefulWidget {
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
  State<_AnimatedBranch> createState() => _AnimatedBranchState();
}

class _AnimatedBranchState extends State<_AnimatedBranch> {
  late final FocusScopeNode _focusScopeNode = FocusScopeNode(
    debugLabel: 'navigation-branch',
  );

  @override
  void didUpdateWidget(covariant _AnimatedBranch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active && !widget.active && _focusScopeNode.hasFocus) {
      _focusScopeNode.unfocus(disposition: UnfocusDisposition.scope);
    }
  }

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusScope(
    node: _focusScopeNode,
    canRequestFocus: widget.active,
    skipTraversal: !widget.active,
    descendantsAreFocusable: widget.active,
    descendantsAreTraversable: widget.active,
    child: IgnorePointer(
      ignoring: !widget.active,
      child: ExcludeSemantics(
        excluding: !widget.active,
        child: AnimatedOpacity(
          opacity: widget.active ? 1 : 0,
          duration: widget.fadeDuration,
          curve: KgMotion.standard,
          child: AnimatedSlide(
            offset: widget.active ? Offset.zero : widget.offset,
            duration: widget.slideDuration,
            curve: KgMotion.standard,
            child: HeroMode(
              enabled: widget.active,
              child: TickerMode(
                enabled: widget.active,
                child: RepaintBoundary(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
