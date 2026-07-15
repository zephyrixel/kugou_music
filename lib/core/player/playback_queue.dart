import 'package:kgmusic/core/models/song.dart';

enum PlaybackOrder { sequential, repeatAll, repeatOne, shuffle }

extension PlaybackOrderInfo on PlaybackOrder {
  String get label => switch (this) {
    PlaybackOrder.sequential => '顺序播放',
    PlaybackOrder.repeatAll => '列表循环',
    PlaybackOrder.repeatOne => '单曲循环',
    PlaybackOrder.shuffle => '随机播放',
  };

  String get description => switch (this) {
    PlaybackOrder.sequential => '播放到队列末尾后停止',
    PlaybackOrder.repeatAll => '播放完队列后从第一首继续',
    PlaybackOrder.repeatOne => '循环当前歌曲',
    PlaybackOrder.shuffle => '从待播歌曲中随机选择',
  };
}

enum PlaybackQueueOriginKind {
  snapshot,
  dailyRecommendations,
  search,
  libraryPlaylist,
  publicPlaylist,
  favorites,
  history,
  personalFm,
  heartRadio,
}

extension PlaybackQueueOriginKindInfo on PlaybackQueueOriginKind {
  String get label => switch (this) {
    PlaybackQueueOriginKind.snapshot => '播放队列',
    PlaybackQueueOriginKind.dailyRecommendations => '每日推荐',
    PlaybackQueueOriginKind.search => '搜索结果',
    PlaybackQueueOriginKind.libraryPlaylist => '本地歌单',
    PlaybackQueueOriginKind.publicPlaylist => '公开歌单',
    PlaybackQueueOriginKind.favorites => '我喜欢',
    PlaybackQueueOriginKind.history => '最近播放',
    PlaybackQueueOriginKind.personalFm => '猜你喜欢',
    PlaybackQueueOriginKind.heartRadio => '红心电台',
  };
}

class PlaybackQueueOrigin {
  const PlaybackQueueOrigin({
    required this.kind,
    required this.title,
    this.id,
    this.totalCount,
  });

  final PlaybackQueueOriginKind kind;
  final String title;
  final String? id;
  final int? totalCount;

  String get displayTitle => title.trim().isEmpty ? kind.label : title;

  PlaybackQueueOrigin copyWith({String? title, int? totalCount}) =>
      PlaybackQueueOrigin(
        kind: kind,
        title: title ?? this.title,
        id: id,
        totalCount: totalCount ?? this.totalCount,
      );
}

class PlaybackQueuePage {
  const PlaybackQueuePage({
    required this.page,
    required this.pageSize,
    required this.songs,
    this.total,
    this.hasMore,
  });

  final int page;
  final int pageSize;
  final List<Song> songs;
  final int? total;
  final bool? hasMore;
}

class PlaybackQueueLoadRequest {
  const PlaybackQueueLoadRequest({
    required this.page,
    required this.currentIndex,
    required this.songs,
    required this.position,
  });

  final int page;
  final int currentIndex;
  final List<Song> songs;
  final Duration position;

  Song? get currentSong => currentIndex >= 0 && currentIndex < songs.length
      ? songs[currentIndex]
      : null;

  int get remainingCount => currentIndex < 0
      ? songs.length
      : (songs.length - currentIndex - 1).clamp(0, songs.length);
}

/// A source-backed queue request. The loader is intentionally small so feature
/// pages can provide cached/local implementations without coupling the player
/// to a specific repository.
abstract interface class PlaybackQueueSource {
  Future<PlaybackQueuePage> loadPage(PlaybackQueueLoadRequest request);
}

class PlaybackQueueRequest {
  const PlaybackQueueRequest({
    required this.origin,
    required this.songs,
    this.source,
    this.nextPage = 1,
    this.hasMore = false,
    this.pageSize = 50,
  });

  factory PlaybackQueueRequest.snapshot({
    required String title,
    required List<Song> songs,
    PlaybackQueueOriginKind kind = PlaybackQueueOriginKind.snapshot,
  }) => PlaybackQueueRequest(
    origin: PlaybackQueueOrigin(
      kind: kind,
      title: title,
      totalCount: songs.length,
    ),
    songs: List.unmodifiable(songs),
  );

  final PlaybackQueueOrigin origin;
  final List<Song> songs;
  final PlaybackQueueSource? source;
  final int nextPage;
  final bool hasMore;
  final int pageSize;

  PlaybackQueueRequest copyWith({
    PlaybackQueueOrigin? origin,
    List<Song>? songs,
    PlaybackQueueSource? source,
    int? nextPage,
    bool? hasMore,
    int? pageSize,
  }) => PlaybackQueueRequest(
    origin: origin ?? this.origin,
    songs: songs ?? this.songs,
    source: source ?? this.source,
    nextPage: nextPage ?? this.nextPage,
    hasMore: hasMore ?? this.hasMore,
    pageSize: pageSize ?? this.pageSize,
  );
}

class PlaybackQueueState {
  const PlaybackQueueState({
    required this.origin,
    required this.songs,
    required this.currentIndex,
    required this.order,
    required this.hasMore,
    this.loadingMore = false,
    this.error,
  });

  final PlaybackQueueOrigin origin;
  final List<Song> songs;
  final int currentIndex;
  final PlaybackOrder order;
  final bool hasMore;
  final bool loadingMore;
  final Object? error;

  Song? get currentSong => currentIndex >= 0 && currentIndex < songs.length
      ? songs[currentIndex]
      : null;

  List<Song> get upcoming => currentIndex < 0
      ? songs
      : songs.skip(currentIndex + 1).toList(growable: false);
}
