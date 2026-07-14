import 'package:flutter/material.dart';
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    horizontalTitleGap: 12,
    onTap: onTap,
    leading: index == null
        ? SongArtwork(url: song.artworkUrl)
        : SizedBox(
            width: 32,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
    title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
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
