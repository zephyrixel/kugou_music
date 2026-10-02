import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/artwork_backdrop.dart';

/// Moves a retained artwork layer; blur and image decoding do not run per tick.
class PlayerBackdrop extends StatefulWidget {
  const PlayerBackdrop({super.key, required this.handler, required this.item});

  final MusicAudioHandler handler;
  final MediaItem item;

  @override
  State<PlayerBackdrop> createState() => _PlayerBackdropState();
}

class _PlayerBackdropState extends State<PlayerBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: KgMotion.ambient,
  );
  StreamSubscription<PlaybackState>? _subscription;
  late final AppLifecycleListener _lifecycle;
  Animation<double>? _routeAnimation;
  bool _playing = false;
  bool _visible = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _foreground = state == AppLifecycleState.resumed;
        _syncMotion();
      },
    );
    _listen();
  }

  void _listen() {
    _subscription?.cancel();
    _playing = widget.handler.playbackState.value.playing;
    _subscription = widget.handler.playbackState.listen((state) {
      if (_playing == state.playing) return;
      _playing = state.playing;
      _syncMotion();
    });
  }

  @override
  void didUpdateWidget(PlayerBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handler != widget.handler) {
      _listen();
      _syncMotion();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeStatusListener(_routeStatusChanged);
      _routeAnimation = animation;
      _routeAnimation?.addStatusListener(_routeStatusChanged);
    }
    _visible =
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _syncMotion();
  }

  void _routeStatusChanged(AnimationStatus _) => _syncMotion();

  void _syncMotion() {
    // The route already moves the full-screen blur. Do not run a second
    // transform inside it until the route settles; keep the retained layer
    // stable through opening, dismissal and cancelled dismiss gestures.
    final routeSettled =
        _routeAnimation == null || _routeAnimation!.isCompleted;
    if (_playing && _visible && _foreground && routeSettled) {
      if (!_motion.isAnimating) _motion.repeat(reverse: true);
    } else {
      _motion.stop();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _routeAnimation?.removeStatusListener(_routeStatusChanged);
    _lifecycle.dispose();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRect(
      child: AnimatedBuilder(
        animation: _motion,
        child: ArtworkBackdrop(
          url: widget.item.artUri?.toString(),
          cacheId: 'song:${widget.item.id}',
          opacity: 0.82,
          scrim: 0.52,
          decodePixelSize: 320,
          blurSigma: 42,
        ),
        builder: (context, child) => FractionalTranslation(
          translation: Offset(
            (_motion.value - 0.5) * 0.025,
            (_motion.value - 0.5) * 0.015,
          ),
          child: Transform.scale(scale: 1.06, child: child),
        ),
      ),
    ),
  );
}
