import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kgmusic/core/cache/artwork_cache.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';

class SongArtwork extends StatelessWidget {
  const SongArtwork({
    super.key,
    this.url,
    this.cacheId,
    this.size = 48,
    this.radius = KgRadii.medium,
    this.decodePixelSize,
    this.filterQuality = FilterQuality.low,
    this.placeholderIcon = Icons.album_outlined,
  });

  final String? url;
  final String? cacheId;
  final double size;
  final double radius;

  /// Overrides the decoded texture size without changing layout dimensions.
  final int? decodePixelSize;
  final FilterQuality filterQuality;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final requestedSize =
        decodePixelSize?.clamp(64, 1080) ??
        (size * MediaQuery.devicePixelRatioOf(context)).round().clamp(
          240,
          1080,
        );
    // Snap before the size reaches either the URL template or the cache key so
    // every call site for one cover shares a single download and disk entry.
    final pixelSize = ArtworkCacheService.snapPixelSize(requestedSize);
    final imageUrl = normalizeArtworkUrl(url, size: pixelSize);
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KgColors.elevatedHigh, KgColors.surface],
        ),
      ),
      child: Icon(
        placeholderIcon,
        size: (size * 0.36).clamp(16, 40),
        color: KgColors.textMuted,
      ),
    );
    final localUri = Uri.tryParse(url ?? '');
    if (localUri?.scheme == 'file') {
      final file = File.fromUri(localUri!);
      return _frame(
        Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // The player rewrites artUri to the 720px prefetch file, so without
          // this the mini player and backdrop decode it at full resolution.
          cacheWidth: requestedSize,
          filterQuality: filterQuality,
          errorBuilder: (_, _, _) => placeholder,
        ),
      );
    }
    if (imageUrl == null) return _frame(placeholder);
    final cacheKey = ArtworkCacheService.instance.cacheKey(
      url: imageUrl,
      cacheId: cacheId,
      pixelSize: pixelSize,
    );
    return _frame(
      CachedNetworkImage(
        key: ValueKey(cacheKey),
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheManager: ArtworkCacheService.instance.manager,
        cacheKey: cacheKey,
        // Memory-only resize. maxWidth/HeightDiskCache would store a second,
        // PNG re-encoded copy per size against the object-count cap.
        memCacheWidth: requestedSize,
        filterQuality: filterQuality,
        fadeInDuration: KgMotion.resolve(context, KgMotion.medium),
        fadeOutDuration: KgMotion.resolve(context, KgMotion.fast),
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }

  Widget _frame(Widget child) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: KgColors.borderSubtle),
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: child),
  );
}
