import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/notification_navigation_controller.dart';

void main() {
  testWidgets('通知连续点击或已在播放器时不会重复压入播放器路由', (tester) async {
    final router = GoRouter(
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
    addTearDown(router.dispose);

    var mounted = true;
    final controller = NotificationNavigationController(
      router: router,
      hasMediaItem: () => true,
      isMounted: () => mounted,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    controller
      ..openNotificationTarget()
      ..openNotificationTarget();
    await tester.pumpAndSettle();
    expect(find.text('播放器'), findsOneWidget);
    expect(router.routerDelegate.state.matchedLocation, '/player');
    // push 路由不会写入 RouteMatchList.uri；旧实现因此始终误判为首页。
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(router.routerDelegate.currentConfiguration.matches, hasLength(2));

    controller.openNotificationTarget();
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.matches, hasLength(2));

    mounted = false;
  });
}
