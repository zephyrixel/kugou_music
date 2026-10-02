import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/playback_song_tile.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
import 'package:kgmusic/features/home/home_discovery.dart';
import 'package:kgmusic/features/home/home_song_shelf.dart';

class HomeDiscoverySection extends ConsumerWidget {
  const HomeDiscoverySection({
    super.key,
    required this.cardId,
    this.rowLayout = false,
  });

  final int cardId;
  final bool rowLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(homeDiscoveryCardProvider(cardId));
    final child = value.when(
      skipLoadingOnRefresh: true,
      loading: () => _SectionPadding(
        key: const ValueKey('loading'),
        child: rowLayout
            ? const KgSongListSkeleton(rows: 3)
            : const HomeSongShelfSkeleton(),
      ),
      error: (_, _) => _SectionPadding(
        key: const ValueKey('error'),
        child: KgErrorView(
          compact: true,
          message: '一组推荐暂时无法加载',
          onRetry: () async =>
              ref.invalidate(homeDiscoveryCardProvider(cardId)),
        ),
      ),
      data: (card) {
        if (card.songs.isEmpty) return const SizedBox.shrink();
        void play(Song cardSong) => unawaited(
          playSong(
            context,
            ref,
            cardSong,
            queueRequest: PlaybackQueueRequest.snapshot(
              title: card.title,
              id: card.id.toString(),
              songs: card.songs,
              kind: PlaybackQueueOriginKind.discovery,
            ),
          ),
        );

        return _SectionPadding(
          key: ValueKey(card.id),
          child: rowLayout
              ? _DiscoverySongRows(
                  title: card.title,
                  songs: card.songs,
                  onPlay: play,
                  scrollKey: 'discovery-rows:${card.id}',
                )
              : HomeSongShelf(
                  title: card.title,
                  subtitle: card.subtitle,
                  songs: card.songs,
                  scrollKey: 'discovery:${card.id}',
                  onSongTap: play,
                  onPlayAll: () => play(card.songs.first),
                ),
        );
      },
    );
    return AnimatedSwitcher(
      duration: KgMotion.resolve(context, KgMotion.fast),
      switchInCurve: KgMotion.standard,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}

class _DiscoverySongRows extends StatelessWidget {
  const _DiscoverySongRows({
    required this.title,
    required this.songs,
    required this.onPlay,
    required this.scrollKey,
  });
  final String title;
  final List<Song> songs;
  final ValueChanged<Song> onPlay;
  final String scrollKey;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scaler = MediaQuery.textScalerOf(context);
      final rowHeight = (scaler.scale(16) * 1.4 + scaler.scale(13) * 1.4 + 28)
          .clamp(80.0, double.infinity);
      final rows = songs.length.clamp(1, 3);
      final width = constraints.maxWidth >= 600 ? 360.0 : constraints.maxWidth;
      return Column(
        children: [
          KgSectionHeader(
            title: title,
            action: IconButton(
              tooltip: '播放全部',
              onPressed: () => onPlay(songs.first),
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: rowHeight * rows,
            child: ListView.builder(
              key: PageStorageKey(scrollKey),
              scrollDirection: Axis.horizontal,
              itemCount: (songs.length / rows).ceil(),
              itemBuilder: (context, group) => SizedBox(
                width: width,
                child: Column(
                  children: [
                    for (
                      var row = 0;
                      row < rows && group * rows + row < songs.length;
                      row++
                    )
                      SizedBox(
                        height: rowHeight,
                        child: PlaybackSongTile(
                          song: songs[group * rows + row],
                          onTap: () => onPlay(songs[group * rows + row]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _SectionPadding extends StatelessWidget {
  const _SectionPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      KgSpacing.lg,
      0,
      KgSpacing.lg,
      KgSpacing.section,
    ),
    child: child,
  );
}
