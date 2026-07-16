import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';
import 'package:kgmusic/core/widgets/paged_list_footer.dart';
import 'package:kgmusic/features/playlists/library_playlist_pager.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 2,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KgPageHeader(title: '音乐库', subtitle: '收藏与最近听过的音乐'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: KgColors.elevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const TabBar(
                indicator: BoxDecoration(
                  color: KgColors.elevatedHigh,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: '收藏'),
                  Tab(text: '最近播放'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [const _FavoriteSongs(), const _HistorySongs()],
            ),
          ),
        ],
      ),
    ),
  );
}

class _FavoriteSongs extends ConsumerStatefulWidget {
  const _FavoriteSongs();

  @override
  ConsumerState<_FavoriteSongs> createState() => _FavoriteSongsState();
}

class _FavoriteSongsState extends ConsumerState<_FavoriteSongs> {
  final _scrollController = ScrollController();
  PagedListController<Song>? _pager;
  String? _localId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pager = _pager;
    if (pager != null && _scrollController.hasClients) {
      pager.onScroll(_scrollController.position);
    }
  }

  void _bindPager(String localId) {
    if (_localId == localId && _pager != null) return;
    _pager?.dispose();
    final pager = createLibraryPlaylistPager(
      repository: ref.read(libraryRepositoryProvider),
      localId: localId,
    );
    _localId = localId;
    _pager = pager;
    pager.addListener(_onPagerChanged);
    pager.attach();
  }

  void _onPagerChanged() {
    if (mounted) setState(() {});
    _pager?.loadAgainIfShort(_scrollController);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pager?.removeListener(_onPagerChanged);
    _pager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(favoriteSongsProvider);
    final favorite = (ref.watch(libraryPlaylistsProvider).value ?? const [])
        .where((playlist) => playlist.isMyFavorite)
        .firstOrNull;
    final localId = favorite?.localId;
    if (localId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bindPager(localId);
      });
    }
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          KgErrorView(error: error, onRetry: () async => _pager?.reset()),
      data: (songs) {
        if (songs.isEmpty && (_pager?.initialLoading ?? false)) {
          return const Center(child: CircularProgressIndicator());
        }
        if (songs.isEmpty) {
          return const KgEmptyView(
            '还没有收藏歌曲',
            icon: Icons.favorite_border_rounded,
          );
        }
        return _SongCollectionList(
          songs: songs,
          label: '${songs.length} 首收藏',
          scrollController: _scrollController,
          pager: _pager,
          onRefresh: () async {
            await _pager?.reset(forceRefresh: true, keepItems: true);
          },
          queueRequest: favorite?.localId == null
              ? null
              : (items) => ref
                    .read(playbackQueueFactoryProvider)
                    .libraryPlaylist(
                      playlist: favorite!,
                      songs: items,
                      count: favorite.count,
                      nextPage: ((items.length + 99) ~/ 100) + 1,
                      hasMore: items.length < favorite.count,
                    ),
          trailingBuilder: (song) => IconButton(
            tooltip: '取消喜欢',
            onPressed: () =>
                ref.read(libraryRepositoryProvider).toggleFavorite(song),
            icon: const Icon(Icons.favorite_rounded, size: 20),
          ),
        );
      },
    );
  }
}

class _HistorySongs extends ConsumerWidget {
  const _HistorySongs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(historyEntriesProvider);
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => KgErrorView(
        error: error,
        onRetry: () async => ref.invalidate(historyEntriesProvider),
      ),
      data: (entries) {
        final songs = entries
            .map((entry) => entry.song)
            .toList(growable: false);
        if (songs.isEmpty) {
          return const KgEmptyView('播放记录会出现在这里', icon: Icons.history_rounded);
        }
        return _SongCollectionList(songs: songs, label: '最近 ${songs.length} 首');
      },
    );
  }
}

class _SongCollectionList extends ConsumerWidget {
  const _SongCollectionList({
    required this.songs,
    required this.label,
    this.trailingBuilder,
    this.queueRequest,
    this.scrollController,
    this.pager,
    this.onRefresh,
  });

  final List<Song> songs;
  final String label;
  final Widget Function(Song song)? trailingBuilder;
  final PlaybackQueueRequest Function(List<Song> songs)? queueRequest;
  final ScrollController? scrollController;
  final PagedListController<Song>? pager;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final footers = pager == null ? const <Widget>[] : pagedListFooters(pager!);
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: songs.length + 1 + footers.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(color: KgColors.textMuted),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => playSong(
                      context,
                      ref,
                      songs.first,
                      queueRequest:
                          queueRequest?.call(songs) ??
                          PlaybackQueueRequest.snapshot(
                            title: label.contains('收藏') ? '我喜欢' : '最近播放',
                            songs: songs,
                            kind: label.contains('收藏')
                                ? PlaybackQueueOriginKind.favorites
                                : PlaybackQueueOriginKind.history,
                          ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('播放全部'),
                  ),
                ],
              ),
            );
          }
          if (index > songs.length) return footers[index - songs.length - 1];
          final song = songs[index - 1];
          return SongTile(
            song: song,
            onTap: () => playSong(
              context,
              ref,
              song,
              queueRequest:
                  queueRequest?.call(songs) ??
                  PlaybackQueueRequest.snapshot(
                    title: label.contains('收藏') ? '我喜欢' : '最近播放',
                    songs: songs,
                    kind: label.contains('收藏')
                        ? PlaybackQueueOriginKind.favorites
                        : PlaybackQueueOriginKind.history,
                  ),
            ),
            trailing: trailingBuilder?.call(song),
          );
        },
      ),
    );
  }
}
