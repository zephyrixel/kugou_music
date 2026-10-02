import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/playback_insets.dart';
import 'package:kgmusic/features/player/mini_player.dart';

/// Lives on the root shell route, outside its nested content navigator. This
/// keeps one player alive across details and puts its Hero on the same navigator
/// as the full-screen player. Root modal routes naturally cover both.
class PlaybackShell extends ConsumerStatefulWidget {
  const PlaybackShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<PlaybackShell> createState() => _PlaybackShellState();
}

class _PlaybackShellState extends ConsumerState<PlaybackShell> {
  final _playerKey = GlobalKey();
  double _playerHeight = 68;
  bool _measurementPending = false;

  bool get _hasNavigation =>
      widget.location == '/' ||
      widget.location == '/search' ||
      widget.location == '/library' ||
      widget.location.startsWith('/library/');

  void _measurePlayer() {
    if (_measurementPending) return;
    _measurementPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementPending = false;
      if (!mounted) return;
      final height = _playerKey.currentContext?.size?.height;
      if (height != null &&
          height > 0 &&
          (height - _playerHeight).abs() > 0.5) {
        setState(() => _playerHeight = height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= KgBreakpoints.navigationRail;
        final railWidth = wide && _hasNavigation
            ? KgNavigation.railWidthOf(context) + 1
            : 0.0;
        final navigationHeight = !wide && _hasNavigation
            ? KgNavigation.barHeight
            : 0.0;
        final safeArea = MediaQuery.viewPaddingOf(context);
        return StreamBuilder<MediaItem?>(
          stream: handler.mediaItem,
          initialData: handler.mediaItem.value,
          builder: (context, snapshot) {
            final visible = snapshot.data != null && !keyboard;
            // Keep feedback above the nested navigation bar even before a song
            // is selected. Zero width reserves geometry without intercepting
            // touches or exposing an empty player to accessibility services.
            final navigationSpace = !keyboard && navigationHeight > 0
                ? SizedBox(width: 0, height: navigationHeight)
                : null;
            if (visible) _measurePlayer();
            return PlaybackInsets(
              bottom: visible ? _playerHeight + 12 : 0,
              keyboardVisible: keyboard,
              child: Scaffold(
                // Resize once here so both content and Snackbar avoid the
                // keyboard. Scaffold consumes the inset for nested pages;
                // PlaybackInsets retains keyboard visibility for navigation.
                body: widget.child,
                floatingActionButtonAnimator:
                    FloatingActionButtonAnimator.noAnimation,
                floatingActionButtonLocation: _PlayerLocation(railWidth),
                floatingActionButton: !visible
                    ? navigationSpace
                    : AnimatedPadding(
                        duration: KgMotion.resolve(context, KgMotion.medium),
                        curve: KgMotion.standard,
                        padding: EdgeInsets.only(bottom: navigationHeight),
                        child: SizedBox(
                          width: math.min(
                            760,
                            math.max(
                              0,
                              constraints.maxWidth -
                                  safeArea.horizontal -
                                  railWidth -
                                  24,
                            ),
                          ),
                          child:
                              NotificationListener<
                                SizeChangedLayoutNotification
                              >(
                                onNotification: (_) {
                                  _measurePlayer();
                                  return false;
                                },
                                child: SizeChangedLayoutNotifier(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: KgMotion.resolve(
                                      context,
                                      KgMotion.medium,
                                    ),
                                    curve: KgMotion.standard,
                                    child: MiniPlayer(key: _playerKey),
                                    builder: (context, value, child) => Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 8 * (1 - value)),
                                        child: child,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PlayerLocation extends FloatingActionButtonLocation {
  const _PlayerLocation(this.railWidth);

  final double railWidth;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) => Offset(
    geometry.minViewPadding.left +
        railWidth +
        (geometry.scaffoldSize.width -
                geometry.minViewPadding.horizontal -
                railWidth -
                geometry.floatingActionButtonSize.width) /
            2,
    geometry.scaffoldSize.height -
        geometry.minViewPadding.bottom -
        geometry.floatingActionButtonSize.height -
        12,
  );
}
