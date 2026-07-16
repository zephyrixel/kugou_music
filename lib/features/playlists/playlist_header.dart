import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/artwork_backdrop.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class PlaylistHeader extends StatelessWidget {
  const PlaylistHeader({
    super.key,
    required this.title,
    required this.artwork,
    required this.cacheId,
    required this.count,
    this.subtitle,
    this.description,
  });

  final String title;
  final String? subtitle;
  final String? description;
  final String? artwork;
  final String cacheId;
  final int count;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ArtworkBackdrop(
        url: artwork,
        cacheId: cacheId,
        opacity: 0.68,
        scrim: 0.58,
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x8A090A0F), Color(0x18090A0F), Color(0xF0090A0F)],
            stops: [0, 0.28, 1],
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KgSpacing.lg,
            72,
            KgSpacing.lg,
            KgSpacing.xl,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Hero(
                tag: 'playlist-artwork:$cacheId',
                child: SongArtwork(
                  url: artwork,
                  cacheId: cacheId,
                  size: 122,
                  radius: KgRadii.large,
                ),
              ),
              const SizedBox(width: KgSpacing.lg),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (subtitle?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '$count 首歌曲',
                      style: const TextStyle(
                        color: KgColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: KgColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
