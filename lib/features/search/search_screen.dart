import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';
import 'package:kgmusic/core/widgets/paged_list_footer.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/core/widgets/song_tile_actions.dart';
import 'package:kgmusic/features/playlists/playlist_header.dart';

enum _SearchKind { songs, playlists }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  _SearchKind _kind = _SearchKind.songs;
  String _keyword = '';

  late final PagedListController<Song> _songPager;
  late final PagedListController<PlaylistSearchHit> _playlistPager;

  PagedListController get _activePager =>
      _kind == _SearchKind.songs ? _songPager : _playlistPager;

  @override
  void initState() {
    super.initState();
    _songPager = PagedListController<Song>(
      pageSize: 30,
      itemId: (song) => song.id,
      fetchPage: (page, pageSize) {
        final keyword = _keyword;
        final userId = ref.read(authControllerProvider).snapshot.userId;
        return ref
            .read(musicRepositoryProvider)
            .search(keyword, userId: userId, page: page, pageSize: pageSize)
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
    _playlistPager = PagedListController<PlaylistSearchHit>(
      pageSize: 30,
      itemId: (hit) =>
          hit.globalCollectionId ??
          hit.specialId?.toString() ??
          '${hit.name}:${hit.creatorUserId}',
      fetchPage: (page, pageSize) {
        final keyword = _keyword;
        final userId = ref.read(authControllerProvider).snapshot.userId;
        return ref
            .read(musicRepositoryProvider)
            .searchPlaylists(
              keyword,
              userId: userId,
              page: page,
              pageSize: pageSize,
            )
            .map(
              (result) => PageSnapshot(
                items: result.items,
                page: result.page,
                pageSize: result.pageSize,
                total: result.total,
              ),
            );
      },
    );
    _songPager.addListener(_onPagerChanged);
    _playlistPager.addListener(_onPagerChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _songPager.removeListener(_onPagerChanged);
    _playlistPager.removeListener(_onPagerChanged);
    _songPager.dispose();
    _playlistPager.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPagerChanged() {
    if (mounted) setState(() {});
    _activePager.loadAgainIfShort(_scrollController);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _activePager.onScroll(_scrollController.position);
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _keyword = '');
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_runSearch(trimmed)),
    );
  }

  Future<void> _runSearch(String keyword) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) {
      setState(() => _keyword = '');
      return;
    }
    final keywordChanged = normalized != _keyword;
    setState(() => _keyword = normalized);
    if (keywordChanged && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    await _activePager.reset();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('搜索', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),
              SegmentedButton<_SearchKind>(
                segments: const [
                  ButtonSegment(
                    value: _SearchKind.songs,
                    icon: Icon(Icons.music_note_rounded),
                    label: Text('歌曲'),
                  ),
                  ButtonSegment(
                    value: _SearchKind.playlists,
                    icon: Icon(Icons.queue_music_rounded),
                    label: Text('歌单'),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (value) {
                  final next = value.first;
                  if (next == _kind) return;
                  setState(() => _kind = next);
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(0);
                  }
                  if (_keyword.isNotEmpty) {
                    unawaited(_activePager.reset());
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: _runSearch,
                decoration: InputDecoration(
                  hintText: _kind == _SearchKind.songs ? '歌曲、歌手或专辑' : '搜索公开歌单',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
              if (_keyword.isNotEmpty && _activePager.initialLoading)
                const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        ),
        Expanded(child: _body()),
      ],
    ),
  );

  Widget _body() {
    if (_keyword.isEmpty) {
      return const _Empty(query: '');
    }
    final pager = _activePager;
    if (pager.initialLoading && pager.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (pager.initialError != null && pager.items.isEmpty) {
      return PlaylistLoadError(
        error: pager.initialError!,
        retry: () => pager.reset(),
      );
    }
    if (pager.items.isEmpty) {
      return _Empty(query: _keyword);
    }
    return _kind == _SearchKind.songs ? _songResults() : _playlistResults();
  }

  Widget _songResults() {
    final songs = _songPager.items;
    final footers = pagedListFooters(_songPager);
    return ListView.builder(
      controller: _scrollController,
      itemCount: songs.length + footers.length,
      itemBuilder: (context, index) {
        if (index >= songs.length) {
          return footers[index - songs.length];
        }
        final song = songs[index];
        return SongTile(
          song: song,
          onTap: () => playSong(context, ref, song, queue: songs),
          trailing: SongTileActions(song: song),
        );
      },
    );
  }

  Widget _playlistResults() {
    final playlists = _playlistPager.items;
    final footers = pagedListFooters(_playlistPager);
    return ListView.builder(
      controller: _scrollController,
      itemCount: playlists.length + footers.length,
      itemBuilder: (context, index) {
        if (index >= playlists.length) {
          return footers[index - playlists.length];
        }
        final playlist = playlists[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 5,
          ),
          leading: SongArtwork(
            url: playlist.artworkUrl,
            cacheId:
                'playlist:${playlist.globalCollectionId ?? playlist.specialId}',
          ),
          title: Text(
            playlist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${playlist.creatorName ?? '未知创建者'} · ${playlist.songCount ?? 0} 首',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: playlist.globalCollectionId == null
              ? null
              : () => context.push('/playlist', extra: playlist),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.query});
  final String query;
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      query.isEmpty ? '输入关键词，探索 Lite 曲库' : '没有找到结果',
      style: const TextStyle(color: KgColors.textMuted),
    ),
  );
}
