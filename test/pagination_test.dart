import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/pagination.dart';

void main() {
  group('canLoadNextPage', () {
    test('uses the server total when it is available', () {
      expect(
        canLoadNextPage(
          loadedItemCount: 50,
          lastPageItemCount: 50,
          pageSize: 50,
          total: 51,
        ),
        isTrue,
      );
      expect(
        canLoadNextPage(
          loadedItemCount: 51,
          lastPageItemCount: 1,
          pageSize: 50,
          total: 51,
        ),
        isFalse,
      );
    });

    test('falls back to a full-page check when total is absent', () {
      expect(
        canLoadNextPage(
          loadedItemCount: 50,
          lastPageItemCount: 50,
          pageSize: 50,
        ),
        isTrue,
      );
      expect(
        canLoadNextPage(
          loadedItemCount: 63,
          lastPageItemCount: 13,
          pageSize: 50,
        ),
        isFalse,
      );
    });
  });
}
