import 'dart:ui' as ui;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/features/player/player_control_deck.dart';
import 'package:kgmusic/features/player/player_visual_pager.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        title: StreamBuilder<PlaybackQueueState>(
          stream: handler.queueStateStream,
          initialData: handler.queueState,
          builder: (context, snapshot) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '正在播放',
                  style: TextStyle(fontSize: 11, color: KgColors.textMuted),
                ),
                Text(
                  snapshot.data?.origin.displayTitle ?? '播放队列',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
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
              KgColors.background.withValues(alpha: 0.58),
              KgColors.background.withValues(alpha: 0.94),
            ],
          ),
        ),
      ),
      SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape =
                constraints.maxWidth > constraints.maxHeight &&
                constraints.maxWidth >= 600;
            return landscape
                ? _LandscapePlayer(
                    handler: handler,
                    item: item,
                    song: song,
                    constraints: constraints,
                  )
                : _PortraitPlayer(
                    handler: handler,
                    item: item,
                    song: song,
                    constraints: constraints,
                  );
          },
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
  const _PortraitPlayer({
    required this.handler,
    required this.item,
    required this.song,
    required this.constraints,
  });

  final MusicAudioHandler handler;
  final MediaItem item;
  final Song? song;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final compact = constraints.maxHeight < 650;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, compact ? 0 : 8, 16, 0),
            child: PlayerVisualPager(
              handler: handler,
              item: item,
              song: song,
              compact: compact,
            ),
          ),
        ),
        _ControlSurface(
          portrait: true,
          compact: compact,
          child: PlayerControlDeck(
            handler: handler,
            item: item,
            song: song,
            compact: compact,
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
    required this.song,
    required this.constraints,
  });

  final MusicAudioHandler handler;
  final MediaItem item;
  final Song? song;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final compact = constraints.maxHeight < 410;
    final panelWidth = (constraints.maxWidth * 0.42)
        .clamp(330.0, 460.0)
        .toDouble();
    return Padding(
      padding: EdgeInsets.fromLTRB(18, compact ? 6 : 12, 18, compact ? 8 : 16),
      child: Row(
        children: [
          Expanded(
            child: PlayerVisualPager(
              handler: handler,
              item: item,
              song: song,
              compact: compact,
            ),
          ),
          SizedBox(width: compact ? 12 : 22),
          SizedBox(
            width: panelWidth,
            child: Align(
              alignment: Alignment.center,
              child: _ControlSurface(
                portrait: false,
                compact: compact,
                child: PlayerControlDeck(
                  handler: handler,
                  item: item,
                  song: song,
                  compact: compact,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlSurface extends StatelessWidget {
  const _ControlSurface({
    required this.portrait,
    required this.compact,
    required this.child,
  });

  final bool portrait;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
      compact ? 18 : 22,
      compact ? 10 : 16,
      compact ? 18 : 22,
      compact ? 8 : 14,
    ),
    decoration: BoxDecoration(
      color: KgColors.surface.withValues(alpha: portrait ? 0.88 : 0.76),
      borderRadius: portrait
          ? const BorderRadius.vertical(top: Radius.circular(28))
          : BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: child,
  );
}

class _AmbientArtwork extends StatelessWidget {
  const _AmbientArtwork({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Opacity(
      opacity: 0.3,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 38, sigmaY: 38),
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
