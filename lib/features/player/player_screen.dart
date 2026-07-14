import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
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
          final artworkSize = (MediaQuery.sizeOf(context).height * 0.36)
              .clamp(200.0, 300.0)
              .toDouble();
          return Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 34),
            child: Column(
              children: [
                const Spacer(),
                SongArtwork(
                  url: item.artUri?.toString(),
                  size: artworkSize,
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
                if (currentSong != null) ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _QualitySelector(
                      handler: handler,
                      song: currentSong,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
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

class _QualitySelector extends StatelessWidget {
  const _QualitySelector({required this.handler, required this.song});

  final MusicAudioHandler handler;
  final Song song;

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
            .map((quality) {
              final available = quality.isAvailableFor(song);
              return PopupMenuItem<AudioQuality>(
                value: quality,
                enabled: available,
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Icon(
                        state.requested == quality
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: state.requested == quality
                            ? KgColors.accent
                            : KgColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(quality.label),
                          Text(
                            available
                                ? quality.detail
                                : '${quality.detail} · 无可用资源',
                            style: const TextStyle(
                              color: KgColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: KgColors.elevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.switching)
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.graphic_eq_rounded, size: 18),
              const SizedBox(width: 8),
              Text(_qualityLabel(state)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down_rounded, size: 20),
            ],
          ),
        ),
      );
    },
  );

  String _qualityLabel(PlaybackQualityState state) {
    if (state.switching) return '正在切换到 ${state.requested.label}';
    final actual = state.actual ?? state.requested;
    final bitRate = state.bitRateKbps;
    final parts = <String>[
      if (state.preview) '试听',
      actual.label,
      if (bitRate != null) '$bitRate kbps',
      if (state.fellBack) '已回退',
    ];
    return parts.join(' · ');
  }

  Future<void> _switchQuality(
    BuildContext context,
    AudioQuality quality,
  ) async {
    try {
      await handler.setPlaybackQuality(quality);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('切换音质失败：$error')));
      }
    }
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
