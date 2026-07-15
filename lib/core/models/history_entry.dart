import 'package:kgmusic/core/models/song.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.song,
    required this.playedAt,
    required this.playCount,
  });

  final Song song;
  final DateTime playedAt;
  final int playCount;
}

class HistoryPage {
  const HistoryPage({
    required this.items,
    required this.hasMore,
    this.cursor,
    this.total,
  });

  final List<HistoryEntry> items;
  final String? cursor;
  final bool hasMore;
  final int? total;
}

class HistoryUpload {
  const HistoryUpload({
    required this.mixSongId,
    required this.playedAt,
    required this.playCount,
  });

  final int mixSongId;
  final DateTime playedAt;
  final int playCount;
}
