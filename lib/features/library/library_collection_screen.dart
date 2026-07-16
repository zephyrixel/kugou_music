import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';
import 'package:kgmusic/core/widgets/paged_list_footer.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/features/playlists/library_playlist_pager.dart';

enum LibraryCollectionKind { favorites, history }

class LibraryCollectionScreen extends ConsumerWidget {
  const LibraryCollectionScreen({super.key, required this.kind});

  final LibraryCollectionKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(kind == LibraryCollectionKind.favorites ? '我喜欢' : '最近播放'),
    ),
    body: kind == LibraryCollectionKind.favorites
        ? const _FavoriteSongs()
        : const _HistorySongs(),
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
    if (_pager case final pager? when _scrollController.hasClients) {
      pager.onScroll(_scrollController.position);
    }
  }

  void _bindPager(String localId) {
    if (_localId == localId && _pager != null) return;
    _pager?.removeListener(_onPagerChanged);
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
    if (favorite?.localId case final localId?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bindPager(localId);
      });
    }
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => const KgLoadingView(label: '正在读取收藏'),
      error: (error, _) =>
          KgErrorView(error: error, onRetry: () async => _pager?.reset()),
      data: (songs) => _SongCollectionView(
        songs: songs,
        emptyMessage: '还没有收藏歌曲',
        label: '${songs.length} 首收藏',
        scrollController: _scrollController,
        pager: _pager,
        onRefresh: () async =>
            _pager?.reset(forceRefresh: true, keepItems: true),
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
      ),
    );
  }
}

class _HistorySongs extends ConsumerWidget {
  const _HistorySongs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(historyEntriesProvider);
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => const KgLoadingView(label: '正在读取播放记录'),
      error: (error, _) => KgErrorView(
        error: error,
        onRetry: () async => ref.invalidate(historyEntriesProvider),
      ),
      data: (entries) => _SongCollectionView(
        songs: entries.map((entry) => entry.song).toList(growable: false),
        emptyMessage: '播放记录会出现在这里',
        label: '最近 ${entries.length} 首',
      ),
    );
  }
}

class _SongCollectionView extends ConsumerWidget {
  const _SongCollectionView({
    required this.songs,
    required this.emptyMessage,
    required this.label,
    this.trailingBuilder,
    this.queueRequest,
    this.scrollController,
    this.pager,
    this.onRefresh,
  });

  final List<Song> songs;
  final String emptyMessage;
  final String label;
  final Widget Function(Song song)? trailingBuilder;
  final PlaybackQueueRequest Function(List<Song> songs)? queueRequest;
  final ScrollController? scrollController;
  final PagedListController<Song>? pager;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (songs.isEmpty && (pager?.initialLoading ?? false)) {
      return const KgLoadingView(label: '正在加载歌曲');
    }
    if (songs.isEmpty) {
      return KgEmptyView(emptyMessage, icon: Icons.music_note_rounded);
    }
    final footers = pager == null ? const <Widget>[] : pagedListFooters(pager!);
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        key: PageStorageKey('collection-$label'),
        controller: scrollController,
        padding: const EdgeInsets.only(top: KgSpacing.xs, bottom: KgSpacing.xl),
        itemCount: songs.length + 1 + footers.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                KgSpacing.lg,
                KgSpacing.xs,
                KgSpacing.lg,
                KgSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(label)),
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
                    icon: const Icon(Icons.play_arrow_rounded),
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
            variant: SongTileVariant.artwork,
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
