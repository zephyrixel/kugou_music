import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/core/widgets/song_favorite_button.dart';
import 'package:kgmusic/core/widgets/add_to_playlist_button.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('正在播放'),
      ),
      body: StreamBuilder<MediaItem?>(
        stream: handler.mediaItem,
        builder: (context, snapshot) {
          final item = snapshot.data;
          if (item == null) return const Center(child: Text('还没有开始播放'));
          final index = handler.currentIndex;
          final currentSong = index >= 0 && index < handler.songs.length
              ? handler.songs[index]
              : null;
          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 34),
            child: Column(
              children: [
                const Spacer(),
                SongArtwork(
                  url: item.artUri?.toString(),
                  size: 300,
                  radius: 30,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.artist ?? '未知歌手',
                            style: const TextStyle(color: KgColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (currentSong != null) ...[
                      SongFavoriteButton(song: currentSong),
                      AddToPlaylistButton(song: currentSong),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                _Progress(handler: handler),
                const SizedBox(height: 18),
                StreamBuilder<PlaybackState>(
                  stream: handler.playbackState,
                  builder: (context, stateSnapshot) {
                    final playing = stateSnapshot.data?.playing ?? false;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          iconSize: 38,
                          onPressed: handler.skipToPrevious,
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        IconButton.filled(
                          iconSize: 44,
                          padding: const EdgeInsets.all(18),
                          style: IconButton.styleFrom(
                            backgroundColor: KgColors.accent,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: playing ? handler.pause : handler.play,
                          icon: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                        IconButton(
                          iconSize: 38,
                          onPressed: handler.skipToNext,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.handler});
  final MusicAudioHandler handler;

  @override
  Widget build(BuildContext context) => StreamBuilder<Duration?>(
    stream: handler.durationStream,
    builder: (context, durationSnapshot) {
      final duration = durationSnapshot.data ?? Duration.zero;
      return StreamBuilder<Duration>(
        stream: handler.positionStream,
        builder: (context, positionSnapshot) {
          final position = positionSnapshot.data ?? Duration.zero;
          final max = duration.inMilliseconds
              .toDouble()
              .clamp(1, double.infinity)
              .toDouble();
          final value = position.inMilliseconds
              .toDouble()
              .clamp(0, max)
              .toDouble();
          return Column(
            children: [
              Slider(
                value: value,
                max: max,
                onChanged: (next) =>
                    handler.seek(Duration(milliseconds: next.round())),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(position)),
                  Text(formatDuration(duration)),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}
