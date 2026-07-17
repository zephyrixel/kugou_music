import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
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
  Widget build(BuildContext context) {
    final gap = compact ? 7.0 : 12.0;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TrackHeading(item: item, song: song, compact: compact),
          if (song != null) ...[
            SizedBox(height: gap),
            Row(
              children: [
                PlayerQualitySelector(
                  handler: handler,
                  song: song!,
                  compact: compact,
                ),
                const Spacer(),
                if (handler.isRecommendationQueue)
                  _DislikeButton(handler: handler, compact: compact),
              ],
            ),
          ],
          SizedBox(height: gap),
          RepaintBoundary(
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
          SizedBox(height: compact ? 4 : 8),
          PlayerPlaybackControls(handler: handler, compact: compact),
        ],
      ),
    );
  }
}

class _DislikeButton extends StatelessWidget {
  const _DislikeButton({required this.handler, required this.compact});

  final MusicAudioHandler handler;
  final bool compact;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () async {
      try {
        await handler.dislikeCurrent();
      } catch (_) {
        if (context.mounted) showAppError(context, '暂时无法处理这首歌曲，请稍后重试');
      }
    },
    style: TextButton.styleFrom(
      foregroundColor: KgColors.textMuted,
      minimumSize: Size(0, compact ? 34 : 40),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    ),
    icon: const Icon(Icons.thumb_down_alt_outlined, size: 17),
    label: Text('不感兴趣', style: TextStyle(fontSize: compact ? 11 : 12)),
  );
}

class _TrackHeading extends StatelessWidget {
  const _TrackHeading({
    required this.item,
    required this.song,
    required this.compact,
  });

  final MediaItem item;
  final Song? song;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: compact ? 28 : 34,
              child: KgMarqueeText(
                item.title,
                style:
                    (compact
                            ? Theme.of(context).textTheme.titleLarge
                            : Theme.of(context).textTheme.headlineSmall)
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                        ),
              ),
            ),
            SizedBox(height: compact ? 2 : 4),
            SizedBox(
              height: compact ? 18 : 21,
              child: KgMarqueeText(
                [
                  item.artist ?? '未知歌手',
                  if (!compact && item.album?.trim().isNotEmpty == true)
                    item.album!,
                ].join(' · '),
                velocity: 24,
                style: TextStyle(
                  color: KgColors.textMuted,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
      if (song != null) ...[
        const SizedBox(width: 6),
        SongFavoriteButton(song: song!, compact: true),
        AddToPlaylistButton(song: song!, compact: true),
      ],
    ],
  );
}
