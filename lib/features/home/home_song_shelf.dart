import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class HomeSongShelf extends StatelessWidget {
  const HomeSongShelf({
    super.key,
    required this.title,
    required this.songs,
    required this.onSongTap,
    required this.scrollKey,
    this.subtitle,
    this.onPlayAll,
  });

  final String title;
  final String? subtitle;
  final List<Song> songs;
  final ValueChanged<Song> onSongTap;
  final String scrollKey;
  final VoidCallback? onPlayAll;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cardWidth = constraints.maxWidth >= KgBreakpoints.mediumWidth
          ? 164.0
          : 142.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KgSectionHeader(
            title: title,
            subtitle: subtitle,
            action: onPlayAll == null
                ? null
                : IconButton(
                    tooltip: '播放全部',
                    onPressed: onPlayAll,
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
          ),
          const SizedBox(height: KgSpacing.md),
          SizedBox(
            height: _shelfHeight(context, cardWidth),
            child: ListView.separated(
              key: PageStorageKey('home-song-shelf:$scrollKey'),
              scrollDirection: Axis.horizontal,
              reverse: Directionality.of(context) == TextDirection.rtl,
              itemCount: songs.length,
              separatorBuilder: (_, _) => const SizedBox(width: KgSpacing.sm),
              itemBuilder: (context, index) => _HomeSongCard(
                song: songs[index],
                width: cardWidth,
                onTap: () => onSongTap(songs[index]),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class HomeSongShelfSkeleton extends StatelessWidget {
  const HomeSongShelfSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cardWidth = constraints.maxWidth >= KgBreakpoints.mediumWidth
          ? 164.0
          : 142.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KgSkeleton(width: 180, height: 24, radius: KgRadii.small),
          const SizedBox(height: KgSpacing.md),
          SizedBox(
            height: _shelfHeight(context, cardWidth),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: Directionality.of(context) == TextDirection.rtl,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: KgSpacing.sm),
              itemBuilder: (_, _) => SizedBox(
                width: cardWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KgSkeleton(
                      width: cardWidth,
                      height: cardWidth,
                      radius: KgRadii.medium,
                    ),
                    const SizedBox(height: 8),
                    KgSkeleton(
                      width: cardWidth * 0.78,
                      height: 14,
                      radius: KgRadii.small,
                    ),
                    const SizedBox(height: 7),
                    KgSkeleton(
                      width: cardWidth * 0.45,
                      height: 10,
                      radius: KgRadii.small,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _HomeSongCard extends StatelessWidget {
  const _HomeSongCard({
    required this.song,
    required this.width,
    required this.onTap,
  });

  final Song song;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Semantics(
      button: true,
      label: '播放 ${song.title}',
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SongArtwork(
                url: song.artworkUrl,
                cacheId: 'song:${song.id}',
                size: width,
                radius: KgRadii.medium,
              ),
              const SizedBox(height: 7),
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                song.artistLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: KgColors.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(KgRadii.medium),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('home-song:${song.id}'),
                onTap: onTap,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Reserve space for scaled labels without constraining the page text scale.
double _shelfHeight(BuildContext context, double coverSize) {
  final scaler = MediaQuery.textScalerOf(context);
  return coverSize + 12 + scaler.scale(14) * 1.5 + scaler.scale(12) * 1.4;
}
