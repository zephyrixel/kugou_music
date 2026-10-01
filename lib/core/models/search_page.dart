import 'package:kgmusic/core/models/song.dart';

class SearchPage {
  const SearchPage({
    required this.songs,
    required this.page,
    required this.pageSize,
    this.total,
  });
  final List<Song> songs;
  final int page;
  final int pageSize;
  final int? total;
}
