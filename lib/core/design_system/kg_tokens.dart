import 'package:flutter/material.dart';

abstract final class KgSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 36.0;
}

abstract final class KgRadii {
  static const small = 10.0;
  static const medium = 16.0;
  static const large = 22.0;
  static const hero = 30.0;
  static const pill = 999.0;
}

abstract final class KgMotion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 360);

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
