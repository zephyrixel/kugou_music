bool canLoadNextPage({
  required int loadedItemCount,
  required int lastPageItemCount,
  required int pageSize,
  int? total,
}) {
  if (total != null) return loadedItemCount < total;
  return lastPageItemCount >= pageSize;
}
