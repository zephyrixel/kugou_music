import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/features/player/player_queue_sheet.dart';

class PlayerPlaybackControls extends StatelessWidget {
  const PlayerPlaybackControls({
    super.key,
    required this.handler,
    required this.compact,
  });

  final MusicAudioHandler handler;
  final bool compact;

  @override
  Widget build(BuildContext context) => StreamBuilder<PlaybackState>(
    stream: handler.playbackState,
    initialData: handler.playbackState.value,
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
                ? KgBusyIndicator(
                    size: compact ? 24 : 28,
                    strokeWidth: 3,
                    color: Colors.black,
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
