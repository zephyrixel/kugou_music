import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class ArtworkBackdrop extends StatelessWidget {
  const ArtworkBackdrop({
    super.key,
    required this.url,
    required this.cacheId,
    this.blur = 34,
    this.opacity = 0.52,
    this.scrim = 0.48,
  });

  final String? url;
  final String cacheId;
  final double blur;
  final double opacity;
  final double scrim;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: KgMotion.resolve(context, KgMotion.slow),
          switchInCurve: KgMotion.standard,
          switchOutCurve: Curves.easeInCubic,
          child: LayoutBuilder(
            key: ValueKey(cacheId),
            builder: (context, constraints) {
              final size = constraints.biggest.longestSide;
              return Opacity(
                opacity: opacity,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Transform.scale(
                    scale: 1.16,
                    child: Center(
                      child: SongArtwork(
                        url: url,
                        cacheId: cacheId,
                        size: size,
                        radius: 0,
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
            gradient: LinearGradient(
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
  );
}
