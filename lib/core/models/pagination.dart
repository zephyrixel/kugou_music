/// Whether another page should be requested after merging [lastPageItemCount]
/// items into a list that already has [loadedItemCount] unique items.
bool canLoadNextPage({
  required int loadedItemCount,
  required int lastPageItemCount,
  required int pageSize,
  int? total,
  int? page,
  bool? hasMore,
}) {
  if (lastPageItemCount == 0) return false;
  if (hasMore != null) return hasMore;
  if (total != null) {
    return (page == null ? loadedItemCount : page * pageSize) < total;
  }
  return lastPageItemCount >= pageSize;
}

/// One page of items from a paged remote/cache source.
class PageSnapshot<T> {
  const PageSnapshot({
    required this.items,
    required this.page,
    required this.pageSize,
    this.total,
    this.hasMore,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int? total;
  final bool? hasMore;
}
