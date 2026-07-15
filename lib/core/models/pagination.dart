/// Whether another page should be requested after merging [lastPageItemCount]
/// items into a list that already has [loadedItemCount] unique items.
bool canLoadNextPage({
  required int loadedItemCount,
  required int lastPageItemCount,
  required int pageSize,
  int? total,
}) {
  if (total != null) return loadedItemCount < total;
  return lastPageItemCount >= pageSize;
}

/// One page of items from a paged remote/cache source.
class PageSnapshot<T> {
  const PageSnapshot({
    required this.items,
    required this.page,
    required this.pageSize,
    this.total,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int? total;
}
