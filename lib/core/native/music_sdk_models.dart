import 'package:kgmusic/core/models/song.dart';

class CloudHistoryEntry {
  const CloudHistoryEntry({
    required this.song,
    required this.playedAt,
    required this.playCount,
  });

  final Song song;
  final DateTime playedAt;
  final int playCount;
}

class CloudHistoryPage {
  const CloudHistoryPage({
    required this.items,
    required this.hasMore,
    this.cursor,
    this.total,
  });

  final List<CloudHistoryEntry> items;
  final String? cursor;
  final bool hasMore;
  final int? total;
}

class CloudHistoryUpload {
  const CloudHistoryUpload({
    required this.mixSongId,
    required this.playedAt,
    required this.playCount,
  });

  final int mixSongId;
  final DateTime playedAt;
  final int playCount;
}

class PlaylistMutation {
  const PlaylistMutation({required this.listId, this.globalCollectionId});

  final int listId;
  final String? globalCollectionId;
}

class PlaylistTracksMutation {
  const PlaylistTracksMutation({required this.fileIds});

  final List<int> fileIds;
}
