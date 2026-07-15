import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';
import 'package:kgmusic/features/playlists/playlist_header.dart';

/// Footer widgets for a [PagedListController]: spinner or retry row.
///
/// Returns plain widgets (not slivers) so both ListView and CustomScrollView
/// can wrap them as needed.
List<Widget> pagedListFooters(
  PagedListController controller, {
  Future<void> Function()? onRetryMore,
}) {
  if (controller.loadingMore) {
    return const [
      Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    ];
  }
  final error = controller.loadMoreError;
  if (error != null) {
    return [
      PlaylistLoadError(
        error: error,
        retry: onRetryMore ?? () => controller.loadMore(),
      ),
    ];
  }
  return const [];
}

/// Same as [pagedListFooters] wrapped in [SliverToBoxAdapter]s.
List<Widget> pagedListFooterSlivers(
  PagedListController controller, {
  Future<void> Function()? onRetryMore,
}) => pagedListFooters(controller, onRetryMore: onRetryMore)
    .map((child) => SliverToBoxAdapter(child: child))
    .toList(growable: false);
