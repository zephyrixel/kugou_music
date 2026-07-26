import 'package:kgmusic/core/cache/music_repository.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/recommendation/recommendation_playback.dart';

class PlaybackQueueSourceFactory {
  const PlaybackQueueSourceFactory({
    required this.musicRepository,
    required this.libraryRepository,
    required this.sdk,
    required this.recommendationPlayback,
  });

  final MusicRepository musicRepository;
  final LibraryRepository libraryRepository;
  final AuthSdk sdk;
  final RecommendationPlayback recommendationPlayback;

  PlaybackQueueRequest search({
    required String keyword,
    required List<Song> songs,
    required int nextPage,
    required bool hasMore,
    required int? total,
    required int? userId,
    int pageSize = 30,
  }) => PlaybackQueueRequest(
    origin: PlaybackQueueOrigin(
      kind: PlaybackQueueOriginKind.search,
      title: '搜索：$keyword',
      id: keyword,
      totalCount: total ?? songs.length,
    ),
    songs: List.unmodifiable(songs),
    source: SearchPlaybackQueueSource(
      repository: musicRepository,
      keyword: keyword,
      userId: userId,
      pageSize: pageSize,
    ),
    nextPage: nextPage,
    hasMore: hasMore,
    pageSize: pageSize,
  );

  PlaybackQueueRequest publicPlaylist({
    required String globalCollectionId,
    required String title,
    required List<Song> songs,
    required int nextPage,
    required bool hasMore,
    required int? total,
    required int? userId,
    int pageSize = 50,
  }) => PlaybackQueueRequest(
    origin: PlaybackQueueOrigin(
      kind: PlaybackQueueOriginKind.publicPlaylist,
      title: title,
      id: globalCollectionId,
      totalCount: total ?? songs.length,
    ),
    songs: List.unmodifiable(songs),
    source: PublicPlaylistPlaybackQueueSource(
      repository: musicRepository,
      globalCollectionId: globalCollectionId,
      userId: userId,
      pageSize: pageSize,
    ),
    nextPage: nextPage,
    hasMore: hasMore,
    pageSize: pageSize,
  );

  PlaybackQueueRequest libraryPlaylist({
    required Playlist playlist,
    required List<Song> songs,
    required int count,
    required int nextPage,
    required bool hasMore,
    int pageSize = 100,
  }) {
    final localId = playlist.localId;
    if (localId == null) {
      throw StateError('本地歌单缺少 localId');
    }
    return PlaybackQueueRequest(
      origin: PlaybackQueueOrigin(
        kind: playlist.isMyFavorite
            ? PlaybackQueueOriginKind.favorites
            : PlaybackQueueOriginKind.libraryPlaylist,
        title: playlist.name,
        id: localId,
        totalCount: count,
        sourceBits: playlist.isMyFavorite
            ? 16
            : playlist.isCollected
            ? 64
            : 32,
      ),
      songs: List.unmodifiable(songs),
      source: LibraryPlaylistPlaybackQueueSource(
        repository: libraryRepository,
        localId: localId,
        pageSize: pageSize,
      ),
      nextPage: nextPage,
      hasMore: hasMore,
      pageSize: pageSize,
    );
  }

  Future<PlaybackQueueSource?> restore(
    PlaybackQueueOrigin origin, {
    required int pageSize,
  }) async {
    final recommendationKind = RecommendationPlayback.kindForOrigin(
      origin.kind,
    );
    if (recommendationKind != null) {
      return recommendationPlayback.createSource(recommendationKind);
    }
    final id = origin.id;
    if (id == null || id.isEmpty) return null;
    final auth = await sdk.authState();
    final userId = auth.authenticated ? auth.userId : null;
    return switch (origin.kind) {
      PlaybackQueueOriginKind.search => SearchPlaybackQueueSource(
        repository: musicRepository,
        keyword: id,
        userId: userId,
        pageSize: pageSize,
      ),
      PlaybackQueueOriginKind.publicPlaylist =>
        PublicPlaylistPlaybackQueueSource(
          repository: musicRepository,
          globalCollectionId: id,
          userId: userId,
          pageSize: pageSize,
        ),
      PlaybackQueueOriginKind.libraryPlaylist ||
      PlaybackQueueOriginKind.favorites => LibraryPlaylistPlaybackQueueSource(
        repository: libraryRepository,
        localId: id,
        pageSize: pageSize,
      ),
      _ => null,
    };
  }
}

class SearchPlaybackQueueSource implements PlaybackQueueSource {
  const SearchPlaybackQueueSource({
    required this.repository,
    required this.keyword,
    required this.userId,
    this.pageSize = 30,
  });

  final MusicRepository repository;
  final String keyword;
  final int? userId;
  final int pageSize;

  @override
  Future<PlaybackQueuePage> loadPage(PlaybackQueueLoadRequest request) async {
    final page = request.page;
    // `.last`, not `.first`: the repository emits the cached page before the
    // refreshed one, and `.first` would abandon the in-flight request.
    final value = await repository
        .search(keyword, userId: userId, page: page, pageSize: pageSize)
        .last;
    return PlaybackQueuePage(
      page: value.page,
      pageSize: value.pageSize,
      songs: value.songs,
      total: value.total,
    );
  }
}

class PublicPlaylistPlaybackQueueSource implements PlaybackQueueSource {
  const PublicPlaylistPlaybackQueueSource({
    required this.repository,
    required this.globalCollectionId,
    required this.userId,
    this.pageSize = 50,
  });

  final MusicRepository repository;
  final String globalCollectionId;
  final int? userId;
  final int pageSize;

  @override
  Future<PlaybackQueuePage> loadPage(PlaybackQueueLoadRequest request) async {
    final page = request.page;
    final value = await repository
        .publicPlaylistTracks(
          globalCollectionId,
          userId: userId,
          page: page,
          pageSize: pageSize,
        )
        .last;
    return PlaybackQueuePage(
      page: value.page,
      pageSize: value.pageSize,
      songs: value.songs,
      total: value.total,
    );
  }
}

class LibraryPlaylistPlaybackQueueSource implements PlaybackQueueSource {
  const LibraryPlaylistPlaybackQueueSource({
    required this.repository,
    required this.localId,
    this.pageSize = 100,
  });

  final LibraryRepository repository;
  final String localId;
  final int pageSize;

  @override
  Future<PlaybackQueuePage> loadPage(PlaybackQueueLoadRequest request) async {
    final page = request.page;
    final value = await repository.playbackQueuePage(
      localId,
      page: page,
      pageSize: pageSize,
    );
    return PlaybackQueuePage(
      page: value.page,
      pageSize: value.pageSize,
      songs: value.songs,
      total: value.total,
    );
  }
}
