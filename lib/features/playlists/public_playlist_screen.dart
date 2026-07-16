import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/cache/cache_policy.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
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
      fetchPage: (page, pageSize, forceRefresh) {
        final userId = ref.read(authControllerProvider).snapshot.userId;
        return ref
            .read(musicRepositoryProvider)
            .publicPlaylistTracks(
              widget.playlist.globalCollectionId!,
              userId: userId,
              page: page,
              pageSize: pageSize,
              mode: forceRefresh
                  ? CacheLoadMode.forceRefresh
                  : CacheLoadMode.normal,
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
    body: PlaylistSongsView(
      title: widget.playlist.name,
      subtitle: widget.playlist.creatorName,
      description: widget.playlist.intro,
      artwork: widget.playlist.artworkUrl,
      cacheId: 'playlist:${widget.playlist.globalCollectionId}',
      count: _pager.total ?? widget.playlist.songCount ?? _pager.items.length,
      songs: _pager.items,
      loading: _pager.initialLoading,
      error: _pager.initialError,
      scrollController: _scrollController,
      onRefresh: () => _pager.reset(forceRefresh: true, keepItems: true),
      onRetry: () => _pager.reset(),
      trailing: OutlinedButton.icon(
        onPressed: widget.playlist.globalCollectionId == null ? null : _collect,
        icon: const Icon(Icons.library_add_outlined),
        label: const Text('收藏歌单'),
      ),
      footerSlivers: pagedListFooterSlivers(_pager),
      queueRequest: (songs) {
        final userId = ref.read(authControllerProvider).snapshot.userId;
        final gid = widget.playlist.globalCollectionId;
        if (gid == null || gid.isEmpty) {
          throw StateError('公开歌单缺少全局标识');
        }
        return ref
            .read(playbackQueueFactoryProvider)
            .publicPlaylist(
              globalCollectionId: gid,
              title: widget.playlist.name,
              songs: songs,
              nextPage: _pager.nextPage,
              hasMore: _pager.hasMore,
              total: _pager.total ?? widget.playlist.songCount,
              userId: userId,
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
