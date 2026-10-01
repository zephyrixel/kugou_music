import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/app_router.dart';
import 'package:kgmusic/app/notification_navigation_controller.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
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
    builder: (context, child) {
      final content = AppErrorListener(
        bus: ref.watch(appErrorBusProvider),
        messengerKey: _scaffoldMessengerKey,
        child: child ?? const SizedBox.shrink(),
      );
      if (!_supportsDesktopShortcuts) return content;
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): _togglePlayback,
          const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
              _previous,
          const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
              _next,
          const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
              _navigate('/'),
          const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
              _navigate('/search'),
          const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
              _navigate('/library'),
        },
        child: content,
      );
    },
  );

  bool get _supportsDesktopShortcuts =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows);

  bool get _editingText {
    final context = FocusManager.instance.primaryFocus?.context;
    return context != null &&
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _togglePlayback() {
    if (_editingText) return;
    final handler = ref.read(audioHandlerProvider);
    final playing = handler.playbackState.value.playing;
    unawaited(playing ? handler.pause() : handler.play());
  }

  void _previous() {
    if (!_editingText) {
      unawaited(ref.read(audioHandlerProvider).skipToPrevious());
    }
  }

  void _next() {
    if (!_editingText) unawaited(ref.read(audioHandlerProvider).skipToNext());
  }

  void _navigate(String location) {
    if (!_editingText) _router.go(location);
  }
}
