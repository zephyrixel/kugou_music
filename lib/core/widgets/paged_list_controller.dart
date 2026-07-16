import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kgmusic/core/models/pagination.dart';

/// Shared infinite-scroll list state for page-based remote sources.
///
/// Call [attach] once from [State.initState], [reset] when the query changes,
/// and [loadMore] from scroll listeners. Dispose with the host State.
class PagedListController<T> extends ChangeNotifier {
  PagedListController({
    required this.fetchPage,
    required this.itemId,
    this.pageSize = 30,
    this.loadMoreThreshold = 560,
  });

  /// Loads a single page. May emit multiple times (cache then network).
  final Stream<PageSnapshot<T>> Function(
    int page,
    int pageSize,
    bool forceRefresh,
  )
  fetchPage;

  /// Stable identity for de-duplication across pages.
  final String Function(T item) itemId;

  final int pageSize;
  final double loadMoreThreshold;

  final Map<int, PageSnapshot<T>> _pages = {};
  List<T> _items = const [];
  Object? _initialError;
  Object? _loadMoreError;
  int? _total;
  int _nextPage = 1;
  int _generation = 0;
  bool _initialLoading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _started = false;
  bool _disposed = false;

  List<T> get items => _items;
  Object? get initialError => _initialError;
  Object? get loadMoreError => _loadMoreError;
  int? get total => _total;
  bool get initialLoading => _initialLoading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  int get nextPage => _nextPage;
  bool get isEmpty =>
      _items.isEmpty && !_initialLoading && _initialError == null;

  /// Kick off the first page (idempotent until [reset]).
  void attach() {
    if (_started || _disposed) return;
    _started = true;
    unawaited(loadMore(reset: true));
  }

  /// Drop state and reload page 1 (e.g. new search keyword).
  Future<void> reset({bool forceRefresh = false, bool keepItems = false}) =>
      loadMore(reset: true, forceRefresh: forceRefresh, keepItems: keepItems);

  Future<void> loadMore({
    bool reset = false,
    bool forceRefresh = false,
    bool keepItems = false,
  }) async {
    if (_disposed) return;
    if (!reset && (_initialLoading || _loadingMore || !_hasMore)) return;
    final generation = reset ? ++_generation : _generation;
    final requestedPage = reset ? 1 : _nextPage;

    _mutate(() {
      if (reset) {
        if (!keepItems) _items = const [];
        // Keep the rendered snapshot, but discard page bookkeeping so the
        // refreshed first page becomes the new pagination anchor.
        _pages.clear();
        _initialError = null;
        _loadMoreError = null;
        _total = null;
        _nextPage = 1;
        _initialLoading = _items.isEmpty;
        _hasMore = true;
        _started = true;
      } else {
        _loadingMore = true;
        _loadMoreError = null;
      }
    });

    try {
      await for (final page in fetchPage(
        requestedPage,
        pageSize,
        forceRefresh,
      )) {
        if (_disposed || generation != _generation) return;
        _pages[page.page] = page;
        final merged = <T>[];
        final known = <String>{};
        final pages = _pages.values.toList()
          ..sort((a, b) => a.page.compareTo(b.page));
        for (final snapshot in pages) {
          for (final item in snapshot.items) {
            if (known.add(itemId(item))) merged.add(item);
          }
        }
        final total = page.total ?? _total;
        _mutate(() {
          _items = List.unmodifiable(merged);
          _total = total;
          _nextPage = _pages.keys.reduce((a, b) => a > b ? a : b) + 1;
          _hasMore = canLoadNextPage(
            loadedItemCount: merged.length,
            lastPageItemCount: page.items.length,
            pageSize: page.pageSize,
            total: total,
          );
          _initialLoading = false;
        });
      }
      if (_disposed || generation != _generation) return;
      _mutate(() => _loadingMore = false);
    } catch (error) {
      if (_disposed || generation != _generation) return;
      _mutate(() {
        if (reset && keepItems && _items.isNotEmpty) {
          _loadMoreError = error;
        } else if (reset || _items.isEmpty) {
          _initialError = error;
          _initialLoading = false;
        } else {
          _loadMoreError = error;
        }
        _loadingMore = false;
      });
    }
  }

  /// Scroll-near-end helper. Returns true when a load was scheduled.
  bool onScroll(ScrollMetrics metrics) {
    if (metrics.extentAfter <= loadMoreThreshold) {
      unawaited(loadMore());
      return true;
    }
    return false;
  }

  /// After layout, if content still does not fill the viewport, fetch more.
  void loadAgainIfShort(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !controller.hasClients) return;
      if (controller.position.extentAfter <= loadMoreThreshold) {
        unawaited(loadMore());
      }
    });
  }

  void _mutate(void Function() update) {
    if (_disposed) return;
    update();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    super.dispose();
  }
}
