import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';
import 'package:kgmusic/features/playlists/playlist_header.dart';

/// Bottom-of-list loading / error row used by public playlists, search, and
/// library progressive track loads.
List<Widget> loadMoreFooters({
  required bool loading,
  Object? error,
  Future<void> Function()? onRetry,
}) {
  if (loading) {
    return const [
      Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    ];
  }
  if (error != null) {
    return [
      PlaylistLoadError(
        error: error,
        retry: onRetry ?? () async {},
      ),
    ];
  }
  return const [];
}

List<Widget> loadMoreFooterSlivers({
  required bool loading,
  Object? error,
  Future<void> Function()? onRetry,
}) =>
    loadMoreFooters(loading: loading, error: error, onRetry: onRetry)
        .map((child) => SliverToBoxAdapter(child: child))
        .toList(growable: false);

/// Convenience for [PagedListController].
List<Widget> pagedListFooters(
  PagedListController controller, {
  Future<void> Function()? onRetryMore,
}) =>
    loadMoreFooters(
      loading: controller.loadingMore,
      error: controller.loadMoreError,
      onRetry: onRetryMore ?? () => controller.loadMore(),
    );

List<Widget> pagedListFooterSlivers(
  PagedListController controller, {
  Future<void> Function()? onRetryMore,
}) =>
    loadMoreFooterSlivers(
      loading: controller.loadingMore,
      error: controller.loadMoreError,
      onRetry: onRetryMore ?? () => controller.loadMore(),
    );
