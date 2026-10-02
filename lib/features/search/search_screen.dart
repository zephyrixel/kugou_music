import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/kg_motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/cache/cache_policy.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_choice_tabs.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';
import 'package:kgmusic/features/search/search_results.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _songScrollController = ScrollController();
  final _playlistScrollController = ScrollController();
  ScrollController get _scrollController => _kind == SearchKind.songs
      ? _songScrollController
      : _playlistScrollController;
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
    _songScrollController.addListener(_onScroll);
    _playlistScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _songPager.removeListener(_onPagerChanged);
    _playlistPager.removeListener(_onPagerChanged);
    _songPager.dispose();
    _playlistPager.dispose();
    _songScrollController.dispose();
    _playlistScrollController.dispose();
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
      _clearSearch();
      return;
    }
    setState(() {});
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_runSearch(trimmed)),
    );
  }

  Future<void> _runSearch(String keyword) async {
    _debounce?.cancel();
    if (!mounted) return;
    final normalized = keyword.trim();
    if (normalized.isEmpty) {
      _clearSearch();
      return;
    }
    final keywordChanged = normalized != _keyword;
    if (keywordChanged) {
      _songPager.clear();
      _playlistPager.clear();
    }
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 400;
          final search = TextField(
            controller: _controller,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: _runSearch,
            decoration: InputDecoration(
              hintText: _kind == SearchKind.songs ? '歌曲、歌手或专辑' : '搜索公开歌单',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: KgStateTransition(
                alignment: Alignment.center,
                child: _controller.text.isEmpty
                    ? const SizedBox(width: 48)
                    : IconButton(
                        tooltip: '清空搜索',
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          );
          final tabs = KgChoiceTabs<SearchKind>(
            options: const {SearchKind.songs: '歌曲', SearchKind.playlists: '歌单'},
            value: _kind,
            onChanged: (next) {
              setState(() => _kind = next);
              if (_scrollController.hasClients) _scrollController.jumpTo(0);
              if (_keyword.isNotEmpty) unawaited(_activePager.reset());
            },
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, compact ? 12 : 24, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!compact) ...[
                      const KgPageHeader(title: '搜索', padding: EdgeInsets.zero),
                      const SizedBox(height: 20),
                    ],
                    if (compact && constraints.maxWidth >= 600)
                      Row(
                        children: [
                          Expanded(child: search),
                          const SizedBox(width: 20),
                          tabs,
                        ],
                      )
                    else ...[
                      search,
                      const SizedBox(height: 8),
                      tabs,
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 2,
                        child:
                            _keyword.isNotEmpty && _activePager.initialLoading
                            ? const LinearProgressIndicator(minHeight: 2)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: KgStateTransition(
                  retainOutgoing: false,
                  duration: KgMotion.resolve(context, KgMotion.medium),
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
          );
        },
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
    _songPager.clear();
    _playlistPager.clear();
    setState(() => _keyword = '');
  }
}
