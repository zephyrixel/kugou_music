import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/widgets/app_dialogs.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/features/membership/membership_controller.dart';
import 'package:kgmusic/features/membership/membership_presenter.dart';

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
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('每日权益', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                '每天可领取一次，领取后可升级畅听权益。',
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
                    ? const KgBusyIndicator()
                    : const Icon(Icons.redeem_rounded),
                label: Text(controller.claimedToday ? '今日已领取' : '领取 1 天会员'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: controller.busy || controller.upgradedToday
                    ? null
                    : () => _upgrade(context, controller),
                icon: controller.action == MembershipAction.upgrading
                    ? const KgBusyIndicator()
                    : const Icon(Icons.upgrade_rounded),
                label: Text(controller.upgradedToday ? '今日已升级' : '升级畅听 VIP'),
              ),
              const SizedBox(height: 8),
              const Text(
                '请先领取当日会员权益，再进行畅听升级。',
                textAlign: TextAlign.center,
                style: TextStyle(color: KgColors.textMuted, fontSize: 12),
              ),
            ],
          ),
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
      content: '每日限领一次，请确认今天尚未领取。',
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
    } catch (_) {
      if (context.mounted) showAppError(context, '会员权益领取失败，请稍后重试');
    }
  }

  Future<void> _upgrade(
    BuildContext context,
    MembershipController controller,
  ) async {
    final accepted = await confirmDialog(
      context,
      title: '升级畅听 VIP？',
      content: '升级前需要先领取当日会员权益，请勿重复操作。',
      confirmLabel: '升级',
    );
    if (!accepted) return;
    try {
      final result = await controller.upgrade();
      if (!context.mounted) return;
      final expiry = parseVipTime(result.endTime);
      final success = expiry == null
          ? '畅听 VIP 升级成功'
          : '升级成功，有效至 ${formatVipDate(expiry)}';
      showAppMessage(
        context,
        controller.refreshWarning == null
            ? success
            : '$success；${controller.refreshWarning}',
      );
    } catch (_) {
      if (context.mounted) showAppError(context, '畅听权益升级失败，请稍后重试');
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
        children: [KgBusyIndicator(), SizedBox(width: 10), Text('正在读取本月领取记录…')],
      );
    }
    if (controller.recordUnavailable) {
      return const Text(
        '本月领取记录暂时无法读取',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: KgColors.warning),
      );
    }
    final count = controller.record?.claimedDays;
    return Text(
      count == null ? '本月领取情况以账号权益记录为准' : '本月已领取 $count 天',
      style: const TextStyle(color: KgColors.textMuted),
    );
  }
}
