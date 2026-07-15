import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/add_to_playlist_button.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/song_favorite_button.dart';
import 'package:kgmusic/features/player/playback_progress_bar.dart';
import 'package:kgmusic/features/player/player_queue_sheet.dart';

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
                _QualitySelector(
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
          PlaybackProgressBar(
            durationStream: handler.durationStream,
            positionStream: handler.positionStream,
            bufferedPositionStream: handler.bufferedPositionStream,
            onSeek: handler.seek,
            compact: compact,
          ),
          SizedBox(height: compact ? 4 : 8),
          _PlaybackControls(handler: handler, compact: compact),
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
      } catch (error) {
        if (context.mounted) showAppError(context, error);
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
            Text(
              item.title,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style:
                  (compact
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.headlineSmall)
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                      ),
            ),
            SizedBox(height: compact ? 2 : 4),
            Text(
              [
                item.artist ?? '未知歌手',
                if (!compact && item.album?.trim().isNotEmpty == true)
                  item.album!,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: KgColors.textMuted,
                fontSize: compact ? 12 : 14,
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

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.handler, required this.compact});

  final MusicAudioHandler handler;
  final bool compact;

  @override
  Widget build(BuildContext context) => StreamBuilder<PlaybackState>(
    stream: handler.playbackState,
    builder: (context, snapshot) {
      final state = snapshot.data;
      final playing = state?.playing ?? false;
      final loading = state?.processingState == AudioProcessingState.loading;
      final buffering =
          state?.processingState == AudioProcessingState.buffering;
      final busy = loading || buffering;
      final playButtonSize = compact ? 52.0 : 64.0;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ModeButton(handler: handler),
          IconButton(
            tooltip: '上一首',
            onPressed: busy ? null : handler.skipToPrevious,
            iconSize: compact ? 27 : 30,
            icon: const Icon(Icons.skip_previous_rounded),
          ),
          IconButton.filled(
            tooltip: loading
                ? '正在加载'
                : buffering
                ? '正在缓冲'
                : (playing ? '暂停' : '播放'),
            iconSize: compact ? 31 : 36,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              fixedSize: Size.square(playButtonSize),
              backgroundColor: KgColors.accent,
              disabledBackgroundColor: KgColors.accent,
              foregroundColor: Colors.black,
              disabledForegroundColor: Colors.black,
              shadowColor: KgColors.accent.withValues(alpha: 0.35),
              elevation: 8,
            ),
            onPressed: busy ? null : (playing ? handler.pause : handler.play),
            icon: loading
                ? SizedBox.square(
                    dimension: compact ? 24 : 28,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.black,
                    ),
                  )
                : Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
          ),
          IconButton(
            tooltip: '下一首',
            onPressed: busy ? null : handler.skipToNext,
            iconSize: compact ? 27 : 30,
            icon: const Icon(Icons.skip_next_rounded),
          ),
          IconButton(
            tooltip: '播放队列',
            onPressed: () => showPlayerQueueSheet(context, handler),
            icon: const Icon(Icons.queue_music_rounded),
          ),
        ],
      );
    },
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.handler});

  final MusicAudioHandler handler;

  @override
  Widget build(BuildContext context) => StreamBuilder<PlaybackQueueState>(
    stream: handler.queueStateStream,
    initialData: handler.queueState,
    builder: (context, snapshot) => IconButton(
      tooltip: snapshot.data?.order.label ?? '播放顺序',
      onPressed: snapshot.data == null
          ? null
          : () {
              final current = snapshot.data!.order;
              final next = PlaybackOrder
                  .values[(current.index + 1) % PlaybackOrder.values.length];
              handler.setPlaybackOrder(next);
            },
      icon: Icon(
        snapshot.data?.order == PlaybackOrder.shuffle
            ? Icons.shuffle_rounded
            : snapshot.data?.order == PlaybackOrder.repeatOne
            ? Icons.repeat_one_rounded
            : Icons.repeat_rounded,
        color: snapshot.data?.order == PlaybackOrder.sequential
            ? KgColors.textMuted
            : KgColors.accent,
      ),
    ),
  );
}

class _QualitySelector extends StatelessWidget {
  const _QualitySelector({
    required this.handler,
    required this.song,
    required this.compact,
  });

  final MusicAudioHandler handler;
  final Song song;
  final bool compact;

  @override
  Widget build(BuildContext context) => StreamBuilder<PlaybackQualityState>(
    stream: handler.qualityStateStream,
    initialData: handler.qualityState,
    builder: (context, snapshot) {
      final state = snapshot.data ?? handler.qualityState;
      return PopupMenuButton<AudioQuality>(
        tooltip: '切换播放音质',
        enabled: !state.switching,
        onSelected: (quality) => _switchQuality(context, quality),
        itemBuilder: (context) => AudioQuality.values
            .map(
              (quality) => PopupMenuItem<AudioQuality>(
                value: quality,
                enabled: quality.isAvailableFor(song),
                child: Row(
                  children: [
                    Icon(
                      state.requested == quality
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: state.requested == quality
                          ? KgColors.accent
                          : KgColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(quality.label),
                  ],
                ),
              ),
            )
            .toList(growable: false),
        child: Container(
          height: compact ? 34 : 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.065),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.switching ? Icons.sync_rounded : Icons.graphic_eq_rounded,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                _qualityLabel(state),
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded, size: 18),
            ],
          ),
        ),
      );
    },
  );

  String _qualityLabel(PlaybackQualityState state) {
    if (state.switching) return '切换中';
    final actual = state.actual ?? state.requested;
    return state.fellBack ? '${actual.label} · 回退' : actual.label;
  }

  Future<void> _switchQuality(
    BuildContext context,
    AudioQuality quality,
  ) async {
    try {
      await handler.setPlaybackQuality(quality);
    } catch (error) {
      if (context.mounted) showAppError(context, '切换音质失败：$error');
    }
  }
}
