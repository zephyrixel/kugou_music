import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

enum SongTileVariant { artwork, indexed, compact }

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.index,
    this.trailing,
    this.variant,
  });

  final Song song;
  final VoidCallback onTap;
  final int? index;
  final Widget? trailing;
  final SongTileVariant? variant;

  @override
  Widget build(BuildContext context) {
    final style =
        variant ??
        (index == null ? SongTileVariant.artwork : SongTileVariant.indexed);
    assert(style != SongTileVariant.indexed || index != null);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KgSpacing.xs),
      child: ListTile(
        minTileHeight: style == SongTileVariant.compact ? 58 : 68,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KgSpacing.sm,
          vertical: 3,
        ),
        horizontalTitleGap: KgSpacing.sm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KgRadii.medium),
        ),
        hoverColor: KgColors.elevated,
        splashColor: KgColors.accent.withValues(alpha: 0.08),
        onTap: onTap,
        leading: switch (style) {
          SongTileVariant.artwork => SongArtwork(
            url: song.artworkUrl,
            cacheId: 'song:${song.id}',
          ),
          SongTileVariant.indexed => SizedBox(
            width: 32,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: index! <= 3 ? KgColors.accent : KgColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SongTileVariant.compact => null,
        },
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
      ),
    );
  }
}
