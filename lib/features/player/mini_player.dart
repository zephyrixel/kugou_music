import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

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
                      SongArtwork(
                        url: item.artUri?.toString(),
                        cacheId: 'song:${item.id}',
                        size: 48,
                        radius: 12,
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
                          final playing = stateSnapshot.data?.playing ?? false;
                          return IconButton(
                            onPressed: playing ? handler.pause : handler.play,
                            icon: Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: '下一首',
                        onPressed: handler.skipToNext,
                        icon: const Icon(Icons.skip_next_rounded),
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
    builder: (context, durationSnapshot) => StreamBuilder<Duration>(
      stream: handler.positionStream,
      builder: (context, positionSnapshot) {
        final duration = durationSnapshot.data?.inMilliseconds ?? 0;
        final position = positionSnapshot.data?.inMilliseconds ?? 0;
        final value = duration <= 0
            ? 0.0
            : (position / duration).clamp(0.0, 1.0);
        return LinearProgressIndicator(
          value: value,
          minHeight: 2,
          backgroundColor: KgColors.divider,
          color: KgColors.accent,
        );
      },
    ),
  );
}
