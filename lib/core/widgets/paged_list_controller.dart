import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kgmusic/core/models/pagination.dart';

/// Owns remote list snapshots. A cache emission does not finish a page load.
class PagedListController<T> extends ChangeNotifier {
  PagedListController({
    required this.fetchPage,
    required this.itemId,
    this.pageSize = 30,
    this.loadMoreThreshold = 560,
  });

  final Stream<PageSnapshot<T>> Function(
    int page,
    int pageSize,
    bool forceRefresh,
  )
  fetchPage;
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
  bool _loading = false;
  bool _hasMore = true;
  bool _started = false;
  bool _disposed = false;

  List<T> get items => _items;
  Object? get initialError => _initialError;
  Object? get loadMoreError => _loadMoreError;
  int? get total => _total;
  bool get initialLoading => _loading && _items.isEmpty;
  bool get loadingMore => _loading && _items.isNotEmpty;
  bool get hasMore => _hasMore;
  int get nextPage => _nextPage;
  bool get isEmpty => _items.isEmpty && !_loading && _initialError == null;
  bool get _canAutoLoad =>
      _started &&
      !_disposed &&
      !_loading &&
      _hasMore &&
      _initialError == null &&
      _loadMoreError == null;

  void attach() {
    if (_started || _disposed) return;
    unawaited(reset());
  }

  void clear() {
    if (_disposed) return;
    _generation += 1;
    _pages.clear();
    _items = const [];
    _total = null;
    _nextPage = 1;
    _loading = false;
    _hasMore = true;
    _started = false;
    _initialError = _loadMoreError = null;
    notifyListeners();
  }

  Future<void> reset({bool forceRefresh = false, bool keepItems = false}) =>
      loadMore(reset: true, forceRefresh: forceRefresh, keepItems: keepItems);

  Future<void> retry() => _nextPage == 1
      ? reset(keepItems: _items.isNotEmpty, forceRefresh: true)
      : loadMore();

  Future<void> loadMore({
    bool reset = false,
    bool forceRefresh = false,
    bool keepItems = false,
  }) async {
    if (_disposed || (!reset && (_loading || !_hasMore))) return;
    final generation = reset ? ++_generation : _generation;
    final requestedPage = reset ? 1 : _nextPage;
    if (reset) {
      if (!keepItems) _items = const [];
      _pages.clear();
      _total = null;
      _nextPage = 1;
      _hasMore = true;
    }
    _initialError = _loadMoreError = null;
    _started = _loading = true;
    notifyListeners();
    var received = false;
    try {
      await for (final page in fetchPage(
        requestedPage,
        pageSize,
        forceRefresh,
      )) {
        if (_disposed || generation != _generation) return;
        if (page.page != requestedPage || page.pageSize <= 0) {
          throw const FormatException('Invalid page response');
        }
        received = true;
        final precedingIds = _pages.entries
            .where((entry) => entry.key < requestedPage)
            .expand((entry) => entry.value.items)
            .map(itemId)
            .toSet();
        final progressed = page.items.any(
          (item) => !precedingIds.contains(itemId(item)),
        );
        _pages[requestedPage] = page;
        final known = <String>{};
        final keys = _pages.keys.toList()..sort();
        _items = List.unmodifiable([
          for (final key in keys)
            for (final item in _pages[key]!.items)
              if (known.add(itemId(item))) item,
        ]);
        _total = page.total ?? _total;
        _nextPage = requestedPage + 1;
        _hasMore =
            progressed &&
            canLoadNextPage(
              loadedItemCount: _items.length,
              lastPageItemCount: page.items.length,
              page: requestedPage,
              pageSize: page.pageSize,
              total: _total,
              hasMore: page.hasMore,
            );
        notifyListeners();
      }
      if (!_disposed && generation == _generation && !received) {
        _hasMore = false;
      }
    } catch (error) {
      if (_disposed || generation != _generation) return;
      if (_items.isEmpty) {
        _initialError = error;
      } else {
        _loadMoreError = error;
      }
      // An unsuccessful refresh must retry that page, even after a cache emission.
      _nextPage = requestedPage;
    } finally {
      if (!_disposed && generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  bool onScroll(ScrollMetrics metrics) {
    if (!_canAutoLoad || metrics.extentAfter > loadMoreThreshold) return false;
    unawaited(loadMore());
    return true;
  }

  void loadAgainIfShort(ScrollController controller) {
    if (!_canAutoLoad) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_canAutoLoad && controller.hasClients) onScroll(controller.position);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    super.dispose();
  }
}
