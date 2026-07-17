import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/app_router.dart';
import 'package:kgmusic/app/notification_navigation_controller.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/platform/android_display_mode.dart';
import 'package:kgmusic/core/widgets/app_error_bus.dart';

class KgMusicApp extends ConsumerStatefulWidget {
  const KgMusicApp({super.key});

  @override
  ConsumerState<KgMusicApp> createState() => _KgMusicAppState();
}

class _KgMusicAppState extends ConsumerState<KgMusicApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late final GoRouter _router;
  StreamSubscription<bool>? _notificationClickSubscription;
  late final NotificationNavigationController _notificationNavigationController;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    _router = createAppRouter(auth);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AndroidDisplayMode.preferHighestRefreshRate());
    });
    _notificationNavigationController = NotificationNavigationController(
      router: _router,
      hasMediaItem: () =>
          ref.read(audioHandlerProvider).mediaItem.value != null,
      isMounted: () => mounted,
    );
    _notificationClickSubscription = AudioService.notificationClicked
        .where((clicked) => clicked)
        .listen((_) {
          _notificationNavigationController.openNotificationTarget();
        });
  }

  @override
  void dispose() {
    unawaited(_notificationClickSubscription?.cancel());
    _notificationNavigationController.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'KGMusic',
    debugShowCheckedModeBanner: false,
    theme: buildKgTheme(),
    scaffoldMessengerKey: _scaffoldMessengerKey,
    routerConfig: _router,
    builder: (context, child) => AppErrorListener(
      bus: ref.watch(appErrorBusProvider),
      messengerKey: _scaffoldMessengerKey,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
