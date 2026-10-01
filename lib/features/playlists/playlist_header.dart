import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked = MediaQuery.textScalerOf(context).scale(14) > 21;
        final cover = Hero(
          tag: 'playlist-artwork:$cacheId',
          child: SongArtwork(
            url: artwork,
            cacheId: cacheId,
            size: constraints.maxWidth < 340 ? 108 : 144,
            radius: KgRadii.medium,
          ),
        );
        final details = Column(
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
              const SizedBox(height: 8),
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: KgColors.textMuted, fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Text('$count 首歌曲', style: Theme.of(context).textTheme.bodySmall),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stacked) ...[
              cover,
              const SizedBox(height: 16),
              details,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  cover,
                  const SizedBox(width: 20),
                  Expanded(child: details),
                ],
              ),
            if (description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: KgColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}
