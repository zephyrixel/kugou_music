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

abstract final class KgMotion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 320);
  static const playerEnter = Duration(milliseconds: 420);
  static const ambient = Duration(seconds: 12);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  static Duration resolve(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
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
