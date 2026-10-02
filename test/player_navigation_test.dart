import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/notification_navigation_controller.dart';
import 'package:kgmusic/app/player_navigation.dart';

void main() {
  testWidgets(
    'pending player requests coalesce even during an async redirect',
    (tester) async {
      final redirect = Completer<String?>();
      final router = _router(
        redirect: (_, state) =>
            state.matchedLocation == '/player' ? redirect.future : null,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      openPlayer(router);
      openPlayer(router);
      await tester.pump();
      openPlayer(router);
      redirect.complete(null);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.matches, hasLength(2));
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('首页'), findsOneWidget);
    },
  );

  testWidgets('redirected requests do not prevent a later valid opening', (
    tester,
  ) async {
    var allow = false;
    final router = _router(
      redirect: (_, state) =>
          !allow && state.matchedLocation == '/player' ? '/' : null,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    openPlayer(router);
    await tester.pumpAndSettle();
    expect(find.text('播放器'), findsNothing);
    allow = true;
    openPlayer(router);
    await tester.pumpAndSettle();
    expect(find.text('播放器'), findsOneWidget);
  });

  testWidgets('notification and dock share one pending player request', (
    tester,
  ) async {
    final router = _router();
    final notifications = NotificationNavigationController(
      router: router,
      hasMediaItem: () => true,
      isMounted: () => true,
    );
    addTearDown(router.dispose);
    addTearDown(notifications.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    for (final notificationFirst in [false, true]) {
      if (notificationFirst) notifications.openNotificationTarget();
      openPlayer(router);
      if (!notificationFirst) notifications.openNotificationTarget();
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.matches, hasLength(2));
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('首页'), findsOneWidget);
    }
  });
}

GoRouter _router({GoRouterRedirect? redirect}) => GoRouter(
  redirect: redirect,
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const Scaffold(body: Text('首页')),
    ),
    GoRoute(
      path: '/player',
      builder: (_, _) => const Scaffold(body: Text('播放器')),
    ),
  ],
);
