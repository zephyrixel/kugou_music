import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
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
  Widget build(BuildContext context) => ListTile(
    enabled: enabled,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
    subtitle: subtitle == null
        ? null
        : Text(
            [?badge, subtitle!].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: KgColors.textMuted),
          ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      size: 20,
      color: KgColors.textMuted,
    ),
  );
}
