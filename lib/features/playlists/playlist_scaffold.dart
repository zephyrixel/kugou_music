import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
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
    this.scrollController,
    this.actions,
    this.trailing,
    this.footerSlivers = const [],
    this.songTrailing,
  });

  final String title;
  final String? artwork;
  final String cacheId;
  final int count;
  final List<Song> songs;
  final bool loading;
  final Object? error;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetry;
  final ScrollController? scrollController;

  /// Extra controls after the play-all button (e.g. collect).
  final List<Widget>? actions;

  /// Optional trailing widgets in the play-all row (right side).
  final Widget? trailing;

  /// Extra slivers after the song list (load-more indicator, etc.).
  final List<Widget> footerSlivers;

  /// Per-song trailing builder; defaults to [SongTileActions].
  final Widget Function(BuildContext context, WidgetRef ref, Song song)?
  songTrailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: PlaylistHeader(
              title: title,
              artwork: artwork,
              cacheId: cacheId,
              count: count,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: songs.isEmpty
                        ? null
                        : () => playSong(
                            context,
                            ref,
                            songs.first,
                            queue: songs,
                          ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('播放全部'),
                  ),
                  ...?actions,
                  if (trailing != null) const Spacer(),
                  ?trailing,
                ],
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
                  onTap: () => playSong(context, ref, song, queue: songs),
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
