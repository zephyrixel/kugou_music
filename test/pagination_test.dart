import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';

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

  group('PagedListController', () {
    test('merges pages and de-duplicates by id', () async {
      final pages = <int, List<String>>{
        1: ['a', 'b', 'c'],
        2: ['c', 'd'],
      };
      final controller = PagedListController<String>(
        pageSize: 3,
        itemId: (item) => item,
        fetchPage: (page, pageSize, forceRefresh) async* {
          yield PageSnapshot(
            items: pages[page] ?? const [],
            page: page,
            pageSize: pageSize,
            total: 4,
          );
        },
      );

      await controller.loadMore(reset: true);
      expect(controller.items, ['a', 'b', 'c']);
      expect(controller.hasMore, isTrue);
      expect(controller.initialLoading, isFalse);

      await controller.loadMore();
      expect(controller.items, ['a', 'b', 'c', 'd']);
      expect(controller.hasMore, isFalse);
      expect(controller.total, 4);

      controller.dispose();
    });

    test('reset invalidates in-flight pages', () async {
      final gate = Completer<void>();
      var page1Calls = 0;
      final controller = PagedListController<String>(
        pageSize: 2,
        itemId: (item) => item,
        fetchPage: (page, pageSize, forceRefresh) async* {
          if (page == 1) {
            page1Calls += 1;
            if (page1Calls == 1) {
              await gate.future;
              yield const PageSnapshot(
                items: ['stale'],
                page: 1,
                pageSize: 2,
                total: 1,
              );
              return;
            }
          }
          yield PageSnapshot(
            items: const ['fresh'],
            page: page,
            pageSize: pageSize,
            total: 1,
          );
        },
      );

      final first = controller.loadMore(reset: true);
      await Future<void>.delayed(Duration.zero);
      final second = controller.loadMore(reset: true);
      gate.complete();
      await first;
      await second;

      expect(controller.items, ['fresh']);
      expect(page1Calls, 2);

      controller.dispose();
    });

    test('surfaces load-more errors without wiping items', () async {
      var calls = 0;
      final controller = PagedListController<String>(
        pageSize: 1,
        itemId: (item) => item,
        fetchPage: (page, pageSize, forceRefresh) async* {
          calls += 1;
          if (calls == 1) {
            yield PageSnapshot(
              items: const ['a'],
              page: page,
              pageSize: pageSize,
              total: 2,
            );
            return;
          }
          throw StateError('network');
        },
      );

      await controller.loadMore(reset: true);
      expect(controller.items, ['a']);

      await controller.loadMore();
      expect(controller.items, ['a']);
      expect(controller.loadMoreError, isA<StateError>());
      expect(controller.loadingMore, isFalse);

      controller.dispose();
    });
  });
}
