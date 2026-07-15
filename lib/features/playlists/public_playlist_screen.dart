import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/features/playlists/playlist_header.dart';
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
  static const _loadMoreThreshold = 560.0;

  final _scrollController = ScrollController();
  final Map<int, SearchPage> _pages = {};
  List<Song> _songs = const [];
  Object? _initialError;
  Object? _loadMoreError;
  int? _total;
  int _nextPage = 1;
  int _generation = 0;
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_load(reset: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter <= _loadMoreThreshold) {
      unawaited(_load());
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_initialLoading || _loadingMore || !_hasMore)) return;
    final generation = reset ? ++_generation : _generation;
    final requestedPage = reset ? 1 : _nextPage;
    setState(() {
      if (reset) {
        _songs = const [];
        _pages.clear();
        _initialError = null;
        _loadMoreError = null;
        _total = null;
        _nextPage = 1;
        _initialLoading = true;
        _hasMore = true;
      } else {
        _loadingMore = true;
        _loadMoreError = null;
      }
    });

    try {
      final userId = ref.read(authControllerProvider).snapshot.userId;
      await for (final page
          in ref
              .read(musicRepositoryProvider)
              .publicPlaylistTracks(
                widget.playlist.globalCollectionId!,
                userId: userId,
                page: requestedPage,
                pageSize: _pageSize,
              )) {
        if (!mounted || generation != _generation) return;
        _pages[page.page] = page;
        final merged = <Song>[];
        final known = <String>{};
        final pages = _pages.values.toList()
          ..sort((a, b) => a.page.compareTo(b.page));
        for (final snapshot in pages) {
          for (final song in snapshot.songs) {
            if (known.add(song.id)) merged.add(song);
          }
        }
        final total = page.total ?? _total;
        setState(() {
          _songs = List.unmodifiable(merged);
          _total = total;
          _nextPage = _pages.keys.reduce((a, b) => a > b ? a : b) + 1;
          _hasMore = canLoadNextPage(
            loadedItemCount: merged.length,
            lastPageItemCount: page.songs.length,
            pageSize: page.pageSize,
            total: total,
          );
          _initialLoading = false;
        });
      }
      if (mounted) setState(() => _loadingMore = false);
      _loadAgainIfShort();
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        if (reset) {
          _initialError = error;
          _initialLoading = false;
        } else {
          _loadMoreError = error;
        }
        _loadingMore = false;
      });
    }
  }

  void _loadAgainIfShort() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _scrollController.hasClients &&
          _scrollController.position.extentAfter <= _loadMoreThreshold) {
        unawaited(_load());
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: Colors.transparent),
    body: PlaylistSongsView(
      title: widget.playlist.name,
      artwork: widget.playlist.artworkUrl,
      cacheId: 'playlist:${widget.playlist.globalCollectionId}',
      count: _total ?? widget.playlist.songCount ?? _songs.length,
      songs: _songs,
      loading: _initialLoading,
      error: _initialError,
      scrollController: _scrollController,
      onRefresh: () => _load(reset: true),
      onRetry: () => _load(reset: true),
      trailing: OutlinedButton.icon(
        onPressed: widget.playlist.globalCollectionId == null ? null : _collect,
        icon: const Icon(Icons.library_add_outlined),
        label: const Text('收藏歌单'),
      ),
      footerSlivers: [
        if (_loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else if (_loadMoreError != null)
          SliverToBoxAdapter(
            child: PlaylistLoadError(error: _loadMoreError!, retry: _load),
          ),
      ],
    ),
  );

  Future<void> _collect() async {
    try {
      await ref.read(libraryRepositoryProvider).collectPlaylist(widget.playlist);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已收藏')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
