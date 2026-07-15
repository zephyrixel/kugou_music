import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.index,
    this.trailing,
  });

  final Song song;
  final VoidCallback onTap;
  final int? index;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 68,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
    horizontalTitleGap: 12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    onTap: onTap,
    leading: index == null
        ? SongArtwork(url: song.artworkUrl, cacheId: 'song:${song.id}')
        : SizedBox(
            width: 32,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: index! <= 3 ? KgColors.accent : KgColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
    title: Text(
      song.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      '${song.artistLabel}${song.album == null ? '' : ' · ${song.album}'}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing:
        trailing ??
        (song.durationSecs == null
            ? null
            : Text(formatDuration(Duration(seconds: song.durationSecs!)))),
  );
}
