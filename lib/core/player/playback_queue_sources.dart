import 'package:kgmusic/core/cache/music_repository.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/playback_queue.dart';

class PlaybackQueueSourceFactory {
  const PlaybackQueueSourceFactory({
    required this.musicRepository,
    required this.libraryRepository,
    required this.sdk,
  });

  final MusicRepository musicRepository;
  final LibraryRepository libraryRepository;
  final MusicSdk sdk;

  Future<PlaybackQueueSource?> restore(
    PlaybackQueueOrigin origin, {
    required int pageSize,
  }) async {
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
  Future<PlaybackQueuePage> loadPage(int page) async {
    final value = await repository
        .search(keyword, userId: userId, page: page, pageSize: pageSize)
        .first;
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
  Future<PlaybackQueuePage> loadPage(int page) async {
    final value = await repository
        .publicPlaylistTracks(
          globalCollectionId,
          userId: userId,
          page: page,
          pageSize: pageSize,
        )
        .first;
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
  Future<PlaybackQueuePage> loadPage(int page) async {
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
