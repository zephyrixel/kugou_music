import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/models/pagination.dart';

/// Loads pages into Drift. The view observes Drift, so this controller keeps no
/// second copy of the songs and never infers a remote cursor from local counts.
class LibraryPlaylistPager extends ChangeNotifier {
  LibraryPlaylistPager({
    required this.repository,
    required this.localId,
    this.pageSize = 100,
  });

  final LibraryRepository repository;
  final String localId;
  final int pageSize;
  int nextPage = 1;
  bool hasMore = true;
  bool loading = false;
  Object? error;
  int _generation = 0;
  bool _disposed = false;
  String? _lastPageSignature;

  bool get initialLoading => loading && nextPage == 1;
  bool get loadingMore => loading && nextPage > 1;
  Object? get initialError => nextPage == 1 ? error : null;
  Object? get loadMoreError => nextPage > 1 ? error : null;

  void attach() => unawaited(loadMore());
  Future<void> retry() => loadMore();

  Future<void> reset({bool forceRefresh = false, bool keepItems = true}) {
    _generation += 1;
    nextPage = 1;
    hasMore = true;
    loading = false;
    _lastPageSignature = null;
    return loadMore(forceRefresh: forceRefresh);
  }

  Future<void> loadMore({bool forceRefresh = false}) async {
    if (_disposed || loading || !hasMore) return;
    final generation = _generation;
    final requestedPage = nextPage;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await repository
          .loadPlaylistPage(
            localId,
            page: requestedPage,
            pageSize: pageSize,
            forceRefresh: forceRefresh,
          )
          .last;
      if (_disposed || generation != _generation) return;
      final signature = page.songs.map((song) => song.id).join('\u0000');
      hasMore =
          signature != _lastPageSignature &&
          canLoadNextPage(
            loadedItemCount: 0,
            lastPageItemCount: page.songs.length,
            pageSize: page.pageSize,
            page: page.page,
            total: page.total,
          );
      _lastPageSignature = signature;
      nextPage = page.page + 1;
    } catch (failure) {
      if (_disposed || generation != _generation) return;
      error = failure;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void onScroll(ScrollMetrics metrics) {
    if (error == null && !loading && hasMore && metrics.extentAfter <= 560) {
      unawaited(loadMore());
    }
  }

  void loadAgainIfShort(ScrollController controller) {
    if (_disposed || loading || error != null || !hasMore) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && controller.hasClients) onScroll(controller.position);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    super.dispose();
  }
}

LibraryPlaylistPager createLibraryPlaylistPager({
  required LibraryRepository repository,
  required String localId,
  int pageSize = 100,
}) => LibraryPlaylistPager(
  repository: repository,
  localId: localId,
  pageSize: pageSize,
);
