import 'dart:async';

import 'package:go_router/go_router.dart';

/// Both player entry points use the router as their source of truth.
///
/// A push Future represents the page's result, not a navigation-in-progress
/// flag: go()/branch restoration can remove the page without completing it.
/// The information provider records a push synchronously, before the delegate
/// commits it. After commit the delegate knows the actual top page (the URL
/// alone does not include imperative routes).
void openPlayer(GoRouter router) {
  final delegate = router.routerDelegate;
  if (delegate.currentConfiguration.isNotEmpty &&
      delegate.state.matchedLocation == '/player') {
    return;
  }
  final request = router.routeInformationProvider.value;
  if (request.state is RouteInformationState && request.uri.path == '/player') {
    return;
  }
  unawaited(router.push<void>('/player'));
}
