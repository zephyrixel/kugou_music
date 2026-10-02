import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kgmusic/core/design_system/kg_tokens.dart';

const kgSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemStatusBarContrastEnforced: false,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: false,
  systemNavigationBarDividerColor: Colors.transparent,
);

abstract final class KgColors {
  static const background = Color(0xFF101012);
  static const surface = Color(0xFF19191C);
  static const elevated = Color(0xFF242427);
  static const elevatedHigh = Color(0xFF2D2D31);
  static const accent = Color(0xFFE7B36A);
  static const onAccent = Color(0xFF241A0D);
  static const accentSecondary = Color(0xFFDAC6A9);
  static const accentSoft = Color(0xFF352B20);
  static const textPrimary = Color(0xFFF5F2EB);
  static const textMuted = Color(0xFFABA8A2);
  static const divider = Color(0xFF353538);
  static const warning = Color(0xFFF1CE86);
  static const error = Color(0xFFFFA59A);
}

ThemeData buildKgTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: KgColors.accent,
        brightness: Brightness.dark,
        surface: KgColors.surface,
      ).copyWith(
        primary: KgColors.accent,
        onPrimary: KgColors.onAccent,
        primaryContainer: KgColors.accentSoft,
        onPrimaryContainer: KgColors.accent,
        secondary: KgColors.accentSecondary,
        onSecondary: KgColors.onAccent,
        secondaryContainer: KgColors.elevated,
        onSecondaryContainer: KgColors.textPrimary,
        onSurface: KgColors.textPrimary,
        onSurfaceVariant: KgColors.textMuted,
        surface: KgColors.surface,
        surfaceContainer: KgColors.elevated,
        surfaceContainerHigh: KgColors.elevatedHigh,
        outlineVariant: KgColors.divider,
        error: KgColors.error,
      );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: KgColors.background,
    colorScheme: scheme,
    splashFactory: InkRipple.splashFactory,
    hoverColor: const Color(0x0DFFFFFF),
    focusColor: KgColors.accent.withValues(alpha: 0.16),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: KgColors.accent,
      selectionColor: KgColors.accent.withValues(alpha: 0.28),
      selectionHandleColor: KgColors.accent,
    ),
    visualDensity: VisualDensity.standard,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0,
        color: KgColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0,
        color: KgColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0,
        color: KgColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: KgColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0,
        color: KgColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: KgColors.textPrimary,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        color: KgColors.textPrimary,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: KgColors.textPrimary,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        color: KgColors.textMuted,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    ),
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: kgSystemUiOverlayStyle,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: KgColors.textPrimary,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: KgColors.surface,
      indicatorColor: KgColors.accentSoft,
      elevation: 0,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 23,
          color: states.contains(WidgetState.selected)
              ? KgColors.accent
              : KgColors.textMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? KgColors.accent
              : KgColors.textMuted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: KgColors.surface,
      indicatorColor: KgColors.accentSoft,
      selectedIconTheme: IconThemeData(color: KgColors.accent, size: 24),
      unselectedIconTheme: IconThemeData(color: KgColors.textMuted, size: 24),
      selectedLabelTextStyle: TextStyle(color: KgColors.accent, fontSize: 12),
      unselectedLabelTextStyle: TextStyle(
        color: KgColors.textMuted,
        fontSize: 12,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KgColors.surface,
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
      textColor: KgColors.textPrimary,
      minTileHeight: 64,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: KgColors.textPrimary,
        height: 1.4,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 13,
        color: KgColors.textMuted,
        height: 1.4,
      ),
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
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        foregroundColor: KgColors.textPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      dividerColor: Colors.transparent,
      indicatorColor: KgColors.accent,
      labelColor: KgColors.textPrimary,
      unselectedLabelColor: KgColors.textMuted,
      labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      indicatorSize: TabBarIndicatorSize.label,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: KgColors.elevated,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      modalBarrierColor: Color(0x99000000),
      constraints: BoxConstraints(maxWidth: 560),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(KgRadii.hero)),
      ),
      clipBehavior: Clip.antiAlias,
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
        color: KgColors.textPrimary,
        fontWeight: FontWeight.w400,
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
      overlayColor: Color(0x28E7B36A),
      trackHeight: 3,
      thumbShape: RoundSliderThumbShape(
        enabledThumbRadius: 5,
        disabledThumbRadius: 4,
      ),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
      trackShape: RoundedRectSliderTrackShape(),
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
