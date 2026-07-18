import 'package:flutter/material.dart';
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
    final profile = ref.watch(userProfileProvider).value;
    final history = ref.watch(historyEntriesProvider).value ?? const [];
    final songs = recommendations.value ?? const <Song>[];
    final recentSongs = history
        .take(8)
        .map((entry) => entry.song)
        .toList(growable: false);
    return SafeArea(
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
                      DiscoverHeader(name: profile?.displayName),
                      const SizedBox(height: KgSpacing.xl),
                      DailyRecommendationHero(
                        songs: songs,
                        loading: recommendations.isLoading && songs.isEmpty,
                        failed: recommendations.hasError && songs.isEmpty,
                        onRetry: () =>
                            ref.invalidate(dailyRecommendationsProvider),
                        onPlay: songs.isEmpty
                            ? null
                            : () => _playCollection(
                                context,
                                ref,
                                songs.first,
                                songs,
                                '每日推荐',
                                PlaybackQueueOriginKind.dailyRecommendations,
                              ),
                      ),
                      const SizedBox(height: KgSpacing.section),
                      const KgSectionHeader(
                        title: '为你而播',
                        subtitle: '越听越懂你的音乐喜好',
                      ),
                      const SizedBox(height: KgSpacing.md),
                      const SizedBox(height: 184, child: RecommendationCards()),
                      if (recentSongs.isNotEmpty) ...[
                        const SizedBox(height: KgSpacing.section),
                        HomeSongShelf(
                          title: '最近听过',
                          subtitle: '从上次停下的地方继续',
                          songs: recentSongs,
                          scrollKey: 'recent',
                          onSongTap: (song) => _playCollection(
                            context,
                            ref,
                            song,
                            recentSongs,
                            '最近播放',
                            PlaybackQueueOriginKind.history,
                          ),
                          onPlayAll: () => _playCollection(
                            context,
                            ref,
                            recentSongs.first,
                            recentSongs,
                            '最近播放',
                            PlaybackQueueOriginKind.history,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: homeDiscoveryCardIds.length,
                itemBuilder: (context, index) =>
                    HomeDiscoverySection(cardId: homeDiscoveryCardIds[index]),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + KgSpacing.xl,
                ),
              ),
            ],
          ),
        ),
      ),
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

  void _playCollection(
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
}
