import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';

class LaunchPlaceholder extends StatelessWidget {
  const LaunchPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -0.7),
          radius: 1.2,
          colors: [KgColors.surface, KgColors.background],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq_rounded, size: 48, color: KgColors.accent),
            SizedBox(height: 12),
            Text(
              'KGMusic',
              style: TextStyle(
                color: KgColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
