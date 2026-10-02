import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/player_navigation.dart';

/// Turns notification clicks into an idempotent navigation action.
///
/// Notification click events can arrive more than once while Android resumes
/// the activity. Navigation is deferred until the router is ready, while the
/// pending flag coalesces clicks before the first route update is committed.
class NotificationNavigationController {
  NotificationNavigationController({
    required this.router,
    required this.hasMediaItem,
    required this.isMounted,
  });

  static const playerPath = '/player';
  static const homePath = '/';

  final GoRouter router;
  final bool Function() hasMediaItem;
  final bool Function() isMounted;

  bool _navigationPending = false;
  bool _disposed = false;

  void openNotificationTarget() {
    if (_disposed || _navigationPending) return;
    _navigationPending = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !isMounted()) {
        _navigationPending = false;
        return;
      }

      try {
        if (hasMediaItem()) {
          openPlayer(router);
        } else if (!_isAt(homePath)) {
          router.go(homePath);
        }
      } finally {
        // Keep the gate closed until the router has committed this update.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) _navigationPending = false;
        });
      }
    });
  }

  bool _isAt(String path) {
    final configuration = router.routerDelegate.currentConfiguration;
    return configuration.isNotEmpty &&
        router.routerDelegate.state.matchedLocation == path;
  }

  void dispose() {
    _disposed = true;
  }
}
