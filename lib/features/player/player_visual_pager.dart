import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/features/player/lyrics/lyrics_panel.dart';

class PlayerVisualPager extends StatefulWidget {
  const PlayerVisualPager({
    required this.handler,
    required this.item,
    required this.song,
    required this.height,
    required this.artworkSize,
    super.key,
  });

  final MusicAudioHandler handler;
  final MediaItem item;
  final Song? song;
  final double height;
  final double artworkSize;

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
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: widget.height,
        child: PageView(
          controller: _controller,
          onPageChanged: (page) => setState(() => _page = page),
          children: [
            _ArtworkPage(item: widget.item, size: widget.artworkSize),
            if (widget.song == null)
              const Center(
                child: Text(
                  '当前歌曲信息不足，无法加载歌词',
                  style: TextStyle(color: KgColors.textMuted),
                ),
              )
            else
              LyricsPanel(
                song: widget.song!,
                positionStream: widget.handler.positionStream,
                onSeek: widget.handler.seek,
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageIndicator(
            active: _page == 0,
            icon: Icons.album_rounded,
            label: '封面',
            onTap: () => _controller.animateToPage(
              0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(width: 8),
          _PageIndicator(
            active: _page == 1,
            icon: Icons.lyrics_rounded,
            label: '歌词',
            onTap: () => _controller.animateToPage(
              1,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    ],
  );
}

class _ArtworkPage extends StatelessWidget {
  const _ArtworkPage({required this.item, required this.size});

  final MediaItem item;
  final double size;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        gradient: RadialGradient(
          colors: [KgColors.accent.withValues(alpha: 0.16), Colors.transparent],
        ),
      ),
      child: Hero(
        tag: 'player-artwork:${item.id}',
        child: SongArtwork(
          url: item.artUri?.toString(),
          cacheId: 'song:${item.id}',
          size: size,
          radius: 30,
        ),
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
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    width: active ? 68 : 38,
    height: 30,
    decoration: BoxDecoration(
      color: active ? KgColors.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 14,
            color: active ? KgColors.accent : KgColors.textMuted,
          ),
          if (active) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: KgColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
