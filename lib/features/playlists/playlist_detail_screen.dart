import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/core/widgets/song_tile_actions.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  const PlaylistDetailScreen({super.key, required this.source});
  final Object source;

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  static const _pageSize = 50;
  static const _loadMoreThreshold = 560.0;

  final _scrollController = ScrollController();
  List<Song> _songs = const [];
  Object? _initialError;
  Object? _loadMoreError;
  int? _total;
  int _nextPage = 1;
  int _loadGeneration = 0;
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  CloudPlaylist? get cloud =>
      widget.source is CloudPlaylist ? widget.source as CloudPlaylist : null;
  PlaylistSearchHit? get search => widget.source is PlaylistSearchHit
      ? widget.source as PlaylistSearchHit
      : null;
  String get title => cloud?.name ?? search?.name ?? '歌单';
  String? get artwork => cloud?.artworkUrl ?? search?.artworkUrl;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_load(reset: true));
  }

  @override
  void didUpdateWidget(covariant PlaylistDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) unawaited(_load(reset: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > _loadMoreThreshold) {
      return;
    }
    unawaited(_load());
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_initialLoading || _loadingMore || !_hasMore)) return;

    final generation = reset ? ++_loadGeneration : _loadGeneration;
    final requestedPage = reset ? 1 : _nextPage;
    setState(() {
      if (reset) {
        _songs = const [];
        _initialError = null;
        _loadMoreError = null;
        _total = null;
        _nextPage = 1;
        _initialLoading = true;
        _loadingMore = false;
        _hasMore = true;
      } else {
        _loadingMore = true;
        _loadMoreError = null;
      }
    });

    try {
      final sdk = ref.read(musicSdkProvider);
      final page = cloud != null
          ? await sdk.playlistTracks(
              cloud!,
              page: requestedPage,
              pageSize: _pageSize,
            )
          : await sdk.publicPlaylistTracks(
              search!.globalCollectionId!,
              page: requestedPage,
              pageSize: _pageSize,
            );
      if (!mounted || generation != _loadGeneration) return;

      final merged = reset ? <Song>[] : <Song>[..._songs];
      final knownSongIds = merged.map((song) => song.id).toSet();
      for (final song in page.songs) {
        if (knownSongIds.add(song.id)) merged.add(song);
      }
      final total = page.total ?? _total;
      final previousCount = reset ? 0 : _songs.length;
      setState(() {
        _songs = List.unmodifiable(merged);
        _total = total;
        _nextPage = page.page + 1;
        _hasMore =
            merged.length > previousCount &&
            canLoadNextPage(
              loadedItemCount: merged.length,
              lastPageItemCount: page.songs.length,
              pageSize: page.pageSize,
              total: total,
            );
        _initialLoading = false;
        _loadingMore = false;
      });
      try {
        await _cacheLoadedSongs();
      } catch (_) {
        // A local cache failure must not discard a successfully loaded page.
      }
      _loadAgainIfViewportIsShort();
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        if (reset) {
          _initialError = error;
          _initialLoading = false;
        } else {
          _loadMoreError = error;
          _loadingMore = false;
        }
      });
    }
  }

  Future<void> _cacheLoadedSongs() async {
    final userId = ref.read(authControllerProvider).snapshot.userId;
    if (cloud?.listId == null || userId == null) return;
    await ref
        .read(databaseProvider)
        .cacheCloudTracks(userId, cloud!.listId!, _songs);
  }

  void _loadAgainIfViewportIsShort() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.extentAfter <= _loadMoreThreshold) {
        unawaited(_load());
      }
    });
  }

  Future<void> _reload() => _load(reset: true);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      actions: [
        if (cloud != null && !cloud!.isSystem)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit' && !cloud!.isCollected) _edit();
              if (value == 'delete') _delete();
            },
            itemBuilder: (_) => [
              if (!cloud!.isCollected)
                const PopupMenuItem(value: 'edit', child: Text('编辑歌单')),
              PopupMenuItem(
                value: 'delete',
                child: Text(cloud!.isCollected ? '取消收藏' : '删除歌单'),
              ),
            ],
          ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _reload,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              title: title,
              artwork: artwork,
              count:
                  _total ?? cloud?.count ?? search?.songCount ?? _songs.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: _songs.isEmpty
                        ? null
                        : () => ref
                              .read(audioHandlerProvider)
                              .playSong(_songs.first, queueSongs: _songs),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('播放全部'),
                  ),
                  const Spacer(),
                  if (search != null)
                    OutlinedButton.icon(
                      onPressed: search!.globalCollectionId == null
                          ? null
                          : _collect,
                      icon: const Icon(Icons.library_add_outlined),
                      label: const Text('收藏歌单'),
                    ),
                ],
              ),
            ),
          ),
          if (_initialLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_initialError != null && _songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _PlaylistLoadError(error: _initialError!, retry: _reload),
            )
          else if (_songs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('歌单中没有歌曲')),
            )
          else
            SliverList.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return SongTile(
                  song: song,
                  index: index + 1,
                  onTap: () => ref
                      .read(audioHandlerProvider)
                      .playSong(song, queueSongs: _songs),
                  trailing: SongTileActions(
                    song: song,
                    onRemove: cloud?.isWritable == true && song.fileId != null
                        ? () => _remove(song)
                        : null,
                  ),
                );
              },
            ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else if (_loadMoreError != null)
            SliverToBoxAdapter(
              child: _PlaylistLoadError(error: _loadMoreError!, retry: _load),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    ),
  );

  Future<void> _collect() async {
    if (!ref.read(authControllerProvider).authenticated) {
      await context.push('/login');
      return;
    }
    try {
      await ref.read(musicSdkProvider).collectPlaylist(search!);
      ref.invalidate(cloudPlaylistsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('歌单已收藏')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _remove(Song song) async {
    try {
      await ref
          .read(musicSdkProvider)
          .removeSongFromPlaylist(cloud!.listId!, song.fileId!);
      ref.invalidate(myFavoriteSongsProvider);
      await _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _edit() async {
    final name = TextEditingController(text: cloud!.name);
    final intro = TextEditingController(text: cloud!.intro);
    final tags = TextEditingController(text: cloud!.tags);
    var private = cloud!.isPrivate;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑歌单'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: intro,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '简介'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tags,
                decoration: const InputDecoration(labelText: '标签（逗号分隔）'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('私密歌单'),
                value: private,
                onChanged: (value) => setState(() => private = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true) return;
    try {
      await ref
          .read(musicSdkProvider)
          .editPlaylist(
            PlaylistEditInput(
              listId: cloud!.listId!,
              name: name.text.trim(),
              intro: intro.text.trim(),
              tags: tags.text.trim(),
              private: private,
            ),
          );
      ref.invalidate(cloudPlaylistsProvider);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _delete() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cloud!.isCollected ? '取消收藏歌单？' : '删除歌单？'),
        content: Text('“${cloud!.name}”的操作会立即同步到酷狗云端。'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await ref.read(musicSdkProvider).deletePlaylist(cloud!);
      ref.invalidate(cloudPlaylistsProvider);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _PlaylistLoadError extends StatelessWidget {
  const _PlaylistLoadError({required this.error, required this.retry});

  final Object error;
  final Future<void> Function() retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => retry(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.artwork,
    required this.count,
  });
  final String title;
  final String? artwork;
  final int count;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
    child: Row(
      children: [
        SongArtwork(url: artwork, size: 118, radius: 24),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                '$count 首歌曲 · Lite 云歌单',
                style: const TextStyle(color: KgColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
