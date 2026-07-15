import 'package:flutter/material.dart';

abstract final class KgColors {
  static const background = Color(0xFF080B0A);
  static const surface = Color(0xFF111513);
  static const elevated = Color(0xFF1A201D);
  static const elevatedHigh = Color(0xFF222A26);
  static const accent = Color(0xFFB6FF3B);
  static const accentSoft = Color(0xFF26351C);
  static const textMuted = Color(0xFF8F9B94);
  static const divider = Color(0xFF28302C);
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
    splashFactory: InkSparkle.splashFactory,
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
      bodyMedium: TextStyle(height: 1.35),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      color: KgColors.elevated,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: KgColors.textMuted,
      subtitleTextStyle: TextStyle(color: KgColors.textMuted, height: 1.3),
    ),
    dividerTheme: const DividerThemeData(
      color: KgColors.divider,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: KgColors.divider),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size.square(44)),
    ),
    tabBarTheme: const TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorColor: KgColors.accent,
      labelColor: Colors.white,
      unselectedLabelColor: KgColors.textMuted,
      labelStyle: TextStyle(fontWeight: FontWeight.w700),
      indicatorSize: TabBarIndicatorSize.label,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: KgColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: KgColors.elevatedHigh,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      actionTextColor: KgColors.accent,
      closeIconColor: Colors.white,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: KgColors.accent,
      inactiveTrackColor: KgColors.divider,
      thumbColor: KgColors.accent,
      overlayColor: Color(0x24B6FF3B),
      trackHeight: 3,
    ),
  );
}
