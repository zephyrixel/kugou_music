import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/widgets/app_dialogs.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/features/membership/membership_controller.dart';
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
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
    error: (error, _) => KgSurface(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.workspace_premium_outlined),
        title: const Text('会员状态加载失败'),
        subtitle: Text(error.toString(), maxLines: 2),
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
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KgColors.accent.withValues(alpha: 0.15),
                KgColors.elevated,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: KgColors.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: KgColors.accent,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.primary?.label ?? '普通用户',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          summary.statusLabel,
                          style: const TextStyle(color: KgColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => showMembershipActions(context, userId),
                    child: const Text('免费权益'),
                  ),
                ],
              ),
              if (summary.items.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...summary.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
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

Future<void> showMembershipActions(BuildContext context, int userId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MembershipActionsSheet(userId: userId),
    );

class _MembershipActionsSheet extends ConsumerStatefulWidget {
  const _MembershipActionsSheet({required this.userId});

  final int userId;

  @override
  ConsumerState<_MembershipActionsSheet> createState() =>
      _MembershipActionsSheetState();
}

class _MembershipActionsSheetState
    extends ConsumerState<_MembershipActionsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(membershipControllerProvider(widget.userId)).loadRecord();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(membershipControllerProvider(widget.userId));
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('免费会员权益', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Lite 概念版提供每日会员领取和畅听升级。接口存在风控限制，请勿频繁操作。',
              style: TextStyle(color: KgColors.textMuted),
            ),
            const SizedBox(height: 18),
            _RecordStatus(controller: controller),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: controller.busy || controller.claimedToday
                  ? null
                  : () => _claim(context, controller),
              icon: controller.action == MembershipAction.claiming
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.redeem_rounded),
              label: Text(controller.claimedToday ? '今日已领取' : '领取 1 天会员'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: controller.busy || controller.upgradedToday
                  ? null
                  : () => _upgrade(context, controller),
              icon: controller.action == MembershipAction.upgrading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upgrade_rounded),
              label: Text(controller.upgradedToday ? '今日已升级' : '升级畅听 VIP'),
            ),
            const SizedBox(height: 8),
            const Text(
              '升级需要先成功领取；如果已在其他设备领取，也可以直接尝试升级。',
              textAlign: TextAlign.center,
              style: TextStyle(color: KgColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claim(
    BuildContext context,
    MembershipController controller,
  ) async {
    final accepted = await confirmDialog(
      context,
      title: '领取 1 天会员？',
      content: '将通过酷狗 Lite 活动接口领取。每天只操作一次，避免触发账号风控。',
      confirmLabel: '领取',
    );
    if (!accepted) return;
    try {
      final result = await controller.claim();
      if (!context.mounted) return;
      final expiry = parseVipTime(result.endTime);
      final success = expiry == null
          ? '会员权益领取成功'
          : '领取成功，有效至 ${formatVipDate(expiry)}';
      showAppMessage(
        context,
        controller.refreshWarning == null
            ? success
            : '$success；${controller.refreshWarning}',
      );
    } catch (error) {
      if (context.mounted) showAppError(context, error);
    }
  }

  Future<void> _upgrade(
    BuildContext context,
    MembershipController controller,
  ) async {
    final accepted = await confirmDialog(
      context,
      title: '升级畅听 VIP？',
      content: '该操作要求账号已成功领取日会员。请求不会自动重试，请勿反复点击。',
      confirmLabel: '升级',
    );
    if (!accepted) return;
    try {
      final result = await controller.upgrade();
      if (!context.mounted) return;
      final message = result.message?.trim();
      final success = message == null || message.isEmpty
          ? '畅听 VIP 升级成功'
          : message;
      showAppMessage(
        context,
        controller.refreshWarning == null
            ? success
            : '$success；${controller.refreshWarning}',
      );
    } catch (error) {
      if (context.mounted) showAppError(context, error);
    }
  }
}

class _RecordStatus extends StatelessWidget {
  const _RecordStatus({required this.controller});

  final MembershipController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.action == MembershipAction.loadingRecord) {
      return const Row(
        children: [
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('正在读取本月领取记录…'),
        ],
      );
    }
    if (controller.recordError != null) {
      return Text(
        '领取记录暂不可用：${controller.recordError}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.orangeAccent),
      );
    }
    final count = controller.record?.claimedDays;
    return Text(
      count == null ? '本月领取次数以酷狗服务端为准' : '本月已领取 $count 天',
      style: const TextStyle(color: KgColors.textMuted),
    );
  }
}
