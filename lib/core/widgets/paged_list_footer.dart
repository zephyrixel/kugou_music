import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

/// Bottom-of-list loading / error row used by public playlists, search, and
/// library progressive track loads.
List<Widget> loadMoreFooters({
  required bool loading,
  Object? error,
  Future<void> Function()? onRetry,
  String errorMessage = '更多内容加载失败，请重试',
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
      KgErrorView(
        message: errorMessage,
        onRetry: onRetry ?? () async {},
        compact: true,
      ),
    ];
  }
  return const [];
}

List<Widget> loadMoreFooterSlivers({
  required bool loading,
  Object? error,
  Future<void> Function()? onRetry,
  String errorMessage = '更多内容加载失败，请重试',
}) => loadMoreFooters(
  loading: loading,
  error: error,
  onRetry: onRetry,
  errorMessage: errorMessage,
).map((child) => SliverToBoxAdapter(child: child)).toList(growable: false);

/// Convenience for [PagedListController].
List<Widget> pagedListFooters(
  PagedListController controller, {
  Future<void> Function()? onRetryMore,
  String errorMessage = '更多内容加载失败，请重试',
}) => loadMoreFooters(
  loading: controller.loadingMore,
  error: controller.loadMoreError,
  onRetry: onRetryMore ?? () => controller.loadMore(),
  errorMessage: errorMessage,
);

List<Widget> pagedListFooterSlivers(
  PagedListController controller, {
  Future<void> Function()? onRetryMore,
  String errorMessage = '更多内容加载失败，请重试',
}) => loadMoreFooterSlivers(
  loading: controller.loadingMore,
  error: controller.loadMoreError,
  onRetry: onRetryMore ?? () => controller.loadMore(),
  errorMessage: errorMessage,
);
