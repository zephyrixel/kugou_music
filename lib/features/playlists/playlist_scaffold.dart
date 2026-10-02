import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/artwork_backdrop.dart';
import 'package:kgmusic/core/widgets/playback_insets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/core/widgets/playback_song_tile.dart';
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
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 380,
          child: IgnorePointer(
            child: ArtworkBackdrop(
              url: artwork,
              cacheId: cacheId,
              opacity: 0.78,
              overlayGradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x55101012),
                  Color(0x99101012),
                  KgColors.background,
                ],
                stops: [0, 0.4, 1],
              ),
            ),
          ),
        ),
        KgContentWidth(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: CustomScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverLayoutBuilder(
                  builder: (context, constraints) => SliverAppBar(
                    pinned: true,
                    backgroundColor: KgColors.background.withValues(
                      alpha: (constraints.scrollOffset / 120).clamp(0, 1),
                    ),
                    actions: appBarActions,
                    title: Opacity(
                      opacity: (constraints.scrollOffset / 120).clamp(0, 1),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, KgColors.background],
                      ),
                    ),
                    child: PlaylistHeader(
                      title: title,
                      subtitle: subtitle,
                      description: description,
                      artwork: artwork,
                      cacheId: cacheId,
                      count: count,
                    ),
                  ),
                ),
                PinnedHeaderSliver(
                  child: _PlaylistControls(
                    count: count,
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
                if (loading && songs.isEmpty)
                  const SliverToBoxAdapter(child: KgSongListSkeleton())
                else if (error != null && songs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: KgErrorView(message: '歌单加载失败', onRetry: onRetry),
                  )
                else if (songs.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: KgEmptyView('歌单中没有歌曲'),
                  )
                else
                  DecoratedSliver(
                    decoration: const BoxDecoration(color: KgColors.background),
                    sliver: SliverList.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return PlaybackSongTile(
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
                  ),
                ...footerSlivers,
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: PlaybackInsets.scrollPadding(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaylistControls extends StatelessWidget {
  const _PlaylistControls({
    required this.count,
    required this.onPlay,
    required this.actions,
    required this.trailing,
  });

  final int count;
  final VoidCallback? onPlay;
  final List<Widget>? actions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: KgColors.background,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(KgSpacing.lg, 8, KgSpacing.lg, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('播放全部'),
          ),
          Text('$count 首', style: Theme.of(context).textTheme.bodySmall),
          ...?actions,
          ?trailing,
        ],
      ),
    ),
  );
}
