import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

/// A soft artwork backdrop isolated as a retained layer for smooth foreground
/// scrolling. Player route transitions snapshot this layer while animating.
class ArtworkBackdrop extends StatelessWidget {
  const ArtworkBackdrop({
    super.key,
    required this.url,
    required this.cacheId,
    this.opacity = 0.52,
    this.scrim = 0.48,
    this.overlayGradient,
    this.sourceSize,
    this.decodePixelSize = 320,
    this.blurSigma = 34,
  });

  final String? url;
  final String cacheId;
  final double opacity;
  final double scrim;
  final Gradient? overlayGradient;
  final double? sourceSize;
  final int decodePixelSize;
  final double blurSigma;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: KgMotion.resolve(context, KgMotion.slow),
            switchInCurve: KgMotion.standard,
            switchOutCurve: Curves.easeInCubic,
            child: LayoutBuilder(
              key: ValueKey('$cacheId:${url ?? ''}'),
              builder: (context, constraints) {
                final size = constraints.biggest.longestSide;
                final artworkSize = sourceSize ?? size;
                final scale = size <= 0 || artworkSize <= 0
                    ? 1.16
                    : 1.16 * size / artworkSize;
                return Opacity(
                  opacity: opacity,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: Transform.scale(
                      scale: scale,
                      child: Center(
                        child: SongArtwork(
                          url: url,
                          cacheId: cacheId,
                          size: artworkSize,
                          radius: 0,
                          decodePixelSize: decodePixelSize,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient:
                  overlayGradient ??
                  LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      KgColors.background.withValues(alpha: scrim * 0.62),
                      KgColors.background.withValues(alpha: scrim),
                    ],
                  ),
            ),
          ),
        ],
      ),
    ),
  );
}
