import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/features/player/player_queue_sheet.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      initialData: handler.mediaItem.value,
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Material(
            color: KgColors.elevated,
            borderRadius: BorderRadius.circular(KgRadii.medium),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/player'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 62),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'player-artwork:${item.id}',
                            transitionOnUserGestures: true,
                            child: SongArtwork(
                              url: item.artUri?.toString(),
                              cacheId: 'song:${item.id}',
                              size: 44,
                              radius: 8,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.artist ?? '未知歌手',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          StreamBuilder<PlaybackState>(
                            stream: handler.playbackState,
                            initialData: handler.playbackState.value,
                            builder: (context, stateSnapshot) {
                              final state = stateSnapshot.data;
                              final playing = state?.playing ?? false;
                              final loading =
                                  state?.processingState ==
                                      AudioProcessingState.loading ||
                                  state?.processingState ==
                                      AudioProcessingState.buffering;
                              return IconButton(
                                tooltip: loading
                                    ? '正在加载'
                                    : playing
                                    ? '暂停'
                                    : '播放',
                                onPressed: loading
                                    ? null
                                    : playing
                                    ? handler.pause
                                    : handler.play,
                                icon: loading
                                    ? const KgBusyIndicator(size: 20)
                                    : AnimatedSwitcher(
                                        duration: KgMotion.resolve(
                                          context,
                                          KgMotion.fast,
                                        ),
                                        child: Icon(
                                          playing
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          key: ValueKey(playing),
                                          size: 28,
                                        ),
                                      ),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: '播放队列',
                            onPressed: () =>
                                showPlayerQueueSheet(context, handler),
                            icon: const Icon(
                              Icons.queue_music_rounded,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _MiniProgress(handler: handler),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The mini player is mounted on every screen for the app's lifetime, and
/// `positionStream` ticks up to 62 Hz on short previews. A 2px bar cannot show
/// more than whole percent steps, so collapse to that before rebuilding.
class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.handler});

  final MusicAudioHandler handler;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: StreamBuilder<Duration?>(
      stream: handler.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data?.inMilliseconds ?? 0;
        if (duration <= 0) {
          return const _MiniProgressBars(value: 0, buffered: 0);
        }
        return StreamBuilder<int>(
          stream: handler.playbackState
              .map((state) => _percent(state.bufferedPosition, duration))
              .distinct(),
          builder: (context, bufferedSnapshot) => StreamBuilder<int>(
            stream: handler.positionStream
                .map((position) => _percent(position, duration))
                .distinct(),
            builder: (context, positionSnapshot) => _MiniProgressBars(
              value: (positionSnapshot.data ?? 0) / 100,
              buffered: (bufferedSnapshot.data ?? 0) / 100,
            ),
          ),
        );
      },
    ),
  );

  static int _percent(Duration position, int durationMs) =>
      (position.inMilliseconds * 100 / durationMs).clamp(0, 100).round();
}

class _MiniProgressBars extends StatelessWidget {
  const _MiniProgressBars({required this.value, required this.buffered});

  final double value;
  final double buffered;

  @override
  Widget build(BuildContext context) => Stack(
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
}
