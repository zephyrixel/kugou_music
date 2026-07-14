import 'package:flutter/material.dart';

abstract final class KgColors {
  static const background = Color(0xFF080B0A);
  static const surface = Color(0xFF111513);
  static const elevated = Color(0xFF1A201D);
  static const accent = Color(0xFFB6FF3B);
  static const textMuted = Color(0xFF8F9B94);
}

ThemeData buildKgTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: KgColors.accent,
    brightness: Brightness.dark,
    surface: KgColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: KgColors.background,
    colorScheme: scheme,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: KgColors.surface,
      indicatorColor: KgColors.accent.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? KgColors.accent
              : KgColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KgColors.elevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
