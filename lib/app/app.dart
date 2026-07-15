import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/features/home/home_screen.dart';
import 'package:kgmusic/features/library/library_screen.dart';
import 'package:kgmusic/features/player/mini_player.dart';
import 'package:kgmusic/features/player/player_screen.dart';
import 'package:kgmusic/features/search/search_screen.dart';
import 'package:kgmusic/features/account/account_screen.dart';
import 'package:kgmusic/features/auth/auth_gate.dart';
import 'package:kgmusic/features/playlists/playlist_detail_screen.dart';
import 'package:kgmusic/core/widgets/app_error_bus.dart';

class KgMusicApp extends ConsumerStatefulWidget {
  const KgMusicApp({super.key});

  @override
  ConsumerState<KgMusicApp> createState() => _KgMusicAppState();
}

class _KgMusicAppState extends ConsumerState<KgMusicApp> {
  late final GoRouter _router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            _AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
          GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
        ],
      ),
      GoRoute(path: '/player', builder: (_, _) => const PlayerScreen()),
      GoRoute(
        path: '/playlist',
        builder: (_, state) => PlaylistDetailScreen(source: state.extra!),
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

class _AppShell extends StatelessWidget {
  const _AppShell({required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final index = switch (location) {
      '/search' => 1,
      '/library' => 2,
      '/account' => 3,
      _ => 0,
    };
    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (next) {
              switch (next) {
                case 0:
                  context.go('/');
                case 1:
                  context.go('/search');
                case 2:
                  context.go('/library');
                case 3:
                  context.go('/account');
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: '推荐',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                label: '搜索',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music_rounded),
                label: '音乐库',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: '我的',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
