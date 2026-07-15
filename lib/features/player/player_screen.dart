import 'dart:ui' as ui;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/add_to_playlist_button.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/core/widgets/song_favorite_button.dart';
import 'package:kgmusic/features/player/playback_progress_bar.dart';
import 'package:kgmusic/features/player/player_queue_sheet.dart';
import 'package:kgmusic/features/player/player_visual_pager.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<PlaybackQueueState>(
          stream: handler.queueStateStream,
          initialData: handler.queueState,
          builder: (context, snapshot) => Text(
            snapshot.data?.origin.displayTitle ?? '正在播放',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          StreamBuilder<PlaybackQueueState>(
            stream: handler.queueStateStream,
            initialData: handler.queueState,
            builder: (context, snapshot) => IconButton(
              tooltip: '播放队列',
              onPressed: snapshot.data == null
                  ? null
                  : () => showPlayerQueueSheet(context, handler),
              icon: const Icon(Icons.queue_music_rounded),
            ),
          ),
        ],
      ),
      body: StreamBuilder<MediaItem?>(
        stream: handler.mediaItem,
        builder: (context, snapshot) {
          final item = snapshot.data;
          if (item == null) {
            return const Center(child: Text('还没有开始播放'));
          }
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
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      _AmbientArtwork(item: item),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              KgColors.background.withValues(alpha: 0.68),
              KgColors.background.withValues(alpha: 0.96),
            ],
          ),
        ),
      ),
      SafeArea(
        top: false,
        child: OrientationBuilder(
          builder: (context, orientation) =>
              orientation == Orientation.landscape
              ? _LandscapePlayer(handler: handler, item: item, song: song)
              : _PortraitPlayer(handler: handler, item: item, song: song),
        ),
      ),
      Positioned(
        left: 16,
        right: 16,
        bottom: 12,
        child: _PlayerMessageBanner(handler: handler),
      ),
    ],
  );
}

class _PortraitPlayer extends StatelessWidget {
  const _PortraitPlayer({required this.handler, required this.item, this.song});

  final MusicAudioHandler handler;
  final MediaItem item;
  final Song? song;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final visualHeight = (height * 0.42).clamp(230.0, 390.0).toDouble();
    final artworkSize = (visualHeight - 20)
        .clamp(180.0, MediaQuery.sizeOf(context).width - 64)
        .toDouble();
    return Column(
      children: [
        PlayerVisualPager(
          handler: handler,
          item: item,
          song: song,
          height: visualHeight,
          artworkSize: artworkSize,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            child: _PlayerControlDeck(handler: handler, item: item, song: song),
          ),
        ),
      ],
    );
  }
}

class _LandscapePlayer extends StatelessWidget {
  const _LandscapePlayer({
    required this.handler,
    required this.item,
    this.song,
  });

  final MusicAudioHandler handler;
  final MediaItem item;
  final Song? song;

  @override
  Widget build(BuildContext context) {
    final availableHeight = (MediaQuery.sizeOf(context).height - 92)
        .clamp(220.0, 520.0)
        .toDouble();
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: PlayerVisualPager(
            handler: handler,
            item: item,
            song: song,
            height: availableHeight,
            artworkSize: availableHeight - 36,
          ),
        ),
        SizedBox(
          width: 360,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 8, 22, 24),
            child: _PlayerControlDeck(handler: handler, item: item, song: song),
          ),
        ),
      ],
    );
  }
}

class _PlayerControlDeck extends StatelessWidget {
  const _PlayerControlDeck({
    required this.handler,
    required this.item,
    this.song,
  });

  final MusicAudioHandler handler;
  final MediaItem item;
  final Song? song;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    item.artist ?? '未知歌手',
                    if (item.album?.trim().isNotEmpty == true) item.album!,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: KgColors.textMuted),
                ),
              ],
            ),
          ),
          if (song != null) SongFavoriteButton(song: song!, compact: true),
          if (song != null) AddToPlaylistButton(song: song!),
        ],
      ),
      if (song != null) ...[
        const SizedBox(height: 14),
        Row(
          children: [
            _QualitySelector(handler: handler, song: song!),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => showPlayerQueueSheet(context, handler),
              icon: const Icon(Icons.queue_music_rounded, size: 18),
              label: const Text('队列'),
            ),
          ],
        ),
      ],
      const SizedBox(height: 16),
      PlaybackProgressBar(
        durationStream: handler.durationStream,
        positionStream: handler.positionStream,
        bufferedPositionStream: handler.bufferedPositionStream,
        onSeek: handler.seek,
      ),
      const SizedBox(height: 10),
      _PlaybackControls(handler: handler),
    ],
  );
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.handler});

  final MusicAudioHandler handler;

  @override
  Widget build(BuildContext context) => StreamBuilder<PlaybackState>(
    stream: handler.playbackState,
    builder: (context, snapshot) {
      final state = snapshot.data;
      final playing = state?.playing ?? false;
      final loading =
          state?.processingState == AudioProcessingState.loading ||
          state?.processingState == AudioProcessingState.buffering;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ModeButton(handler: handler),
          IconButton(
            tooltip: '上一首',
            onPressed: loading ? null : handler.skipToPrevious,
            icon: const Icon(Icons.skip_previous_rounded),
          ),
          IconButton.filled(
            tooltip: loading ? '正在加载' : (playing ? '暂停' : '播放'),
            iconSize: 36,
            padding: const EdgeInsets.all(15),
            style: IconButton.styleFrom(
              backgroundColor: KgColors.accent,
              foregroundColor: Colors.black,
            ),
            onPressed: loading
                ? null
                : (playing ? handler.pause : handler.play),
            icon: loading
                ? const SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(
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
            onPressed: loading ? null : handler.skipToNext,
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
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: KgColors.elevated,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.switching ? Icons.sync_rounded : Icons.graphic_eq_rounded,
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(_qualityLabel(state)),
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

class _AmbientArtwork extends StatelessWidget {
  const _AmbientArtwork({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Opacity(
      opacity: 0.26,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.55,
            0,
            0,
            0,
            0,
            0,
            0.75,
            0,
            0,
            0,
            0,
            0,
            0.55,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: Center(
            child: SongArtwork(
              url: item.artUri?.toString(),
              cacheId: 'song:${item.id}',
              size: MediaQuery.sizeOf(context).longestSide,
              radius: 0,
            ),
          ),
        ),
      ),
    ),
  );
}

class _PlayerMessageBanner extends StatelessWidget {
  const _PlayerMessageBanner({required this.handler});
  final MusicAudioHandler handler;

  @override
  Widget build(BuildContext context) => StreamBuilder<String?>(
    stream: handler.messages,
    builder: (context, snapshot) {
      final message = snapshot.data;
      if (message == null || message.isEmpty) return const SizedBox.shrink();
      return Material(
        color: KgColors.elevatedHigh,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(message, style: const TextStyle(fontSize: 13)),
        ),
      );
    },
  );
}
