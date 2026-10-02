import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/widgets/artwork_backdrop.dart';
import 'package:kgmusic/core/widgets/playback_insets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/cache/cache_policy.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
import 'package:kgmusic/features/home/discover_sections.dart';
import 'package:kgmusic/features/home/home_discovery.dart';
import 'package:kgmusic/features/home/home_discovery_section.dart';
import 'package:kgmusic/features/home/home_song_shelf.dart';
import 'package:kgmusic/features/home/recommendation_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(dailyRecommendationsProvider);
    final songs = recommendations.value ?? const <Song>[];
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 440,
          child: IgnorePointer(
            child: ArtworkBackdrop(
              url: songs.firstOrNull?.artworkUrl,
              cacheId: 'song:${songs.firstOrNull?.id ?? 'daily'}',
              opacity: 0.65,
              overlayGradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x50101012),
                  Color(0xA0101012),
                  KgColors.background,
                ],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: KgContentWidth(
            child: RefreshIndicator(
              onRefresh: () => _refresh(context, ref),
              child: CustomScrollView(
                key: const PageStorageKey('discover-scroll'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      KgSpacing.lg,
                      KgSpacing.xl,
                      KgSpacing.lg,
                      KgSpacing.section,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DiscoverHeader(),
                          const SizedBox(height: KgSpacing.xl),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final hero = DailyRecommendationHero(
                                songs: songs,
                                loading:
                                    recommendations.isLoading && songs.isEmpty,
                                failed:
                                    recommendations.hasError && songs.isEmpty,
                                onRetry: () => ref.invalidate(
                                  dailyRecommendationsProvider,
                                ),
                                onPlay: songs.isEmpty
                                    ? null
                                    : () => _playHomeCollection(
                                        context,
                                        ref,
                                        songs.first,
                                        songs,
                                        '每日推荐',
                                        PlaybackQueueOriginKind
                                            .dailyRecommendations,
                                      ),
                              );
                              if (constraints.maxWidth >= 840 &&
                                  MediaQuery.textScalerOf(context).scale(14) <=
                                      21) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: hero),
                                    const SizedBox(width: 24),
                                    const Expanded(
                                      child: RecommendationCards(
                                        minCardHeight: 100,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  hero,
                                  const SizedBox(height: KgSpacing.section),
                                  const RecommendationCards(),
                                ],
                              );
                            },
                          ),
                          const _RecentlyPlayedShelf(),
                        ],
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: homeDiscoveryCardIds.length,
                    itemBuilder: (context, index) => HomeDiscoverySection(
                      cardId: homeDiscoveryCardIds[index],
                      rowLayout: index.isOdd,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: PlaybackInsets.scrollPadding(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(authControllerProvider).snapshot.userId;
    final repository = ref.read(musicRepositoryProvider);
    try {
      await Future.wait<Object?>([
        repository
            .everydayRecommendations(
              userId: userId,
              mode: CacheLoadMode.forceRefresh,
            )
            .last,
        for (final cardId in homeDiscoveryCardIds)
          repository
              .discoveryCard(
                cardId,
                userId: userId,
                pageSize: homeDiscoveryPageSize,
                mode: CacheLoadMode.forceRefresh,
              )
              .last,
      ]);
    } catch (_) {
      if (context.mounted) showAppError(context, '部分首页内容刷新失败，请稍后重试');
    }
    if (!context.mounted) return;
    ref.invalidate(dailyRecommendationsProvider);
    for (final cardId in homeDiscoveryCardIds) {
      ref.invalidate(homeDiscoveryCardProvider(cardId));
    }
  }
}

/// Isolated leaf: `historyEntriesProvider` is a live Drift watch that fires on
/// every track change, so keeping it out of [HomeScreen.build] stops playback
/// from rebuilding the hero, the cards and the discovery sections.
class _RecentlyPlayedShelf extends ConsumerWidget {
  const _RecentlyPlayedShelf();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyEntriesProvider).value ?? const [];
    final songs = history
        .take(8)
        .map((entry) => entry.song)
        .toList(growable: false);
    if (songs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: KgSpacing.section),
      child: HomeSongShelf(
        title: '最近播放',
        songs: songs,
        scrollKey: 'recent',
        onSongTap: (song) => _playHomeCollection(
          context,
          ref,
          song,
          songs,
          '最近播放',
          PlaybackQueueOriginKind.history,
        ),
        onPlayAll: () => _playHomeCollection(
          context,
          ref,
          songs.first,
          songs,
          '最近播放',
          PlaybackQueueOriginKind.history,
        ),
      ),
    );
  }
}

void _playHomeCollection(
  BuildContext context,
  WidgetRef ref,
  Song song,
  List<Song> songs,
  String title,
  PlaybackQueueOriginKind kind,
) => playSong(
  context,
  ref,
  song,
  queueRequest: PlaybackQueueRequest.snapshot(
    title: title,
    songs: songs,
    kind: kind,
  ),
);
