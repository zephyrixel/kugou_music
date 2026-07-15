import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/player/playback_queue_sources.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/paged_list_footer.dart';
import 'package:kgmusic/features/playlists/playlist_scaffold.dart';

class PublicPlaylistScreen extends ConsumerStatefulWidget {
  const PublicPlaylistScreen({super.key, required this.playlist});

  final PlaylistSearchHit playlist;

  @override
  ConsumerState<PublicPlaylistScreen> createState() =>
      _PublicPlaylistScreenState();
}

class _PublicPlaylistScreenState extends ConsumerState<PublicPlaylistScreen> {
  static const _pageSize = 50;

  final _scrollController = ScrollController();
  late final PagedListController<Song> _pager;

  @override
  void initState() {
    super.initState();
    _pager = PagedListController<Song>(
      pageSize: _pageSize,
      itemId: (song) => song.id,
      fetchPage: (page, pageSize) {
        final userId = ref.read(authControllerProvider).snapshot.userId;
        return ref
            .read(musicRepositoryProvider)
            .publicPlaylistTracks(
              widget.playlist.globalCollectionId!,
              userId: userId,
              page: page,
              pageSize: pageSize,
            )
            .map(
              (result) => PageSnapshot(
                items: result.songs,
                page: result.page,
                pageSize: result.pageSize,
                total: result.total,
              ),
            );
      },
    );
    _pager.addListener(_onPagerChanged);
    _scrollController.addListener(_onScroll);
    _pager.attach();
  }

  @override
  void dispose() {
    _pager.removeListener(_onPagerChanged);
    _pager.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onPagerChanged() {
    if (mounted) setState(() {});
    _pager.loadAgainIfShort(_scrollController);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _pager.onScroll(_scrollController.position);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: Colors.transparent),
    body: PlaylistSongsView(
      title: widget.playlist.name,
      artwork: widget.playlist.artworkUrl,
      cacheId: 'playlist:${widget.playlist.globalCollectionId}',
      count: _pager.total ?? widget.playlist.songCount ?? _pager.items.length,
      songs: _pager.items,
      loading: _pager.initialLoading,
      error: _pager.initialError,
      scrollController: _scrollController,
      onRefresh: () => _pager.reset(),
      onRetry: () => _pager.reset(),
      trailing: OutlinedButton.icon(
        onPressed: widget.playlist.globalCollectionId == null ? null : _collect,
        icon: const Icon(Icons.library_add_outlined),
        label: const Text('收藏歌单'),
      ),
      footerSlivers: pagedListFooterSlivers(_pager),
      queueRequest: (songs) {
        final userId = ref.read(authControllerProvider).snapshot.userId;
        return PlaybackQueueRequest(
          origin: PlaybackQueueOrigin(
            kind: PlaybackQueueOriginKind.publicPlaylist,
            title: widget.playlist.name,
            id: widget.playlist.globalCollectionId,
            totalCount:
                _pager.total ?? widget.playlist.songCount ?? songs.length,
          ),
          songs: List.unmodifiable(songs),
          source: PublicPlaylistPlaybackQueueSource(
            repository: ref.read(musicRepositoryProvider),
            globalCollectionId: widget.playlist.globalCollectionId!,
            userId: userId,
          ),
          nextPage: _pager.nextPage,
          hasMore: _pager.hasMore,
          pageSize: _pageSize,
        );
      },
    ),
  );

  Future<void> _collect() async {
    try {
      await ref
          .read(libraryRepositoryProvider)
          .collectPlaylist(widget.playlist);
      if (mounted) showAppMessage(context, '已收藏');
    } catch (error) {
      if (mounted) showAppError(context, error);
    }
  }
}
