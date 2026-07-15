import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/core/widgets/song_tile_actions.dart';
import 'package:kgmusic/features/home/recommendation_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(dailyRecommendationsProvider);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(dailyRecommendationsProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const KgPageHeader(
                      title: '听点什么',
                      subtitle: 'Lite 概念版 · 为今天选一首歌',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 28),
                    _DailyHero(
                      count: recommendations.value?.length,
                      onPlay: recommendations.value?.isNotEmpty == true
                          ? () => playSong(
                              context,
                              ref,
                              recommendations.value!.first,
                              queueRequest: PlaybackQueueRequest.snapshot(
                                title: '每日推荐',
                                songs: recommendations.value!,
                                kind: PlaybackQueueOriginKind
                                    .dailyRecommendations,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickLink(
                            icon: Icons.search_rounded,
                            label: '搜索曲库',
                            onTap: () => context.go('/search'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickLink(
                            icon: Icons.favorite_rounded,
                            label: '我的收藏',
                            onTap: () => context.go('/library'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const KgSectionHeader(
                      title: '为你推荐',
                      subtitle: '连续播放，越听越懂你',
                    ),
                    const SizedBox(height: 14),
                    const SizedBox(height: 188, child: RecommendationCards()),
                    const SizedBox(height: 30),
                    const KgSectionHeader(
                      title: '每日推荐',
                      subtitle: '根据你的音乐口味更新',
                    ),
                  ],
                ),
              ),
            ),
            recommendations.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: KgErrorView(
                  error: error,
                  onRetry: () async =>
                      ref.invalidate(dailyRecommendationsProvider),
                ),
              ),
              data: (songs) => songs.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('今天还没有推荐内容')),
                    )
                  : SliverList.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) => SongTile(
                        song: songs[index],
                        index: index + 1,
                        onTap: () => playSong(
                          context,
                          ref,
                          songs[index],
                          queueRequest: PlaybackQueueRequest.snapshot(
                            title: '每日推荐',
                            songs: songs,
                            kind: PlaybackQueueOriginKind.dailyRecommendations,
                          ),
                        ),
                        trailing: SongTileActions(song: songs[index]),
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: KgColors.elevated,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: KgColors.accent, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 17,
              color: KgColors.textMuted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _DailyHero extends StatelessWidget {
  const _DailyHero({this.count, this.onPlay});
  final int? count;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) => Container(
    height: 184,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFB6FF3B), Color(0xFF60D831)],
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '今日\n推荐',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                count == null ? '正在生成今日声音' : '$count 首今日精选',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: onPlay,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: KgColors.accent,
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('播放'),
        ),
      ],
    ),
  );
}
