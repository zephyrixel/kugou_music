import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/artwork_backdrop.dart';
import 'package:kgmusic/core/widgets/kg_glass_surface.dart';
import 'package:kgmusic/core/widgets/kg_marquee_text.dart';
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
      builder: (context, itemSnapshot) {
        final item = itemSnapshot.data;
        if (item == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KgRadii.large),
            boxShadow: [
              BoxShadow(
                color: KgColors.accent.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: KgGlassSurface(
            blurSigma: 0,
            color: KgColors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(KgRadii.large),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/player'),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned.fill(
                      child: ArtworkBackdrop(
                        url: item.artUri?.toString(),
                        cacheId: 'song:${item.id}',
                        opacity: 0.3,
                        sourceSize: 48,
                        decodePixelSize: 96,
                        blurSigma: 24,
                        overlayGradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            KgColors.surface.withValues(alpha: 0.34),
                            KgColors.surface.withValues(alpha: 0.82),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 70,
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          AnimatedSwitcher(
                            duration: KgMotion.resolve(
                              context,
                              KgMotion.medium,
                            ),
                            child: Hero(
                              key: ValueKey(item.id),
                              tag: 'player-artwork:${item.id}',
                              child: SongArtwork(
                                url: item.artUri?.toString(),
                                cacheId: 'song:${item.id}',
                                size: 48,
                                radius: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 21,
                                  child: KgMarqueeText(
                                    item.title,
                                    key: ValueKey('title:${item.id}'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 20,
                                  child: KgMarqueeText(
                                    item.artist ?? '未知歌手',
                                    key: ValueKey('artist:${item.id}'),
                                    velocity: 24,
                                    style: const TextStyle(
                                      color: KgColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
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
                                    : (playing ? '暂停' : '播放'),
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
                            onPressed: () =>
                                showPlayerQueueSheet(context, handler),
                            icon: const Icon(Icons.queue_music_rounded),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                    _MiniProgress(handler: handler),
                  ],
                ),
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
