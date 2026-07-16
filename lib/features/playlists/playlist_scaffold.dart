import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/kg_glass_surface.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/core/widgets/song_tile_actions.dart';
import 'package:kgmusic/features/playlists/playlist_header.dart';

/// Shared playlist detail body: header + play-all row + loading/error/empty/list.
class PlaylistSongsView extends ConsumerWidget {
  const PlaylistSongsView({
    super.key,
    required this.title,
    required this.artwork,
    required this.cacheId,
    required this.count,
    required this.songs,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onRetry,
    this.subtitle,
    this.description,
    this.scrollController,
    this.appBarActions = const [],
    this.actions,
    this.trailing,
    this.footerSlivers = const [],
    this.songTrailing,
    this.queueRequest,
  });

  final String title;
  final String? artwork;
  final String cacheId;
  final int count;
  final String? subtitle;
  final String? description;
  final List<Song> songs;
  final bool loading;
  final Object? error;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetry;
  final ScrollController? scrollController;
  final List<Widget> appBarActions;

  /// Extra controls after the play-all button (e.g. collect).
  final List<Widget>? actions;

  /// Optional trailing widgets in the play-all row (right side).
  final Widget? trailing;

  /// Extra slivers after the song list (load-more indicator, etc.).
  final List<Widget> footerSlivers;

  /// Per-song trailing builder; defaults to [SongTileActions].
  final Widget Function(BuildContext context, WidgetRef ref, Song song)?
  songTrailing;

  final PlaybackQueueRequest Function(List<Song> songs)? queueRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 310,
            backgroundColor: KgColors.surface.withValues(alpha: 0.98),
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            actions: appBarActions,
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: PlaylistHeader(
                title: title,
                subtitle: subtitle,
                description: description,
                artwork: artwork,
                cacheId: cacheId,
                count: count,
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedControlDelegate(
              child: _PlaylistControls(
                songs: songs,
                title: title,
                actions: actions,
                trailing: trailing,
                onPlay: songs.isEmpty
                    ? null
                    : () => playSong(
                        context,
                        ref,
                        songs.first,
                        queueRequest:
                            queueRequest?.call(songs) ??
                            PlaybackQueueRequest.snapshot(
                              title: title,
                              songs: songs,
                            ),
                      ),
              ),
            ),
          ),
          if (loading && songs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null && songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: KgErrorView(error: error!, onRetry: onRetry),
            )
          else if (songs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: KgEmptyView('歌单中没有歌曲'),
            )
          else
            SliverList.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongTile(
                  song: song,
                  index: index + 1,
                  variant: SongTileVariant.indexed,
                  onTap: () => playSong(
                    context,
                    ref,
                    song,
                    queueRequest:
                        queueRequest?.call(songs) ??
                        PlaybackQueueRequest.snapshot(
                          title: title,
                          songs: songs,
                        ),
                  ),
                  trailing:
                      songTrailing?.call(context, ref, song) ??
                      SongTileActions(song: song),
                );
              },
            ),
          ...footerSlivers,
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _PlaylistControls extends StatelessWidget {
  const _PlaylistControls({
    required this.songs,
    required this.title,
    required this.onPlay,
    required this.actions,
    required this.trailing,
  });

  final List<Song> songs;
  final String title;
  final VoidCallback? onPlay;
  final List<Widget>? actions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => KgGlassSurface(
    borderRadius: BorderRadius.zero,
    color: KgColors.surface.withValues(alpha: 0.94),
    blurSigma: 14,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        KgSpacing.lg,
        KgSpacing.xs,
        KgSpacing.lg,
        KgSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(songs.isEmpty ? '暂无歌曲' : '播放全部'),
              style: FilledButton.styleFrom(
                backgroundColor: KgColors.accentSoft.withValues(alpha: 0.82),
                foregroundColor: KgColors.accent,
              ),
            ),
          ),
          if (actions?.isNotEmpty == true || trailing != null)
            const SizedBox(width: KgSpacing.sm),
          ...?actions,
          ?trailing,
        ],
      ),
    ),
  );
}

class _PinnedControlDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedControlDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 68;

  @override
  double get maxExtent => 68;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(covariant _PinnedControlDelegate oldDelegate) =>
      oldDelegate.child != child;
}
