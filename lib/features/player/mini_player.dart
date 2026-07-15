import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/features/player/player_queue_sheet.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, itemSnapshot) {
        final item = itemSnapshot.data;
        if (item == null) return const SizedBox.shrink();
        return Material(
          color: KgColors.elevated,
          child: InkWell(
            onTap: () => context.push('/player'),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  height: 70,
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Hero(
                        tag: 'player-artwork:${item.id}',
                        child: SongArtwork(
                          url: item.artUri?.toString(),
                          cacheId: 'song:${item.id}',
                          size: 48,
                          radius: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              item.artist ?? '未知歌手',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: KgColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<PlaybackState>(
                        stream: handler.playbackState,
                        builder: (context, stateSnapshot) {
                          final state = stateSnapshot.data;
                          final playing = state?.playing ?? false;
                          final loading =
                              state?.processingState ==
                                  AudioProcessingState.loading ||
                              state?.processingState ==
                                  AudioProcessingState.buffering;
                          return IconButton(
                            tooltip: loading ? '正在加载' : (playing ? '暂停' : '播放'),
                            onPressed: loading
                                ? null
                                : (playing ? handler.pause : handler.play),
                            icon: loading
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: '播放队列',
                        onPressed: () => showPlayerQueueSheet(context, handler),
                        icon: const Icon(Icons.queue_music_rounded),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
                _MiniProgress(handler: handler),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.handler});

  final MusicAudioHandler handler;

  @override
  Widget build(BuildContext context) => StreamBuilder<Duration?>(
    stream: handler.durationStream,
    builder: (context, durationSnapshot) => StreamBuilder<PlaybackState>(
      stream: handler.playbackState,
      builder: (context, stateSnapshot) => StreamBuilder<Duration>(
        stream: handler.positionStream,
        builder: (context, positionSnapshot) {
          final duration = durationSnapshot.data?.inMilliseconds ?? 0;
          final position = positionSnapshot.data?.inMilliseconds ?? 0;
          final value = duration <= 0
              ? 0.0
              : (position / duration).clamp(0.0, 1.0);
          final buffered = duration <= 0
              ? 0.0
              : ((stateSnapshot.data?.bufferedPosition.inMilliseconds ?? 0) /
                        duration)
                    .clamp(0.0, 1.0);
          return Stack(
            children: [
              LinearProgressIndicator(
                value: buffered,
                minHeight: 2,
                backgroundColor: KgColors.divider,
                color: Colors.white30,
              ),
              LinearProgressIndicator(
                value: value,
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: KgColors.accent,
              ),
            ],
          );
        },
      ),
    ),
  );
}
