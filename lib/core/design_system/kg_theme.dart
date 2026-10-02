import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/kg_motion.dart';

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
  static const borderSubtle = Color(0x14FFFFFF);
  static const borderHighlight = Color(0x24FFFFFF);
  static const hover = Color(0x0AFFFFFF);
  static const pressed = Color(0x14E7B36A);
  static const focus = Color(0x29E7B36A);
  static const selected = Color(0x1FE7B36A);
  static const disabled = Color(0x61F5F2EB);
  static const warning = Color(0xFFF1CE86);
  static const error = Color(0xFFFFA59A);
}

/// Translucent ink decorations keep press/focus feedback above the surface.
abstract final class KgGradients {
  static const surface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x09FFFFFF), Color(0x00FFFFFF)],
  );
  static const warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x24E7B36A), Color(0x08E7B36A), Color(0x00E7B36A)],
  );
  static const selected = LinearGradient(
    colors: [Color(0x2BE7B36A), Color(0x0CE7B36A)],
  );
  static const button = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x24FFFFFF), Color(0x00FFFFFF), Color(0x08000000)],
  );
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
    hoverColor: KgColors.hover,
    focusColor: KgColors.focus,
    splashColor: KgColors.pressed,
    highlightColor: const Color(0x08FFFFFF),
    disabledColor: KgColors.disabled,
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
      labelPadding: const EdgeInsets.only(top: 4),
      overlayColor: _controlOverlay(KgColors.accent),
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
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? KgColors.elevated
            : KgColors.surface,
      ),
      hintStyle: const TextStyle(color: KgColors.textMuted, fontSize: 14),
      labelStyle: const TextStyle(color: KgColors.textMuted, fontSize: 14),
      helperStyle: const TextStyle(color: KgColors.textMuted, height: 1.4),
      errorStyle: const TextStyle(color: KgColors.error, height: 1.4),
      errorMaxLines: 3,
      prefixIconColor: KgColors.textMuted,
      suffixIconColor: KgColors.textMuted,
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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
        borderSide: const BorderSide(color: KgColors.borderHighlight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
        borderSide: const BorderSide(color: KgColors.accent, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
        borderSide: const BorderSide(color: KgColors.borderSubtle),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
        borderSide: const BorderSide(color: KgColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
        borderSide: const BorderSide(color: KgColors.error, width: 1.4),
      ),
    ),
    cardTheme: CardThemeData(
      color: KgColors.elevated,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KgRadii.large),
        side: const BorderSide(color: KgColors.borderSubtle),
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
      color: KgColors.borderSubtle,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            disabledForegroundColor: KgColors.disabled,
            disabledBackgroundColor: KgColors.elevatedHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KgRadii.medium),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ).copyWith(
            overlayColor: _controlOverlay(KgColors.onAccent),
            foregroundBuilder: _buttonFeedback,
            backgroundBuilder: _buttonSheen,
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            foregroundColor: KgColors.textPrimary,
            disabledForegroundColor: KgColors.disabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KgRadii.medium),
            ),
          ).copyWith(
            overlayColor: _controlOverlay(KgColors.accent),
            foregroundBuilder: _buttonFeedback,
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.focused)
                    ? KgColors.accent
                    : states.contains(WidgetState.disabled)
                    ? KgColors.borderSubtle
                    : KgColors.borderHighlight,
              ),
            ),
          ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style:
          IconButton.styleFrom(
            minimumSize: const Size.square(48),
            foregroundColor: KgColors.textPrimary,
            disabledForegroundColor: KgColors.disabled,
          ).copyWith(
            overlayColor: _controlOverlay(KgColors.accent),
            foregroundBuilder: _buttonFeedback,
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style:
          TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            disabledForegroundColor: KgColors.disabled,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ).copyWith(
            overlayColor: _controlOverlay(KgColors.accent),
            foregroundBuilder: _buttonFeedback,
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
      dragHandleColor: KgColors.borderHighlight,
      dragHandleSize: Size(32, 4),
      modalBarrierColor: Color(0x99000000),
      constraints: BoxConstraints(maxWidth: 560),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(KgRadii.hero)),
        side: BorderSide(color: KgColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: KgColors.elevated,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: KgColors.textPrimary,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: KgColors.textMuted,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KgRadii.large),
        side: const BorderSide(color: KgColors.borderHighlight),
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
      elevation: 4,
      insetPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
        side: const BorderSide(color: KgColors.borderHighlight),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: KgColors.accent,
      inactiveTrackColor: KgColors.divider,
      secondaryActiveTrackColor: Color(0x60FFFFFF),
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
      elevation: 6,
      menuPadding: const EdgeInsets.symmetric(vertical: 8),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 14,
          height: 1.4,
          color: states.contains(WidgetState.disabled)
              ? KgColors.disabled
              : KgColors.textPrimary,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
        side: const BorderSide(color: KgColors.borderHighlight),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      textStyle: const TextStyle(fontSize: 12, color: KgColors.textPrimary),
      decoration: BoxDecoration(
        color: KgColors.elevatedHigh,
        borderRadius: BorderRadius.circular(KgRadii.small),
        border: Border.all(color: KgColors.borderHighlight),
      ),
    ),
    switchTheme: SwitchThemeData(
      overlayColor: _controlOverlay(KgColors.accent),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : KgColors.borderHighlight,
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      expansionAnimationStyle: const AnimationStyle(
        duration: KgMotion.medium,
        curve: KgMotion.standard,
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      iconColor: KgColors.accent,
      collapsedIconColor: KgColors.textMuted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KgRadii.medium),
      ),
      clipBehavior: Clip.antiAlias,
    ),
  );
}

Widget _buttonFeedback(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) => KgPressFeedback(states: states, child: child ?? const SizedBox.shrink());

Widget _buttonSheen(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) => Ink(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(KgRadii.medium),
    gradient: states.contains(WidgetState.disabled) ? null : KgGradients.button,
  ),
  child: child,
);

WidgetStateProperty<Color?> _controlOverlay(Color color) =>
    WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return Colors.transparent;
      if (states.contains(WidgetState.focused)) {
        return color.withValues(alpha: 0.18);
      }
      if (states.contains(WidgetState.pressed)) {
        return color.withValues(alpha: 0.12);
      }
      if (states.contains(WidgetState.hovered)) {
        return color.withValues(alpha: 0.06);
      }
      return null;
    });
