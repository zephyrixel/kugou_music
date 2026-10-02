import 'package:flutter/material.dart';

abstract final class KgSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 32.0;
}

abstract final class KgRadii {
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 20.0;
  static const hero = 24.0;
  static const pill = 999.0;
}

abstract final class KgShadows {
  static const floating = [
    BoxShadow(color: Color(0x38000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x18000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const artwork = [
    BoxShadow(color: Color(0x38000000), blurRadius: 28, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x20000000), blurRadius: 8, offset: Offset(0, 3)),
  ];
}

abstract final class KgMotion {
  static const press = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 320);
  static const selection = Duration(milliseconds: 280);
  static const navigation = Duration(milliseconds: 240);
  static const pageEnter = Duration(milliseconds: 300);
  static const pageExit = Duration(milliseconds: 220);
  static const sheetEnter = Duration(milliseconds: 360);
  static const sheetExit = Duration(milliseconds: 240);
  static const dialogEnter = Duration(milliseconds: 240);
  static const dialogExit = Duration(milliseconds: 180);
  static const menuEnter = Duration(milliseconds: 180);
  static const menuExit = Duration(milliseconds: 140);
  static const playerEnter = Duration(milliseconds: 420);
  static const ambient = Duration(seconds: 12);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve rebound = Curves.easeOutBack;

  static Duration resolve(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

  static AnimationStyle menuStyle(BuildContext context) => AnimationStyle(
    duration: resolve(context, menuEnter),
    reverseDuration: resolve(context, menuExit),
    curve: standard,
    reverseCurve: Curves.easeInCubic,
  );
}

abstract final class KgBreakpoints {
  static const compactHeight = 650.0;
  static const mediumWidth = 600.0;
  static const navigationRail = 840.0;
  static const contentMaxWidth = 1180.0;
  static const readingMaxWidth = 760.0;
}

abstract final class KgNavigation {
  static const barHeight = 64.0;

  static double railWidthOf(BuildContext context) =>
      (MediaQuery.textScalerOf(context).scale(12) * 2 + 32).clamp(
        80.0,
        double.infinity,
      );
}
