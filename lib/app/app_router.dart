import 'package:flutter/material.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/animated_branch_container.dart';
import 'package:kgmusic/app/app_shell.dart';
import 'package:kgmusic/app/playback_shell.dart';
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
import 'package:kgmusic/features/settings/settings_screen.dart';

GoRouter createAppRouter(AuthController auth) => GoRouter(
  refreshListenable: auth,
  redirect: (context, state) => authRedirect(
    status: auth.status,
    authenticated: auth.authenticated,
    location: state.matchedLocation,
  ),
  observers: [KeyboardDismissNavigatorObserver()],
  routes: [
    GoRoute(
      path: '/launch',
      pageBuilder: (context, state) => NoTransitionPage<void>(
        key: state.pageKey,
        child: const LaunchPlaceholder(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _contentPage(
        context: context,
        state: state,
        child: const LoginScreen(),
        fadeOnly: true,
      ),
    ),
    ShellRoute(
      observers: [KeyboardDismissNavigatorObserver()],
      builder: (context, state, child) =>
          PlaybackShell(location: state.uri.path, child: child),
      routes: [
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
              routes: [
                GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
              ],
            ),
            StatefulShellBranch(
              observers: [KeyboardDismissNavigatorObserver()],
              routes: [
                GoRoute(
                  path: '/search',
                  builder: (_, _) => const SearchScreen(),
                ),
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
                      pageBuilder: (context, state) => _contentPage(
                        context: context,
                        state: state,
                        child: const LibraryCollectionScreen(
                          kind: LibraryCollectionKind.favorites,
                        ),
                      ),
                    ),
                    GoRoute(
                      path: 'history',
                      pageBuilder: (context, state) => _contentPage(
                        context: context,
                        state: state,
                        child: const LibraryCollectionScreen(
                          kind: LibraryCollectionKind.history,
                        ),
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
          pageBuilder: (context, state) => _contentPage(
            context: context,
            state: state,
            child: const AccountScreen(),
          ),
        ),
        GoRoute(
          path: '/account/settings',
          pageBuilder: (context, state) => _contentPage(
            context: context,
            state: state,
            child: const SettingsScreen(),
          ),
        ),
        GoRoute(
          path: '/account/logs',
          pageBuilder: (context, state) => _contentPage(
            context: context,
            state: state,
            child: const LogSettingsScreen(),
          ),
        ),
        GoRoute(
          path: '/playlist',
          pageBuilder: (context, state) => _contentPage(
            context: context,
            state: state,
            child: PlaylistDetailScreen(
              source: PlaylistTarget.parse(state.extra),
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/player',
      pageBuilder: (context, state) => PlayerTransitionPage<void>(
        key: state.pageKey,
        reduceMotion: MediaQuery.disableAnimationsOf(context),
        child: const PlayerScreen(),
      ),
    ),
  ],
);

CustomTransitionPage<void> _contentPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  bool fadeOnly = false,
}) => CustomTransitionPage<void>(
  key: state.pageKey,
  transitionDuration: KgMotion.resolve(
    context,
    fadeOnly ? KgMotion.fast : KgMotion.pageEnter,
  ),
  reverseTransitionDuration: KgMotion.resolve(
    context,
    fadeOnly ? KgMotion.fast : KgMotion.pageExit,
  ),
  child: child,
  transitionsBuilder: (context, animation, secondary, child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final progress = animation.drive(CurveTween(curve: KgMotion.standard));
    return FadeTransition(
      opacity: progress,
      child: AnimatedBuilder(
        animation: progress,
        child: child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, fadeOnly ? 0 : 24 * (1 - progress.value)),
          child: child,
        ),
      ),
    );
  },
);
