import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
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
      final selectorHeight = widget.compact ? 30.0 : 34.0;
      final pageHeight = math.max(
        0.0,
        constraints.maxHeight - selectorHeight - 6,
      );
      final artworkPadding = widget.compact ? 7.0 : 10.0;
      final artworkSize = math.max(
        0.0,
        math.min(
          constraints.maxWidth - 32 - artworkPadding * 2,
          pageHeight - artworkPadding * 2,
        ),
      );
      return Column(
        children: [
          SizedBox(
            height: pageHeight,
            child: PageView(
              controller: _controller,
              onPageChanged: (page) => setState(() => _page = page),
              children: [
                _ArtworkPage(
                  item: widget.item,
                  size: artworkSize,
                  compact: widget.compact,
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
          const SizedBox(height: 6),
          SizedBox(
            height: selectorHeight,
            child: _PageSelector(
              page: _page,
              onSelected: (page) => _controller.animateToPage(
                page,
                duration: KgMotion.resolve(context, KgMotion.medium),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ArtworkPage extends StatelessWidget {
  const _ArtworkPage({
    required this.item,
    required this.size,
    required this.compact,
  });

  final MediaItem item;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: EdgeInsets.all(compact ? 7 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 28 : 36),
        gradient: RadialGradient(
          colors: [KgColors.accent.withValues(alpha: 0.18), Colors.transparent],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Hero(
        tag: 'player-artwork:${item.id}',
        child: SongArtwork(
          url: item.artUri?.toString(),
          cacheId: 'song:${item.id}',
          size: size,
          radius: compact ? 22 : 28,
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
        Text('当前歌曲信息不足，无法加载歌词', style: TextStyle(color: KgColors.textMuted)),
      ],
    ),
  );
}

class _PageSelector extends StatelessWidget {
  const _PageSelector({required this.page, required this.onSelected});

  final int page;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PageIndicator(
            active: page == 0,
            icon: Icons.album_rounded,
            label: '封面',
            onTap: () => onSelected(0),
          ),
          _PageIndicator(
            active: page == 1,
            icon: Icons.lyrics_rounded,
            label: '歌词',
            onTap: () => onSelected(1),
          ),
        ],
      ),
    ),
  );
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: active ? KgColors.accentSoft : Colors.transparent,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: KgMotion.resolve(context, KgMotion.fast),
        height: 28,
        width: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? KgColors.accent : KgColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? KgColors.accent : KgColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
