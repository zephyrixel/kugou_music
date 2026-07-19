import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';

enum BootstrapFailureKind { nativeRuntime, audio, secureStorage, database, app }

class BootstrapFailure {
  const BootstrapFailure(this.kind);

  final BootstrapFailureKind kind;

  String get title => switch (kind) {
    BootstrapFailureKind.nativeRuntime => 'Native runtime unavailable',
    BootstrapFailureKind.audio => 'Audio system unavailable',
    BootstrapFailureKind.secureStorage => 'Secure storage unavailable',
    BootstrapFailureKind.database => 'Local database unavailable',
    BootstrapFailureKind.app => 'KGMusic could not start',
  };

  String get message => switch (kind) {
    BootstrapFailureKind.nativeRuntime =>
      'The KGMusic native component could not be loaded. Reinstall the application and try again.',
    BootstrapFailureKind.audio =>
      'The desktop audio backend could not be initialized. Check the system audio service and restart KGMusic.',
    BootstrapFailureKind.secureStorage =>
      'KGMusic could not access the system credential store. Unlock or configure it, then restart the application.',
    BootstrapFailureKind.database =>
      'KGMusic could not open its local data. Check available disk space and file permissions.',
    BootstrapFailureKind.app =>
      'An unexpected startup error occurred. Restart KGMusic or reinstall it if the problem continues.',
  };
}

class BootstrapFailureApp extends StatelessWidget {
  const BootstrapFailureApp({super.key, required this.failure});

  final BootstrapFailure failure;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'KGMusic',
    debugShowCheckedModeBanner: false,
    theme: buildKgTheme(),
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 52),
                  const SizedBox(height: 20),
                  Text(
                    failure.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    failure.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
