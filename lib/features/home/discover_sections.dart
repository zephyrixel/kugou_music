import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class DiscoverHeader extends StatelessWidget {
  const DiscoverHeader({super.key});

  @override
  Widget build(BuildContext context) =>
      const KgPageHeader(title: '发现', padding: EdgeInsets.zero);
}

class DailyRecommendationHero extends StatelessWidget {
  const DailyRecommendationHero({
    super.key,
    required this.songs,
    required this.loading,
    required this.onPlay,
    required this.failed,
    required this.onRetry,
  });

  final List<Song> songs;
  final bool loading;
  final bool failed;
  final VoidCallback? onPlay;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked = MediaQuery.textScalerOf(context).scale(14) > 21;
      final coverSize = constraints.maxWidth < 340 ? 100.0 : 144.0;
      final song = songs.firstOrNull;
      final artwork = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(KgRadii.large),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: SongArtwork(
          url: song?.artworkUrl,
          cacheId: 'song:${song?.id ?? 'daily'}',
          size: coverSize,
          radius: KgRadii.large,
        ),
      );
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('每日推荐', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: KgSpacing.xs),
          Text(
            loading
                ? '正在加载'
                : failed
                ? '暂时无法加载'
                : songs.isEmpty
                ? '暂无推荐'
                : '${songs.length} 首歌曲',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: KgColors.textMuted),
          ),
          const SizedBox(height: KgSpacing.lg),
          FilledButton.icon(
            onPressed: failed ? onRetry : onPlay,
            icon: loading
                ? const KgBusyIndicator(size: 18, color: KgColors.onAccent)
                : Icon(
                    failed ? Icons.refresh_rounded : Icons.play_arrow_rounded,
                    size: 22,
                  ),
            label: Text(failed ? '重试' : '播放全部'),
          ),
        ],
      );
      return KgSurface(
        color: const Color(0x16FFFFFF),
        gradient: KgGradients.surface,
        padding: const EdgeInsets.all(KgSpacing.lg),
        radius: KgRadii.hero,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 156),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    artwork,
                    const SizedBox(height: KgSpacing.lg),
                    content,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: KgSpacing.md),
                    artwork,
                  ],
                ),
        ),
      );
    },
  );
}
