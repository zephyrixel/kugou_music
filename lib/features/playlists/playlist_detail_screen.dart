import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
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
  final Map<int, SearchPage> _pages = {};
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
        _pages.clear();
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
      final userId = ref.read(authControllerProvider).snapshot.userId;
      final pages = cloud != null
          ? ref
                .read(musicRepositoryProvider)
                .playlistTracks(
                  userId!,
                  cloud!,
                  page: requestedPage,
                  pageSize: _pageSize,
                )
          : ref
                .read(musicRepositoryProvider)
                .publicPlaylistTracks(
                  search!.globalCollectionId!,
                  userId: userId,
                  page: requestedPage,
                  pageSize: _pageSize,
                );
      await for (final page in pages) {
        if (!mounted || generation != _loadGeneration) return;
        _pages[page.page] = page;
        final merged = <Song>[];
        final knownSongIds = <String>{};
        final snapshots = _pages.values.toList()
          ..sort((a, b) => a.page.compareTo(b.page));
        for (final snapshot in snapshots) {
          for (final song in snapshot.songs) {
            if (knownSongIds.add(song.id)) merged.add(song);
          }
        }
        final total = page.total ?? _total;
        setState(() {
          _songs = List.unmodifiable(merged);
          _total = total;
          _nextPage = _pages.keys.isEmpty
              ? 1
              : _pages.keys.reduce((a, b) => a > b ? a : b) + 1;
          _hasMore = canLoadNextPage(
            loadedItemCount: merged.length,
            lastPageItemCount: page.songs.length,
            pageSize: page.pageSize,
            total: total,
          );
          _initialLoading = false;
          _loadingMore = true;
        });
      }
      if (mounted) {
        setState(() => _loadingMore = false);
      }
      _loadAgainIfViewportIsShort();
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      final authenticationFailed =
          error is MusicSdkException &&
          (error.expired || error.authenticationRequired);
      setState(() {
        if (authenticationFailed) {
          _pages.clear();
          _songs = const [];
        }
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
              cacheId:
                  'playlist:${cloud?.listId ?? search?.globalCollectionId}',
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
      final userId = ref.read(authControllerProvider).snapshot.userId;
      if (userId == null) return;
      await ref.read(musicRepositoryProvider).collectPlaylist(userId, search!);
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
      final userId = ref.read(authControllerProvider).snapshot.userId;
      if (userId == null) return;
      await ref
          .read(musicRepositoryProvider)
          .removeSongFromPlaylist(userId, cloud!.listId!, song.fileId!);
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
      final userId = ref.read(authControllerProvider).snapshot.userId;
      if (userId == null) return;
      await ref
          .read(musicRepositoryProvider)
          .editPlaylist(
            userId,
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
      final userId = ref.read(authControllerProvider).snapshot.userId;
      if (userId == null) return;
      await ref.read(musicRepositoryProvider).deletePlaylist(userId, cloud!);
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
    required this.cacheId,
    required this.count,
  });
  final String title;
  final String? artwork;
  final String cacheId;
  final int count;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
    child: Row(
      children: [
        SongArtwork(url: artwork, cacheId: cacheId, size: 118, radius: 24),
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
