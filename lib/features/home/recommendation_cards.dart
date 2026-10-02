import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

class RecommendationCards extends ConsumerStatefulWidget {
  const RecommendationCards({super.key, this.minCardHeight = 0});
  final double minCardHeight;

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
    } catch (_) {
      if (mounted) showAppError(context, '暂时无法开始推荐播放，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.textScalerOf(context).scale(14) > 21;
    final cards = RecommendationKind.values
        .map(
          (kind) => _RecommendationCard(
            kind: kind,
            minHeight: widget.minCardHeight,
            loading: _loading == kind,
            enabled: _loading == null,
            onTap: () => _start(kind),
          ),
        )
        .toList(growable: false);
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [cards.first, const SizedBox(height: 12), cards.last],
              )
            : Row(
                children: [
                  Expanded(child: cards.first),
                  const SizedBox(width: 12),
                  Expanded(child: cards.last),
                ],
              ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.kind,
    required this.minHeight,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final RecommendationKind kind;
  final double minHeight;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final personal = kind == RecommendationKind.personalFm;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Material(
        color: const Color(0x0CFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KgRadii.large),
          side: const BorderSide(color: KgColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(KgSpacing.md),
            child: Row(
              children: [
                if (loading)
                  const KgBusyIndicator(size: 24)
                else
                  Icon(
                    personal
                        ? Icons.radio_rounded
                        : Icons.favorite_border_rounded,
                    size: 24,
                    color: personal
                        ? KgColors.accentSecondary
                        : KgColors.accent,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kind.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        personal ? '个性推荐' : '从喜欢出发',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
