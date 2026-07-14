import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';

class SongArtwork extends StatelessWidget {
  const SongArtwork({super.key, this.url, this.size = 52, this.radius = 14});

  final String? url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = normalizeArtworkUrl(
      url,
      size: (size * MediaQuery.devicePixelRatioOf(context)).round().clamp(
        240,
        1080,
      ),
    );
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF263128), Color(0xFF101511)],
        ),
      ),
      child: const Icon(Icons.graphic_eq_rounded, color: KgColors.accent),
    );
    if (imageUrl == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        key: ValueKey(imageUrl),
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}
