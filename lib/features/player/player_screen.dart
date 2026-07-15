import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/song_favorite_button.dart';
import 'package:kgmusic/core/widgets/add_to_playlist_button.dart';
import 'package:kgmusic/features/player/playback_progress_bar.dart';
import 'package:kgmusic/features/player/player_visual_pager.dart';

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
          return _PlayerBody(handler: handler, item: item, song: currentSong);
        },
      ),
    );
  }
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({required this.handler, required this.item, this.song});

  final MusicAudioHandler handler;
  final MediaItem item;
  final Song? song;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final maxArtworkSize = (constraints.maxWidth - 80)
          .clamp(160.0, 320.0)
          .toDouble();
      final visualHeight = (constraints.maxHeight * 0.46)
          .clamp(260.0, 360.0)
          .toDouble();
      final artworkSize = (visualHeight - 28)
          .clamp(160.0, maxArtworkSize)
          .toDouble();
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 10, 28, 34),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PlayerVisualPager(
                handler: handler,
                item: item,
                song: song,
                height: visualHeight,
                artworkSize: artworkSize,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.artist ?? '未知歌手',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: KgColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (song != null) ...[
                    SongFavoriteButton(song: song!),
                    AddToPlaylistButton(song: song!),
                  ],
                ],
              ),
              if (song != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _QualitySelector(handler: handler, song: song!),
                ),
              ],
              const SizedBox(height: 14),
              PlaybackProgressBar(
                durationStream: handler.durationStream,
                positionStream: handler.positionStream,
                onSeek: handler.seek,
              ),
              const SizedBox(height: 16),
              _PlaybackControls(handler: handler),
            ],
          ),
        ),
      );
    },
  );
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.handler});

  final MusicAudioHandler handler;

  @override
  Widget build(BuildContext context) => StreamBuilder<PlaybackState>(
    stream: handler.playbackState,
    builder: (context, snapshot) {
      final playing = snapshot.data?.playing ?? false;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: '上一首',
            iconSize: 36,
            onPressed: handler.skipToPrevious,
            icon: const Icon(Icons.skip_previous_rounded),
          ),
          IconButton.filled(
            tooltip: playing ? '暂停' : '播放',
            iconSize: 42,
            padding: const EdgeInsets.all(18),
            style: IconButton.styleFrom(
              backgroundColor: KgColors.accent,
              foregroundColor: Colors.black,
            ),
            onPressed: playing ? handler.pause : handler.play,
            icon: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
          IconButton(
            tooltip: '下一首',
            iconSize: 36,
            onPressed: handler.skipToNext,
            icon: const Icon(Icons.skip_next_rounded),
          ),
        ],
      );
    },
  );
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
        showAppError(context, '切换音质失败：$error');
      }
    }
  }
}
