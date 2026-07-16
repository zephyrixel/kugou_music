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
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/core/widgets/song_tile_actions.dart';
import 'package:kgmusic/features/home/discover_sections.dart';
import 'package:kgmusic/features/home/recommendation_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(dailyRecommendationsProvider);
    final profile = ref.watch(userProfileProvider).value;
    final history = ref.watch(historyEntriesProvider).value ?? const [];
    final songs = recommendations.value ?? const <Song>[];
    return SafeArea(
      bottom: false,
      child: KgContentWidth(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            key: const PageStorageKey('discover-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  KgSpacing.lg,
                  KgSpacing.xl,
                  KgSpacing.lg,
                  KgSpacing.sm,
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
                        subtitle: '连续播放，反馈会用于改进推荐',
                      ),
                      const SizedBox(height: KgSpacing.md),
                      const SizedBox(height: 184, child: RecommendationCards()),
                      if (history.isNotEmpty) ...[
                        const SizedBox(height: KgSpacing.section),
                        const KgSectionHeader(
                          title: '最近听过',
                          subtitle: '从上次停下的地方继续',
                        ),
                        const SizedBox(height: KgSpacing.md),
                        RecentSongsRow(entries: history.take(8).toList()),
                      ],
                      const SizedBox(height: KgSpacing.section),
                      const KgSectionHeader(
                        title: '每日精选',
                        subtitle: '根据你的音乐口味持续更新',
                      ),
                      const SizedBox(height: KgSpacing.xs),
                    ],
                  ),
                ),
              ),
              _recommendationList(context, ref, recommendations),
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

  Future<void> _refresh(WidgetRef ref) async {
    final userId = ref.read(authControllerProvider).snapshot.userId;
    await ref
        .read(musicRepositoryProvider)
        .everydayRecommendations(
          userId: userId,
          mode: CacheLoadMode.forceRefresh,
        )
        .last;
    ref.invalidate(dailyRecommendationsProvider);
  }

  Widget _recommendationList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Song>> recommendations,
  ) => recommendations.when(
    skipLoadingOnRefresh: true,
    loading: () => const SliverToBoxAdapter(child: SongListSkeleton()),
    error: (error, _) => SliverFillRemaining(
      hasScrollBody: false,
      child: KgErrorView(
        error: error,
        onRetry: () async => ref.invalidate(dailyRecommendationsProvider),
      ),
    ),
    data: (songs) => songs.isEmpty
        ? const SliverFillRemaining(
            hasScrollBody: false,
            child: KgEmptyView('今天还没有推荐内容'),
          )
        : SliverList.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) => SongTile(
              song: songs[index],
              index: index + 1,
              variant: SongTileVariant.indexed,
              onTap: () => _playCollection(
                context,
                ref,
                songs[index],
                songs,
                '每日推荐',
                PlaybackQueueOriginKind.dailyRecommendations,
              ),
              trailing: SongTileActions(song: songs[index]),
            ),
          ),
  );

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
