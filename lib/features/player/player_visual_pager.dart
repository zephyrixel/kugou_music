import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/kg_choice_tabs.dart';
import 'package:kgmusic/app/delegated_transition_page.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/features/player/lyrics/lyrics_panel.dart';

class PlayerVisualPager extends StatefulWidget {
  const PlayerVisualPager({
    required this.handler,
    required this.item,
    required this.song,
    required this.compact,
    super.key,
  });

  final MusicAudioHandler handler;
  final MediaItem item;
  final Song? song;
  final bool compact;

  @override
  State<PlayerVisualPager> createState() => _PlayerVisualPagerState();
}

class _PlayerVisualPagerState extends State<PlayerVisualPager> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final selectorHeight = math.max(
        48.0,
        26 + MediaQuery.textScalerOf(context).scale(14) * 1.5,
      );
      final pageHeight = math.max(
        0.0,
        constraints.maxHeight - selectorHeight - 6,
      );
      final shadowInset = widget.compact ? 12.0 : 20.0;
      final artworkSize = math.max(
        0.0,
        math.min(
          constraints.maxWidth - shadowInset * 2,
          pageHeight - shadowInset * 2,
        ),
      );
      return Column(
        children: [
          SizedBox(
            height: pageHeight,
            child: RepaintBoundary(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  PlayerDismissRegion(
                    child: _ArtworkPage(item: widget.item, size: artworkSize),
                  ),
                  if (widget.song == null)
                    const _UnavailableLyrics()
                  else
                    LyricsPanel(
                      song: widget.song!,
                      positionStream: widget.handler.positionStream,
                      onSeek: widget.handler.seek,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: selectorHeight,
            child: Center(
              child: KgChoiceTabs<int>(
                pill: true,
                options: const {0: '封面', 1: '歌词'},
                value: _page,
                onChanged: (page) {
                  if (MediaQuery.disableAnimationsOf(context)) {
                    _controller.jumpToPage(page);
                  } else {
                    _controller.animateToPage(
                      page,
                      duration: KgMotion.medium,
                      curve: KgMotion.standard,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ArtworkPage extends StatelessWidget {
  const _ArtworkPage({required this.item, required this.size});

  final MediaItem item;
  final double size;

  @override
  Widget build(BuildContext context) => Center(
    child: Hero(
      tag: 'player-artwork:${item.id}',
      transitionOnUserGestures: true,
      createRectTween: (begin, end) =>
          MaterialRectCenterArcTween(begin: begin, end: end),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KgRadii.medium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          // Match the Hero's bounds throughout expansion and dismissal.
          layoutBuilder: (child, previous) => Stack(
            fit: StackFit.passthrough,
            alignment: Alignment.center,
            children: [...previous, ?child],
          ),
          duration: KgMotion.resolve(context, KgMotion.medium),
          child: SongArtwork(
            key: ValueKey(item.id),
            url: item.artUri?.toString(),
            cacheId: 'song:${item.id}',
            size: size,
            radius: KgRadii.medium,
          ),
        ),
      ),
    ),
  );
}

class _UnavailableLyrics extends StatelessWidget {
  const _UnavailableLyrics();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lyrics_outlined, size: 34, color: KgColors.textMuted),
        SizedBox(height: 10),
        Text('暂无歌词', style: TextStyle(color: KgColors.textMuted)),
      ],
    ),
  );
}
