import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
    child: Row(
      children: [
        SongArtwork(url: artwork, cacheId: cacheId, size: 118, radius: 24),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 9),
              Text('$count 首歌曲'),
            ],
          ),
        ),
      ],
    ),
  );
}

