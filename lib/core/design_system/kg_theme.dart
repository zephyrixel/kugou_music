import 'package:flutter/material.dart';

import 'package:kgmusic/core/design_system/kg_tokens.dart';

abstract final class KgColors {
  static const background = Color(0xFF090A0F);
  static const surface = Color(0xFF11131A);
  static const elevated = Color(0xFF181B24);
  static const elevatedHigh = Color(0xFF222633);
  static const accent = Color(0xFFAEB8FF);
  static const accentSecondary = Color(0xFF78D7FF);
  static const accentSoft = Color(0xFF292E4A);
  static const textPrimary = Color(0xFFF4F5F8);
  static const textMuted = Color(0xFF9BA3B4);
  static const divider = Color(0xFF2A2E39);
  static const warning = Color(0xFFFFC46B);
}

ThemeData buildKgTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: KgColors.accent,
        brightness: Brightness.dark,
        surface: KgColors.surface,
      ).copyWith(
        primary: KgColors.accent,
        onPrimary: const Color(0xFF15182A),
        secondary: KgColors.accentSecondary,
        onSecondary: const Color(0xFF071A22),
        surface: KgColors.surface,
        surfaceContainer: KgColors.elevated,
        surfaceContainerHigh: KgColors.elevatedHigh,
        outlineVariant: KgColors.divider,
      );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: KgColors.background,
    colorScheme: scheme,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        color: KgColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: KgColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.45,
        color: KgColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w700,
        color: KgColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w700,
        color: KgColors.textPrimary,
      ),
      bodyLarge: TextStyle(height: 1.4, color: KgColors.textPrimary),
      bodyMedium: TextStyle(height: 1.4, color: KgColors.textPrimary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      backgroundColor: KgColors.surface.withValues(alpha: 0.98),
      indicatorColor: KgColors.accentSoft,
      elevation: 0,
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KgSpacing.md,
        vertical: KgSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
        borderSide: const BorderSide(color: KgColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
        borderSide: const BorderSide(color: KgColors.accent, width: 1.4),
      ),
    ),
    cardTheme: CardThemeData(
      color: KgColors.elevated,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KgRadii.large),
      ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KgRadii.medium),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KgRadii.medium),
        ),
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
      modalBarrierColor: Color(0x99000000),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: KgColors.elevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KgRadii.large),
      ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: KgColors.accent,
      inactiveTrackColor: KgColors.divider,
      thumbColor: KgColors.accent,
      overlayColor: Color(0x28AEB8FF),
      trackHeight: 3,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: KgColors.accent,
      linearTrackColor: KgColors.divider,
      circularTrackColor: KgColors.divider,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: KgColors.elevatedHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
      ),
    ),
  );
}
