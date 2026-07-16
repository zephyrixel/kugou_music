import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';

/// A restrained translucent surface shared by immersive UI elements.
class KgGlassSurface extends StatelessWidget {
  const KgGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.color,
    this.borderColor,
    this.blurSigma = 18,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final Color? color;
  final Color? borderColor;
  final double blurSigma;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? KgColors.surface.withValues(alpha: 0.68),
      borderRadius: borderRadius,
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.08),
      ),
    );
    final surface = DecoratedBox(decoration: decoration, child: child);
    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      child: blurSigma <= 0
          ? surface
          : BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: surface,
            ),
    );
  }
}
