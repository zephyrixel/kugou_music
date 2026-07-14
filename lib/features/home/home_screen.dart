import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/core/widgets/song_tile_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(dailyRecommendationsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(dailyRecommendationsProvider.future),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KGMusic',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Lite 概念版 · 让今天有点不一样',
                    style: TextStyle(color: KgColors.textMuted),
                  ),
                  const SizedBox(height: 28),
                  _DailyHero(
                    count: recommendations.value?.length,
                    onPlay: recommendations.value?.isNotEmpty == true
                        ? () => _play(
                            context,
                            ref,
                            recommendations.value!.first,
                            recommendations.value!,
                          )
                        : null,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '每日推荐',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const Text(
                        '来自 Lite API',
                        style: TextStyle(color: KgColors.textMuted),
                      ),
                    ],
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
              child: _ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(dailyRecommendationsProvider),
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
                      onTap: () => _play(context, ref, songs[index], songs),
                      trailing: SongTileActions(song: songs[index]),
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _DailyHero extends StatelessWidget {
  const _DailyHero({this.count, this.onPlay});
  final int? count;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
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
                'DAILY\nMIX',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 34,
                  height: 0.9,
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('重新加载')),
        ],
      ),
    ),
  );
}

Future<void> _play(
  BuildContext context,
  WidgetRef ref,
  Song song,
  List<Song> queue,
) async {
  try {
    await ref.read(audioHandlerProvider).playSong(song, queueSongs: queue);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
