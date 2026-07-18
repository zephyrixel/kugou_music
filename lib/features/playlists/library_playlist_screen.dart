import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/app_dialogs.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/paged_list_footer.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';
import 'package:kgmusic/core/widgets/song_tile_actions.dart';
import 'package:kgmusic/features/playlists/playlist_scaffold.dart';
import 'package:kgmusic/features/playlists/library_playlist_pager.dart';

class LibraryPlaylistScreen extends ConsumerStatefulWidget {
  const LibraryPlaylistScreen({super.key, required this.playlist});

  final Playlist playlist;

  @override
  ConsumerState<LibraryPlaylistScreen> createState() =>
      _LibraryPlaylistScreenState();
}

class _LibraryPlaylistScreenState extends ConsumerState<LibraryPlaylistScreen> {
  Object? _loadError;
  final _scrollController = ScrollController();
  late final PagedListController<Song> _pager;

  @override
  void initState() {
    super.initState();
    _pager =
        createLibraryPlaylistPager(
            repository: ref.read(libraryRepositoryProvider),
            localId: widget.playlist.localId!,
          )
          ..addListener(_onPagerChanged)
          ..attach();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _load({bool force = false}) async {
    if (force && mounted) setState(() => _loadError = null);
    try {
      if (force) {
        await _pager.reset(forceRefresh: true, keepItems: true);
      } else if (!_pager.initialLoading && _pager.items.isEmpty) {
        await _pager.loadMore(reset: true);
      }
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
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
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pager.removeListener(_onPagerChanged);
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(libraryPlaylistsProvider).value ?? const [];
    final current = playlists
        .where((item) => item.localId == widget.playlist.localId)
        .firstOrNull;
    final playlist = current ?? widget.playlist;
    final tracks = ref.watch(
      libraryPlaylistTracksProvider(widget.playlist.localId!),
    );
    final songs = tracks.value ?? const <Song>[];
    // Header prefers cloud metadata count while pages are still arriving.
    final available = playlist.availableTrackCount;
    final count = available > songs.length ? available : songs.length;

    return Scaffold(
      body: PlaylistSongsView(
        title: playlist.name,
        subtitle: playlist.creatorName,
        description: playlist.intro,
        artwork: playlist.artworkUrl,
        cacheId: 'playlist:${playlist.localId}',
        count: count,
        appBarActions: [
          if (!playlist.isSystem)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit' && !playlist.isCollected) {
                  unawaited(_edit(playlist));
                }
                if (value == 'delete') unawaited(_delete(playlist));
              },
              itemBuilder: (_) => [
                if (!playlist.isCollected)
                  const PopupMenuItem(value: 'edit', child: Text('编辑歌单')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(playlist.isCollected ? '取消收藏' : '删除歌单'),
                ),
              ],
            ),
        ],
        songs: songs,
        // Only full-screen spinner when nothing to show yet.
        loading: _pager.initialLoading && songs.isEmpty,
        error: _loadError ?? _pager.initialError,
        scrollController: _scrollController,
        onRefresh: () => _load(force: true),
        onRetry: _load,
        songTrailing: (context, ref, song) => SongTileActions(
          song: song,
          onRemove: playlist.isWritable
              ? () => ref
                    .read(libraryRepositoryProvider)
                    .removeSong(playlist.localId!, song)
              : null,
        ),
        // Reuse the same footer used by public playlists / search.
        footerSlivers: loadMoreFooterSlivers(
          loading: _pager.loadingMore,
          error: songs.isNotEmpty ? _pager.loadMoreError : null,
          onRetry: () => _load(),
        ),
        queueRequest: (items) => ref
            .read(playbackQueueFactoryProvider)
            .libraryPlaylist(
              playlist: playlist,
              songs: items,
              count: count,
              nextPage: ((items.length + 99) ~/ 100) + 1,
              hasMore: items.length < count,
            ),
      ),
    );
  }

  Future<void> _edit(Playlist playlist) async {
    final result = await promptPlaylistEdit(
      context,
      name: playlist.name,
      intro: playlist.intro ?? '',
      tags: playlist.tags ?? '',
      private: playlist.isPrivate,
    );
    if (result == null) return;
    try {
      await ref
          .read(libraryRepositoryProvider)
          .editPlaylist(
            playlist.localId!,
            name: result.name,
            intro: result.intro,
            tags: result.tags,
            private: result.private,
          );
    } catch (_) {
      if (mounted) showAppError(context, '歌单信息保存失败，请稍后重试');
    }
  }

  Future<void> _delete(Playlist playlist) async {
    final accepted = await confirmDialog(
      context,
      title: playlist.isCollected ? '取消收藏歌单？' : '删除歌单？',
      content: playlist.isCollected ? '取消收藏后，这个歌单将从音乐库中移除。' : '删除后将无法恢复，请谨慎操作。',
    );
    if (!accepted) return;
    try {
      await ref
          .read(libraryRepositoryProvider)
          .deletePlaylist(playlist.localId!);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) showAppError(context, '歌单删除失败，请稍后重试');
    }
  }
}
