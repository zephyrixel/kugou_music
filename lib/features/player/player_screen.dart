import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/artwork_backdrop.dart';
import 'package:kgmusic/core/widgets/kg_glass_surface.dart';
import 'package:kgmusic/features/player/player_control_deck.dart';
import 'package:kgmusic/features/player/player_visual_pager.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarDividerColor: Colors.transparent,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          forceMaterialTransparency: true,
          systemOverlayStyle: overlayStyle,
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
          initialData: handler.mediaItem.value,
          builder: (context, snapshot) {
            final item = snapshot.data;
            if (item == null) {
              return const ColoredBox(
                color: KgColors.background,
                child: Center(child: Text('还没有开始播放')),
              );
            }
            final index = handler.currentIndex;
            final currentSong = index >= 0 && index < handler.songs.length
                ? handler.songs[index]
                : null;
            return _PlayerBody(handler: handler, item: item, song: currentSong);
          },
        ),
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
      ArtworkBackdrop(
        url: item.artUri?.toString(),
        cacheId: 'song:${item.id}',
        blur: 42,
        opacity: 0.54,
        scrim: 0.62,
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              KgColors.background.withValues(alpha: 0.5),
              KgColors.background.withValues(alpha: 0.12),
              KgColors.background.withValues(alpha: 0.4),
              KgColors.background.withValues(alpha: 0.86),
            ],
            stops: const [0, 0.2, 0.62, 1],
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + kToolbarHeight,
        ),
        child: SafeArea(
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
      ),
      Positioned(
        left: 16,
        right: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 12,
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
        SizedBox(height: compact ? 6 : 12),
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
  Widget build(BuildContext context) {
    final radius = portrait
        ? const BorderRadius.vertical(top: Radius.circular(28))
        : BorderRadius.circular(28);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: KgColors.background.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: KgGlassSurface(
        borderRadius: radius,
        color: KgColors.surface.withValues(alpha: portrait ? 0.62 : 0.56),
        blurSigma: 22,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 22,
            compact ? 10 : 16,
            compact ? 18 : 22,
            compact ? 8 : 14,
          ),
          child: child,
        ),
      ),
    );
  }
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
      return KgGlassSurface(
        borderRadius: BorderRadius.circular(14),
        color: KgColors.elevatedHigh.withValues(alpha: 0.82),
        blurSigma: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(message, style: const TextStyle(fontSize: 13)),
        ),
      );
    },
  );
}
