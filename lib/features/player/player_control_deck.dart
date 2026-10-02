import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/kg_motion.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/add_to_playlist_button.dart';
import 'package:kgmusic/core/widgets/kg_marquee_text.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/song_favorite_button.dart';
import 'package:kgmusic/features/player/playback_progress_bar.dart';
import 'package:kgmusic/features/player/player_playback_controls.dart';
import 'package:kgmusic/features/player/player_quality_selector.dart';

class PlayerControlDeck extends StatelessWidget {
  const PlayerControlDeck({
    required this.handler,
    required this.item,
    required this.song,
    required this.compact,
    super.key,
  });

  final MusicAudioHandler handler;
  final MediaItem item;
  final Song? song;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ControlReveal(
        order: 0,
        child: KgStateTransition(
          duration: KgMotion.resolve(context, KgMotion.medium),
          child: _TrackHeading(
            key: ValueKey(item.id),
            item: item,
            song: song,
            compact: compact,
          ),
        ),
      ),
      SizedBox(height: compact ? 8 : 16),
      _ControlReveal(
        order: 1,
        child: RepaintBoundary(
          child: PlaybackProgressBar(
            durationStream: handler.durationStream,
            positionStream: handler.positionStream,
            bufferedPositionStream: handler.bufferedPositionStream,
            initialDuration: item.duration,
            initialPosition: handler.position,
            initialBufferedPosition:
                handler.playbackState.value.bufferedPosition,
            onSeek: handler.seek,
            compact: compact,
          ),
        ),
      ),
      SizedBox(height: compact ? 12 : 20),
      _ControlReveal(
        order: 2,
        child: PlayerPlaybackControls(handler: handler, compact: compact),
      ),
      if (song != null) ...[
        SizedBox(height: compact ? 8 : 16),
        _ControlReveal(
          order: 2,
          child: Row(
            children: [
              Flexible(
                child: PlayerQualitySelector(
                  handler: handler,
                  song: song!,
                  compact: compact,
                ),
              ),
              const SizedBox(width: 8),
              AddToPlaylistButton(song: song!),
              if (handler.isRecommendationQueue)
                IconButton(
                  tooltip: '不感兴趣',
                  icon: const Icon(Icons.thumb_down_alt_outlined, size: 21),
                  onPressed: () async {
                    try {
                      await handler.dislikeCurrent();
                    } catch (_) {
                      if (context.mounted) showAppError(context, '操作失败，请重试');
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    ],
  );
}

class _TrackHeading extends StatelessWidget {
  const _TrackHeading({
    super.key,
    required this.item,
    required this.song,
    required this.compact,
  });

  final MediaItem item;
  final Song? song;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final titleSize = compact ? 20.0 : 24.0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scaler.scale(14) > 21)
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                )
              else
                SizedBox(
                  height: scaler.scale(titleSize) * 1.4,
                  child: KgMarqueeText(
                    item.title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              const SizedBox(height: KgSpacing.xxs),
              Text(
                item.artist ?? '未知歌手',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: KgColors.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (song != null) ...[
          const SizedBox(width: KgSpacing.xs),
          SongFavoriteButton(song: song!),
        ],
      ],
    );
  }
}

/// Driven by the route itself, including reversed and cancelled drag gestures.
/// No independent controller can drift away from the cover's Hero flight.
class _ControlReveal extends StatelessWidget {
  const _ControlReveal({required this.order, required this.child});
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final progress = animation.drive(
      CurveTween(
        curve: Interval(0.25 + order * 0.10, 1, curve: KgMotion.standard),
      ),
    );
    return FadeTransition(
      opacity: progress,
      child: AnimatedBuilder(
        animation: progress,
        // Each group moves independently. Retain its paint, rather than
        // repainting the entire control deck for every reveal frame.
        child: RepaintBoundary(child: child),
        builder: (context, child) => IgnorePointer(
          ignoring: progress.value < 0.1,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - progress.value)),
            child: child,
          ),
        ),
      ),
    );
  }
}
