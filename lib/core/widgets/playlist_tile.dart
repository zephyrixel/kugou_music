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
    leading: SongArtwork(
      url: artworkUrl,
      cacheId: cacheId,
      size: 56,
      radius: 16,
    ),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: subtitle == null
        ? null
        : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (badge != null)
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: KgColors.accentSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: KgColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const Icon(Icons.chevron_right_rounded, size: 20),
      ],
    ),
  );
}
