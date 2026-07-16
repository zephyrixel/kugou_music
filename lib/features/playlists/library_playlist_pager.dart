import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';

PagedListController<Song> createLibraryPlaylistPager({
  required LibraryRepository repository,
  required String localId,
  int pageSize = 100,
}) => PagedListController<Song>(
  pageSize: pageSize,
  itemId: (song) => song.id,
  fetchPage: (page, size, forceRefresh) => repository
      .loadPlaylistPage(
        localId,
        page: page,
        pageSize: size,
        forceRefresh: forceRefresh,
      )
      .map(
        (result) => PageSnapshot(
          items: result.songs,
          page: result.page,
          pageSize: result.pageSize,
          total: result.total,
        ),
      ),
);
