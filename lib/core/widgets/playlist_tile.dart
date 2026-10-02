import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class PlaylistTile extends StatelessWidget {
  const PlaylistTile({
    super.key,
    required this.title,
    required this.cacheId,
    required this.onTap,
    this.artworkUrl,
    this.subtitle,
    this.badge,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final String? artworkUrl;
  final String cacheId;
  final String? badge;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(KgRadii.medium),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      enabled: enabled,
      minTileHeight: 76,
      horizontalTitleGap: KgSpacing.sm,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
      ),
      onTap: enabled ? onTap : null,
      leading: Hero(
        tag: 'playlist-artwork:$cacheId',
        child: SongArtwork(
          url: artworkUrl,
          cacheId: cacheId,
          size: 56,
          radius: 12,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: enabled ? KgColors.textPrimary : KgColors.disabled,
        ),
      ),
      subtitle: subtitle == null && badge == null
          ? null
          : Text(
              [?badge, ?subtitle].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: enabled ? KgColors.textMuted : KgColors.disabled,
              ),
            ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: enabled ? KgColors.textMuted : KgColors.disabled,
      ),
    ),
  );
}
