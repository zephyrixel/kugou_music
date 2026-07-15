import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class PlaylistHeader extends StatelessWidget {
  const PlaylistHeader({
    super.key,
    required this.title,
    required this.artwork,
    required this.cacheId,
    required this.count,
  });

  final String title;
  final String? artwork;
  final String cacheId;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [KgColors.elevatedHigh, KgColors.surface],
      ),
    ),
    child: Row(
      children: [
        SongArtwork(url: artwork, cacheId: cacheId, size: 108, radius: 22),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.music_note_rounded,
                    size: 16,
                    color: KgColors.accent,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count 首歌曲',
                    style: const TextStyle(color: KgColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
