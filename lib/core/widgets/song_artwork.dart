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
    this.decodePixelSize,
    this.filterQuality = FilterQuality.low,
  });

  final String? url;
  final String? cacheId;
  final double size;
  final double radius;

  /// Overrides the decoded texture size without changing layout dimensions.
  final int? decodePixelSize;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final pixelSize =
        decodePixelSize?.clamp(64, 1080) ??
        (size * MediaQuery.devicePixelRatioOf(context)).round().clamp(
          240,
          1080,
        );
    final imageUrl = normalizeArtworkUrl(url, size: pixelSize);
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
          filterQuality: filterQuality,
          errorBuilder: (_, _, _) => placeholder,
        ),
      );
    }
    if (imageUrl == null) return placeholder;
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
        filterQuality: filterQuality,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}
