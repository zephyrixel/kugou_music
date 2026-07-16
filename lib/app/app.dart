import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/app_error_bus.dart';
import 'package:kgmusic/features/account/account_screen.dart';
import 'package:kgmusic/features/auth/auth_gate.dart';
import 'package:kgmusic/features/home/home_screen.dart';
import 'package:kgmusic/features/library/library_screen.dart';
import 'package:kgmusic/features/library/library_collection_screen.dart';
import 'package:kgmusic/features/player/mini_player.dart';
import 'package:kgmusic/features/player/player_screen.dart';
import 'package:kgmusic/features/playlists/playlist_detail_screen.dart';
import 'package:kgmusic/features/search/search_screen.dart';

class KgMusicApp extends ConsumerStatefulWidget {
  const KgMusicApp({super.key});

  @override
  ConsumerState<KgMusicApp> createState() => _KgMusicAppState();
}

class _KgMusicAppState extends ConsumerState<KgMusicApp> {
  late final GoRouter _router = GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (_, _) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: 'favorites',
                    builder: (_, _) => const LibraryCollectionScreen(
                      kind: LibraryCollectionKind.favorites,
                    ),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (_, _) => const LibraryCollectionScreen(
                      kind: LibraryCollectionKind.history,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/account',
        pageBuilder: (_, state) =>
            _fadeThroughPage(state: state, child: const AccountScreen()),
      ),
      GoRoute(
        path: '/player',
        pageBuilder: (_, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: KgMotion.slow,
          reverseTransitionDuration: KgMotion.medium,
          child: const PlayerScreen(),
          transitionsBuilder: (context, animation, secondary, child) {
            if (MediaQuery.disableAnimationsOf(context)) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: KgMotion.emphasized,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.035),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/playlist',
        pageBuilder: (_, state) => _fadeThroughPage(
          state: state,
          child: PlaylistDetailScreen(source: state.extra!),
        ),
      ),
    ],
  );
  StreamSubscription<bool>? _notificationClickSubscription;

  @override
  void initState() {
    super.initState();
    _notificationClickSubscription = AudioService.notificationClicked
        .where((clicked) => clicked)
        .listen((_) => _openNotificationTarget());
  }

  void _openNotificationTarget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final handler = ref.read(audioHandlerProvider);
      final target = handler.mediaItem.value == null ? '/' : '/player';
      if (_router.routeInformationProvider.value.uri.path != target) {
        if (target == '/player') {
          _router.push(target);
        } else {
          _router.go(target);
        }
      }
    });
  }

  @override
  void dispose() {
    unawaited(_notificationClickSubscription?.cancel());
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'KGMusic',
    debugShowCheckedModeBanner: false,
    theme: buildKgTheme(),
    routerConfig: _router,
    builder: (context, child) => AppErrorListener(
      bus: ref.watch(appErrorBusProvider),
      child: AuthGate(child: child ?? const SizedBox.shrink()),
    ),
  );
}

CustomTransitionPage<void> _fadeThroughPage({
  required GoRouterState state,
  required Widget child,
}) => CustomTransitionPage<void>(
  key: state.pageKey,
  transitionDuration: KgMotion.medium,
  reverseTransitionDuration: KgMotion.fast,
  child: child,
  transitionsBuilder: (context, animation, secondary, child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = CurvedAnimation(parent: animation, curve: KgMotion.standard);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: 0.985, end: 1.0).animate(curved),
        child: child,
      ),
    );
  },
);

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore_rounded),
      label: '发现',
    ),
    NavigationDestination(icon: Icon(Icons.search_rounded), label: '搜索'),
    NavigationDestination(
      icon: Icon(Icons.library_music_outlined),
      selectedIcon: Icon(Icons.library_music_rounded),
      label: '音乐库',
    ),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= KgBreakpoints.navigationRail) {
        return _WideShell(navigationShell: navigationShell);
      }
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: KgMotion.resolve(context, KgMotion.medium),
              curve: KgMotion.standard,
              alignment: Alignment.bottomCenter,
              child: const MiniPlayer(),
            ),
            NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              destinations: destinations,
            ),
          ],
        ),
      );
    },
  );

  void _goBranch(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );
}

class _WideShell extends StatelessWidget {
  const _WideShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            labelType: NavigationRailLabelType.all,
            backgroundColor: KgColors.surface,
            groupAlignment: -0.7,
            leading: const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 24),
              child: Icon(
                Icons.graphic_eq_rounded,
                color: KgColors.accent,
                size: 30,
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: Text('发现'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search_rounded),
                label: Text('搜索'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music_rounded),
                label: Text('音乐库'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(child: navigationShell),
                AnimatedSize(
                  duration: KgMotion.resolve(context, KgMotion.medium),
                  curve: KgMotion.standard,
                  alignment: Alignment.bottomCenter,
                  child: const MiniPlayer(),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
