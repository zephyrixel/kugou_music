import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
import 'package:kgmusic/features/home/home_discovery.dart';
import 'package:kgmusic/features/home/home_song_shelf.dart';

class HomeDiscoverySection extends ConsumerWidget {
  const HomeDiscoverySection({super.key, required this.cardId});

  final int cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(homeDiscoveryCardProvider(cardId));
    final child = value.when(
      skipLoadingOnRefresh: true,
      loading: () => const _SectionPadding(
        key: ValueKey('loading'),
        child: HomeSongShelfSkeleton(),
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
          key: ObjectKey(card),
          child: HomeSongShelf(
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
