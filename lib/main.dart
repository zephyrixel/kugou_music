import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kgmusic/app/app.dart';
import 'package:kgmusic/app/app_runtime.dart';
import 'package:kgmusic/app/bootstrap_failure.dart';
import 'package:kgmusic/core/logging/app_log.dart';

Future<void> main() async {
  await runZonedGuarded(_bootstrap, (error, stackTrace) {
    AppLog.error(
      '应用发生未捕获异常',
      target: 'bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20;
  try {
    final runtime = await AppRuntime.create();
    runApp(runtime.provide(const KgMusicApp()));
  } on AppStartupException catch (error) {
    AppLog.error(
      error.failure.title,
      target: 'bootstrap',
      error: error.cause,
      stackTrace: error.stackTrace,
    );
    runApp(BootstrapFailureApp(failure: error.failure));
  } catch (error, stackTrace) {
    AppLog.error(
      '应用启动失败',
      target: 'bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
    runApp(
      const BootstrapFailureApp(
        failure: BootstrapFailure(BootstrapFailureKind.app),
      ),
    );
  }
}
