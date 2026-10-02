import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/app/delegated_transition_page.dart';
import 'package:kgmusic/app/app_shell.dart';
import 'package:kgmusic/app/playback_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/features/player/player_screen.dart';
import 'package:kgmusic/features/player/player_backdrop.dart';
import 'package:kgmusic/features/player/mini_player.dart';

import 'support/player_ui_harness.dart';

void main() {
  testWidgets(
    'ambient motion resumes after a route returns and stops offscreen',
    (tester) async {
      final handler = PlayerUiHandler();
      addTearDown(handler.close);
      await tester.pumpWidget(
        playerUiApp(
          handler: handler,
          home: Scaffold(
            body: PlayerBackdrop(
              handler: handler,
              item: handler.mediaItem.value!,
            ),
          ),
        ),
      );
      await handler.play();
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);

      final navigator = Navigator.of(
        tester.element(find.byType(PlayerBackdrop)),
      );
      final coveringRoute = MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('覆盖页面')),
      );
      navigator.push<void>(coveringRoute);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);

      navigator.pop();
      await tester.pump();
      // Let the route finish without waiting for the intentionally looping motion.
      await tester.pump(coveringRoute.reverseTransitionDuration);
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);

      await handler.pause();
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the dock can appear with reduced motion and yield space to the keyboard',
    (tester) async {
      final handler = PlayerUiHandler();
      addTearDown(handler.close);
      addTearDown(tester.view.resetViewInsets);
      final item = handler.mediaItem.value;
      handler.mediaItem.add(null);
      final router = GoRouter(
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => PlaybackShell(
              location: state.uri.path,
              child: AppShell(navigationShell: shell),
            ),
            branches: [
              for (final path in ['/', '/search', '/library'])
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: path,
                      builder: (_, _) => const Scaffold(body: Text('内容')),
                    ),
                  ],
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        playerUiScope(
          handler: handler,
          child: MaterialApp.router(
            theme: buildKgTheme(),
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      handler.mediaItem.add(item);
      await tester.pumpAndSettle();
      expect(find.byTooltip('播放队列'), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(find.byTooltip('播放队列'), findsNothing);
      expect(handler.mediaItem.value, item);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.byTooltip('播放队列'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'player controls remain usable on small, wide, and large-text screens',
    (tester) async {
      final handler = PlayerUiHandler(
        songs: const [
          Song(
            id: 'long',
            title: '一首很长的歌曲标题 A long song title',
            artist: '歌手名称与其他参与演出的音乐人',
            hashes: AudioHashes(standard: 'hash'),
          ),
        ],
      );
      addTearDown(handler.close);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final configuration in [
        (const Size(320, 568), 1.0),
        (const Size(390, 844), 2.0),
        (const Size(844, 390), 1.0),
        (const Size(1280, 800), 1.0),
      ]) {
        await tester.binding.setSurfaceSize(configuration.$1);
        await tester.pumpWidget(
          playerUiApp(
            handler: handler,
            home: const PlayerScreen(),
            reduceMotion: true,
            textScale: configuration.$2,
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('播放'));
        await tester.tap(find.byTooltip('播放'));
        await tester.pump();
        expect(handler.playCalls, greaterThan(0));
        await handler.pause();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'a cancelled player drag preserves the route and a full drag dismisses it',
    (tester) async {
      final handler = PlayerUiHandler();
      addTearDown(handler.close);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(playerUiApp(handler: handler, home: _Launcher()));
      await tester.tap(find.text('打开播放器'));
      await tester.pumpAndSettle();

      final region = find.byType(PlayerDismissRegion).last;
      final gesture = await tester.startGesture(tester.getCenter(region));
      await gesture.moveBy(const Offset(0, 70));
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(
        Navigator.of(
          tester.element(find.byType(PlayerScreen)),
        ).userGestureInProgress,
        isFalse,
      );

      await tester.drag(region, const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsNothing);
      expect(find.text('打开播放器'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('lyrics and seeking remain usable with reduced motion', (
    tester,
  ) async {
    final handler = PlayerUiHandler();
    addTearDown(handler.close);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      playerUiApp(handler: handler, home: _Launcher(), reduceMotion: true),
    );
    await tester.tap(find.text('打开播放器'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('歌词'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(handler.lastSeek, isNotNull);
    expect(find.byType(PlayerScreen), findsOneWidget);
    await tester.tap(find.byTooltip('收起播放器'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _Launcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Expanded(
          child: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                const PlayerTransitionPage<void>(
                  child: PlayerScreen(),
                ).createRoute(context),
              ),
              child: const Text('打开播放器'),
            ),
          ),
        ),
        const MiniPlayer(),
      ],
    ),
  );
}
