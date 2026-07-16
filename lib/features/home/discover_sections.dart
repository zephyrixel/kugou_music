import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/history_entry.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/account_avatar_button.dart';
import 'package:kgmusic/core/widgets/artwork_backdrop.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class DiscoverHeader extends StatelessWidget {
  const DiscoverHeader({super.key, this.name});

  final String? name;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name == null ? _greeting() : '${_greeting()} · $name',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: KgColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '今天想听什么？',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      const SizedBox(width: KgSpacing.md),
      const AccountAvatarButton(),
    ],
  );

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 11) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }
}

class DailyRecommendationHero extends StatelessWidget {
  const DailyRecommendationHero({
    super.key,
    required this.songs,
    required this.loading,
    required this.onPlay,
  });

  final List<Song> songs;
  final bool loading;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final song = songs.firstOrNull;
    return Container(
      height: 232,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: KgColors.elevated,
        borderRadius: BorderRadius.circular(KgRadii.hero),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ArtworkBackdrop(
            url: song?.artworkUrl,
            cacheId: 'daily:${song?.id ?? 'loading'}',
            opacity: 0.68,
            scrim: 0.55,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xD9090A0F), Color(0x26090A0F)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(KgSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(KgRadii.pill),
                  ),
                  child: const Text(
                    'DAILY MIX',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Text('今天的声音', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: KgMotion.resolve(context, KgMotion.fast),
                  child: Text(
                    loading
                        ? '正在整理你的每日推荐'
                        : songs.isEmpty
                        ? '暂时没有推荐歌曲'
                        : '${songs.length} 首精选 · 从 ${song!.artistLabel} 开始',
                    key: ValueKey('${loading}_${songs.length}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: KgSpacing.md),
                FilledButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('播放今日推荐'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecentSongsRow extends ConsumerWidget {
  const RecentSongsRow({super.key, required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = entries.map((entry) => entry.song).toList(growable: false);
    return SizedBox(
      height: 164,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: KgSpacing.sm),
        itemBuilder: (context, index) {
          final song = entries[index].song;
          return SizedBox(
            width: 116,
            child: InkWell(
              borderRadius: BorderRadius.circular(KgRadii.medium),
              onTap: () => playSong(
                context,
                ref,
                song,
                queueRequest: PlaybackQueueRequest.snapshot(
                  title: '最近播放',
                  songs: songs,
                  kind: PlaybackQueueOriginKind.history,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SongArtwork(
                    url: song.artworkUrl,
                    cacheId: 'song:${song.id}',
                    size: 116,
                    radius: KgRadii.medium,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    song.artistLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KgColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SongListSkeleton extends StatelessWidget {
  const SongListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: KgSpacing.lg),
    child: Column(
      children: List.generate(
        5,
        (_) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 7),
          child: KgSkeleton(height: 54, radius: KgRadii.medium),
        ),
      ),
    ),
  );
}
