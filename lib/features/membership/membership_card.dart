import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/features/membership/membership_actions_sheet.dart';
import 'package:kgmusic/features/membership/membership_presenter.dart';

class MembershipCard extends ConsumerWidget {
  const MembershipCard({super.key, required this.vip, required this.userId});

  final AsyncValue<UserVip> vip;
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => vip.when(
    loading: () => const KgSurface(
      child: SizedBox(
        height: 86,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KgSkeleton(height: 20, width: 140),
            SizedBox(height: 16),
            KgSkeleton(height: 12, width: 200),
          ],
        ),
      ),
    ),
    error: (error, _) => KgSurface(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.workspace_premium_outlined),
        title: const Text('会员状态加载失败'),
        trailing: IconButton(
          tooltip: '重试',
          onPressed: () => ref.invalidate(userVipProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
    ),
    data: (value) {
      final summary = buildMembershipSummary(value);
      return KgSurface(
        gradient: KgGradients.warm,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(KgSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked =
                      constraints.maxWidth < 220 ||
                      MediaQuery.textScalerOf(context).scale(14) > 21;
                  final action = TextButton(
                    onPressed: () => showMembershipActions(context, userId),
                    child: const Text('领取权益'),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: KgColors.accentSoft,
                              borderRadius: BorderRadius.circular(
                                KgRadii.medium,
                              ),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: KgColors.accent,
                            ),
                          ),
                          const SizedBox(width: KgSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  summary.primary?.label ?? '普通用户',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: KgSpacing.xxs),
                                Text(
                                  summary.statusLabel,
                                  style: const TextStyle(
                                    color: KgColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!stacked) action,
                        ],
                      ),
                      if (stacked) ...[
                        const SizedBox(height: KgSpacing.sm),
                        Align(alignment: Alignment.centerRight, child: action),
                      ],
                    ],
                  );
                },
              ),
              if (summary.items.length > 1 ||
                  summary.items.any((item) => item.paid || item.yearly)) ...[
                const SizedBox(height: 16),
                ...summary.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (item.yearly) const _MemberTag(label: '年费'),
                        if (item.paid) ...[
                          const SizedBox(width: 6),
                          const _MemberTag(label: '付费'),
                        ],
                        const SizedBox(width: 10),
                        Text(
                          item.endTime == null
                              ? '有效'
                              : formatVipDate(item.endTime!),
                          style: const TextStyle(
                            color: KgColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _MemberTag extends StatelessWidget {
  const _MemberTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: KgColors.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: KgColors.accent,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
