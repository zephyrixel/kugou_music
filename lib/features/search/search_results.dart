import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/paged_list_controller.dart';
import 'package:kgmusic/core/widgets/paged_list_footer.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
import 'package:kgmusic/core/widgets/playlist_tile.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/core/widgets/song_tile_actions.dart';

enum SearchKind { songs, playlists }

class SearchResults extends ConsumerWidget {
  const SearchResults({
    super.key,
    required this.kind,
    required this.keyword,
    required this.songPager,
    required this.playlistPager,
    required this.scrollController,
  });

  final SearchKind kind;
  final String keyword;
  final PagedListController<Song> songPager;
  final PagedListController<PlaylistSearchHit> playlistPager;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (keyword.isEmpty) {
      return const KgEmptyView(
        '输入歌曲、歌手或歌单名称',
        icon: Icons.travel_explore_rounded,
      );
    }
    return kind == SearchKind.songs
        ? _buildSongResults(context, ref)
        : _buildPlaylistResults(context);
  }

  Widget _buildSongResults(BuildContext context, WidgetRef ref) => _buildState(
    pager: songPager,
    errorMessage: '歌曲搜索暂时不可用，请稍后重试',
    results: () {
      final songs = songPager.items;
      final footers = pagedListFooters(songPager);
      return ListView.builder(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + KgSpacing.xl,
        ),
        itemCount: songs.length + footers.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _ResultsSummary(count: songPager.total ?? songs.length);
          }
          final itemIndex = index - 1;
          if (itemIndex >= songs.length) {
            return footers[itemIndex - songs.length];
          }
          final song = songs[itemIndex];
          return SongTile(
            song: song,
            variant: SongTileVariant.artwork,
            onTap: () => playSong(
              context,
              ref,
              song,
              queueRequest: ref
                  .read(playbackQueueFactoryProvider)
                  .search(
                    keyword: keyword,
                    songs: songs,
                    nextPage: songPager.nextPage,
                    hasMore: songPager.hasMore,
                    total: songPager.total,
                    userId: ref.read(authControllerProvider).snapshot.userId,
                    pageSize: songPager.pageSize,
                  ),
            ),
            trailing: SongTileActions(song: song),
          );
        },
      );
    },
  );

  Widget _buildPlaylistResults(BuildContext context) => _buildState(
    pager: playlistPager,
    errorMessage: '歌单搜索暂时不可用，请稍后重试',
    results: () {
      final playlists = playlistPager.items;
      final footers = pagedListFooters(playlistPager);
      return ListView.builder(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          KgSpacing.sm,
          0,
          KgSpacing.sm,
          MediaQuery.paddingOf(context).bottom + KgSpacing.xl,
        ),
        itemCount: playlists.length + footers.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _ResultsSummary(
              count: playlistPager.total ?? playlists.length,
            );
          }
          final itemIndex = index - 1;
          if (itemIndex >= playlists.length) {
            return footers[itemIndex - playlists.length];
          }
          final playlist = playlists[itemIndex];
          return PlaylistTile(
            title: playlist.name,
            subtitle:
                '${playlist.creatorName ?? '未知创建者'} · ${playlist.songCount ?? 0} 首',
            artworkUrl: playlist.artworkUrl,
            cacheId:
                'playlist:${playlist.globalCollectionId ?? playlist.specialId}',
            enabled: playlist.globalCollectionId != null,
            onTap: () => context.push(
              '/playlist',
              extra: PlaylistTarget.public(playlist),
            ),
          );
        },
      );
    },
  );

  Widget _buildState<T>({
    required PagedListController<T> pager,
    required String errorMessage,
    required Widget Function() results,
  }) {
    if (pager.initialLoading && pager.items.isEmpty) {
      return const KgLoadingView();
    }
    if (pager.initialError != null && pager.items.isEmpty) {
      return KgErrorView(message: errorMessage, onRetry: pager.reset);
    }
    if (pager.items.isEmpty) {
      return const KgEmptyView('没有找到匹配结果', icon: Icons.search_off_rounded);
    }
    return results();
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
    child: Text(
      '找到 $count 个结果',
      style: const TextStyle(color: KgColors.textMuted, fontSize: 13),
    ),
  );
}
