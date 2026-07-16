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
