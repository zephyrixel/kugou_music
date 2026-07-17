import 'package:flutter/foundation.dart';
import 'package:kgmusic/core/logging/app_log.dart';

void installAppLogErrorHandlers() {
  final previousFlutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    AppLog.error(
      details.exceptionAsString(),
      target: 'flutter.framework',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (previousFlutterHandler != null) {
      previousFlutterHandler(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  final previousPlatformHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLog.error(
      '未捕获的异步异常',
      target: 'flutter.platform',
      error: error,
      stackTrace: stackTrace,
    );
    return previousPlatformHandler?.call(error, stackTrace) ?? true;
  };
}
