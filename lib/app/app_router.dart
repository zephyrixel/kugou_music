import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/animated_branch_container.dart';
import 'package:kgmusic/app/app_shell.dart';
import 'package:kgmusic/app/delegated_transition_page.dart';
import 'package:kgmusic/app/navigation_focus_policy.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/features/account/account_screen.dart';
import 'package:kgmusic/features/auth/auth_controller.dart';
import 'package:kgmusic/features/auth/auth_route_policy.dart';
import 'package:kgmusic/features/auth/launch_placeholder.dart';
import 'package:kgmusic/features/auth/login_screen.dart';
import 'package:kgmusic/features/home/home_screen.dart';
import 'package:kgmusic/features/library/library_collection_screen.dart';
import 'package:kgmusic/features/library/library_screen.dart';
import 'package:kgmusic/features/logging/log_settings_screen.dart';
import 'package:kgmusic/features/player/player_screen.dart';
import 'package:kgmusic/features/playlists/playlist_detail_screen.dart';
import 'package:kgmusic/features/search/search_screen.dart';

GoRouter createAppRouter(AuthController auth) => GoRouter(
  refreshListenable: auth,
  redirect: (context, state) => authRedirect(
    status: auth.status,
    authenticated: auth.authenticated,
    location: state.matchedLocation,
  ),
  observers: [KeyboardDismissNavigatorObserver()],
  routes: [
    GoRoute(path: '/launch', builder: (_, _) => const LaunchPlaceholder()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    StatefulShellRoute(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
      branches: [
        StatefulShellBranch(
          observers: [KeyboardDismissNavigatorObserver()],
          routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
        ),
        StatefulShellBranch(
          observers: [KeyboardDismissNavigatorObserver()],
          routes: [
            GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
          ],
        ),
        StatefulShellBranch(
          observers: [KeyboardDismissNavigatorObserver()],
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
      path: '/account/logs',
      pageBuilder: (_, state) =>
          _fadeThroughPage(state: state, child: const LogSettingsScreen()),
    ),
    GoRoute(
      path: '/player',
      pageBuilder: (_, state) => PlayerTransitionPage<void>(
        key: state.pageKey,
        child: const PlayerScreen(),
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
