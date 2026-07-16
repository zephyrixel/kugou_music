import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

abstract final class AndroidDisplayMode {
  /// Requests the highest refresh rate that keeps the active resolution.
  static Future<void> preferHighestRefreshRate() async {
    if (!Platform.isAndroid) return;
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } on PlatformException {
      // Display mode selection is best-effort and may be rejected by Android.
    } on MissingPluginException {
      // Keeps unsupported build targets and tests safe.
    }
  }
}
