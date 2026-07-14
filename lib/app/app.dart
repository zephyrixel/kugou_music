import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/features/home/home_screen.dart';
import 'package:kgmusic/features/library/library_screen.dart';
import 'package:kgmusic/features/player/mini_player.dart';
import 'package:kgmusic/features/player/player_screen.dart';
import 'package:kgmusic/features/search/search_screen.dart';

class KgMusicApp extends StatelessWidget {
  KgMusicApp({super.key});

  final GoRouter _router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            _AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
        ],
      ),
      GoRoute(path: '/player', builder: (_, _) => const PlayerScreen()),
    ],
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'KGMusic',
    debugShowCheckedModeBanner: false,
    theme: buildKgTheme(),
    routerConfig: _router,
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
            ],
          ),
        ],
      ),
    );
  }
}
