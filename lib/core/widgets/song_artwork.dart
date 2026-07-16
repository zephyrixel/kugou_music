import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kgmusic/core/cache/artwork_cache.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';

class SongArtwork extends StatelessWidget {
  const SongArtwork({
    super.key,
    this.url,
    this.cacheId,
    this.size = 52,
    this.radius = 14,
  });

  final String? url;
  final String? cacheId;
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
          colors: [Color(0xFF303653), Color(0xFF12141D)],
        ),
      ),
      child: const Icon(Icons.graphic_eq_rounded, color: KgColors.accent),
    );
    final localUri = Uri.tryParse(url ?? '');
    if (localUri?.scheme == 'file') {
      final file = File.fromUri(localUri!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder,
        ),
      );
    }
    if (imageUrl == null) return placeholder;
    final pixelSize = (size * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(240, 1080);
    final cacheKey = ArtworkCacheService.instance.cacheKey(
      url: imageUrl,
      cacheId: cacheId,
      pixelSize: pixelSize,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        key: ValueKey(cacheKey),
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheManager: ArtworkCacheService.instance.manager,
        cacheKey: cacheKey,
        memCacheWidth: pixelSize,
        memCacheHeight: pixelSize,
        maxWidthDiskCache: pixelSize,
        maxHeightDiskCache: pixelSize,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}
