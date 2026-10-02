import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/playback_insets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/cache/cache_policy.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/library/library_models.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/widgets/app_dialogs.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_settings_group.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/features/membership/membership_card.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final profile = ref.watch(userProfileProvider);
    final vip = ref.watch(userVipProvider);
    final sync = ref.watch(librarySyncStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('账号与会员')),
      body: KgContentWidth(
        maxWidth: KgBreakpoints.readingMaxWidth,
        child: RefreshIndicator(
          onRefresh: () async {
            try {
              await _refresh(ref);
            } catch (_) {
              if (context.mounted) showAppError(context, '账号信息刷新失败，请重试');
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              KgSpacing.lg,
              KgSpacing.sm,
              KgSpacing.lg,
              PlaybackInsets.scrollPadding(context, extra: 32),
            ),
            children: [
              _ProfileCard(
                profile: profile,
                fingerprint: auth.snapshot.fingerprintRegistered,
                registeringDevice: auth.registeringDevice,
                onRetryDevice: auth.retryDeviceRegistration,
              ),
              if (auth.snapshot.userId case final userId?) ...[
                const SizedBox(height: KgSpacing.md),
                MembershipCard(vip: vip, userId: userId),
              ],
              if (auth.message != null) ...[
                const SizedBox(height: KgSpacing.sm),
                KgSurface(
                  padding: EdgeInsets.zero,
                  radius: KgRadii.medium,
                  child: ListTile(
                    leading: const Icon(
                      Icons.info_outline_rounded,
                      color: KgColors.warning,
                    ),
                    title: Text(auth.message!),
                    textColor: KgColors.warning,
                  ),
                ),
              ],
              const SizedBox(height: KgSpacing.md),
              _SyncCard(status: sync.value ?? const LibrarySyncStatus.idle()),
              const SizedBox(height: KgSpacing.section),
              const KgSectionHeader(title: '应用与账号'),
              const SizedBox(height: KgSpacing.sm),
              _SettingsCard(authBusy: auth.busy),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    final auth = ref.read(authControllerProvider);
    await auth.refreshIfDue(force: true);
    await ref.read(libraryRepositoryProvider).syncNow();
    final userId = auth.snapshot.userId;
    if (userId != null) {
      final repository = ref.read(musicRepositoryProvider);
      await Future.wait([
        repository.userProfile(userId, mode: CacheLoadMode.forceRefresh).last,
        repository.userVip(userId, mode: CacheLoadMode.forceRefresh).last,
      ]);
    }
    ref.invalidate(userProfileProvider);
    ref.invalidate(userVipProvider);
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.fingerprint,
    required this.registeringDevice,
    required this.onRetryDevice,
  });

  final AsyncValue<UserProfile> profile;
  final bool fingerprint;
  final bool registeringDevice;
  final Future<void> Function() onRetryDevice;

  @override
  Widget build(BuildContext context) => KgSurface(
    padding: EdgeInsets.zero,
    child: Container(
      padding: const EdgeInsets.all(20),
      child: profile.when(
        loading: () => const SizedBox(
          height: 90,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => const Text('个人资料暂时无法加载，请稍后重试'),
        data: (user) => Row(
          children: [
            SongArtwork(
              url: user.avatarUrl,
              cacheId:
                  'user:${user.userId ?? user.username ?? user.displayName}',
              size: 56,
              radius: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '账号 ${user.userId ?? '-'} · ${fingerprint ? '当前设备已验证' : '当前设备待验证'}',
                    style: const TextStyle(color: KgColors.textMuted),
                  ),
                  if (!fingerprint) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: registeringDevice ? null : onRetryDevice,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: registeringDevice
                          ? const KgBusyIndicator(size: 16)
                          : const Icon(Icons.security_update_good_rounded),
                      label: Text(registeringDevice ? '正在验证设备…' : '重新验证'),
                    ),
                  ],
                  if (user.signature?.isNotEmpty == true) ...[
                    const SizedBox(height: 7),
                    Text(
                      user.signature!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard({required this.authBusy});

  final bool authBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) => KgSettingsGroup(
    children: [
      KgSettingsTile(
        icon: Icons.settings_outlined,
        title: '设置',
        subtitle: '播放、存储与诊断',
        onTap: () => context.push('/account/settings'),
      ),
      KgSettingsTile(
        enabled: !authBusy,
        icon: Icons.logout_rounded,
        title: '退出登录',
        subtitle: '清除本机音乐库和登录状态',
        destructive: true,
        onTap: () => _confirmLogout(context, ref),
      ),
    ],
  );
}

class _SyncCard extends ConsumerWidget {
  const _SyncCard({required this.status});

  final LibrarySyncStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = status.failed ? KgColors.warning : KgColors.textMuted;
    final text = switch (status.phase) {
      LibrarySyncPhase.syncing => '正在同步音乐库…',
      LibrarySyncPhase.failed => '音乐库同步失败，请重试',
      LibrarySyncPhase.idle =>
        status.lastSyncedAt == null ? '音乐库尚未同步' : '音乐库已同步',
    };
    return KgSurface(
      padding: EdgeInsets.zero,
      radius: 18,
      child: ListTile(
        leading: status.syncing
            ? const KgBusyIndicator(size: 22)
            : Icon(
                status.failed ? Icons.sync_problem_rounded : Icons.cloud_done,
                color: color,
              ),
        title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),

        trailing: status.failed
            ? IconButton(
                tooltip: '重试同步',
                onPressed: () => ref.read(libraryRepositoryProvider).syncNow(),
                icon: const Icon(Icons.refresh_rounded),
              )
            : null,
      ),
    );
  }
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final accepted = await confirmDialog(
    context,
    title: '退出登录？',
    content: '本机保存的账号信息和音乐库数据将被清除。',
    confirmLabel: '退出',
  );
  if (accepted) await ref.read(authControllerProvider).logout();
}
