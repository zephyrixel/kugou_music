import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/cache/cache_policy.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/account_avatar_button.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';
import 'package:kgmusic/features/search/search_results.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  SearchKind _kind = SearchKind.songs;
  String _keyword = '';

  late final PagedListController<Song> _songPager;
  late final PagedListController<PlaylistSearchHit> _playlistPager;

  PagedListController get _activePager =>
      _kind == SearchKind.songs ? _songPager : _playlistPager;

  @override
  void initState() {
    super.initState();
    _songPager = PagedListController<Song>(
      pageSize: 30,
      itemId: (song) => song.id,
      fetchPage: (page, pageSize, forceRefresh) {
        final keyword = _keyword;
        final userId = ref.read(authControllerProvider).snapshot.userId;
        return ref
            .read(musicRepositoryProvider)
            .search(
              keyword,
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
    _playlistPager = PagedListController<PlaylistSearchHit>(
      pageSize: 30,
      itemId: (hit) =>
          hit.globalCollectionId ??
          hit.specialId?.toString() ??
          '${hit.name}:${hit.creatorUserId}',
      fetchPage: (page, pageSize, forceRefresh) {
        final keyword = _keyword;
        final userId = ref.read(authControllerProvider).snapshot.userId;
        return ref
            .read(musicRepositoryProvider)
            .searchPlaylists(
              keyword,
              userId: userId,
              page: page,
              pageSize: pageSize,
              mode: forceRefresh
                  ? CacheLoadMode.forceRefresh
                  : CacheLoadMode.normal,
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
    setState(() {});
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
    bottom: false,
    child: KgContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KgSpacing.lg,
              KgSpacing.xl,
              KgSpacing.lg,
              KgSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KgPageHeader(
                  title: '搜索',
                  subtitle: '发现歌曲与公开歌单',
                  padding: EdgeInsets.zero,
                  actions: [AccountAvatarButton()],
                ),
                const SizedBox(height: KgSpacing.lg),
                SegmentedButton<SearchKind>(
                  segments: const [
                    ButtonSegment(
                      value: SearchKind.songs,
                      icon: Icon(Icons.music_note_rounded),
                      label: Text('歌曲'),
                    ),
                    ButtonSegment(
                      value: SearchKind.playlists,
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
                const SizedBox(height: KgSpacing.sm),
                TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _runSearch,
                  decoration: InputDecoration(
                    hintText: _kind == SearchKind.songs ? '歌曲、歌手或专辑' : '搜索公开歌单',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '清空搜索',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                if (_keyword.isNotEmpty && _activePager.initialLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: KgSpacing.xs),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: KgMotion.resolve(context, KgMotion.medium),
              switchInCurve: KgMotion.standard,
              switchOutCurve: Curves.easeInCubic,
              child: SearchResults(
                key: ValueKey(_bodyKey),
                kind: _kind,
                keyword: _keyword,
                songPager: _songPager,
                playlistPager: _playlistPager,
                scrollController: _scrollController,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String get _bodyKey {
    if (_keyword.isEmpty) return 'empty';
    if (_activePager.initialLoading && _activePager.items.isEmpty) {
      return 'loading-$_kind';
    }
    if (_activePager.initialError != null && _activePager.items.isEmpty) {
      return 'error-$_kind';
    }
    return 'results-$_kind';
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _keyword = '');
  }
}
