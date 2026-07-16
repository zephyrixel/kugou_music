import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

class RecommendationCards extends ConsumerStatefulWidget {
  const RecommendationCards({super.key});

  @override
  ConsumerState<RecommendationCards> createState() =>
      _RecommendationCardsState();
}

class _RecommendationCardsState extends ConsumerState<RecommendationCards> {
  RecommendationKind? _loading;

  Future<void> _start(RecommendationKind kind) async {
    if (_loading != null) return;
    setState(() => _loading = kind);
    try {
      final request = await ref
          .read(recommendationPlaybackProvider)
          .start(kind);
      if (!mounted) return;
      await ref
          .read(audioHandlerProvider)
          .playSong(request.songs.first, queueRequest: request);
    } catch (error) {
      if (mounted) showAppError(context, error);
    } finally {
      if (mounted) setState(() => _loading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = RecommendationKind.values
        .map(
          (kind) => Expanded(
            child: _RecommendationCard(
              kind: kind,
              loading: _loading == kind,
              enabled: _loading == null,
              onTap: () => _start(kind),
            ),
          ),
        )
        .toList(growable: false);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [cards.first, const SizedBox(width: 12), cards.last],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.kind,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final RecommendationKind kind;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final personal = kind == RecommendationKind.personalFm;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(KgRadii.large),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(KgRadii.large),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: personal
                  ? const [Color(0xFF29234A), Color(0xFF181B28)]
                  : const [Color(0xFF173D4D), Color(0xFF171D28)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(KgRadii.large),
          ),
          child: Padding(
            padding: const EdgeInsets.all(KgSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    personal
                        ? Icons.auto_awesome_rounded
                        : Icons.favorite_rounded,
                    color: personal
                        ? KgColors.accent
                        : KgColors.accentSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  kind.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  kind.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: KgColors.textMuted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      loading ? '正在准备' : '立即播放',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: KgMotion.resolve(context, KgMotion.fast),
                      child: loading
                          ? const SizedBox.square(
                              key: ValueKey('loading'),
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.play_circle_fill_rounded,
                              key: ValueKey('play'),
                              size: 27,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
