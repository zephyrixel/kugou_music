import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/library/library_models.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/widgets/app_dialogs.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/playlist_tile.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final profile = ref.watch(userProfileProvider);
    final vip = ref.watch(userVipProvider);
    final playlists = ref.watch(libraryPlaylistsProvider);
    final sync = ref.watch(librarySyncStatusProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async {
          await auth.refreshIfDue(force: true);
          await ref.read(libraryRepositoryProvider).syncNow();
          ref.invalidate(userProfileProvider);
          ref.invalidate(userVipProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            _TitleBar(authBusy: auth.busy),
            const SizedBox(height: 22),
            _ProfileCard(
              profile: profile,
              vip: vip,
              fingerprint: auth.snapshot.fingerprintRegistered,
            ),
            if (auth.message != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.message!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ],
            const SizedBox(height: 18),
            _SyncCard(status: sync.value ?? const LibrarySyncStatus.idle()),
            const SizedBox(height: 28),
            KgSectionHeader(
              title: '我的歌单',
              subtitle: '仅在打开歌单时加载歌曲',
              action: IconButton(
                tooltip: '创建歌单',
                onPressed: () => _createPlaylist(context, ref),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ),
            playlists.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => KgInlineError(
                error: error,
                onRetry: () => ref.invalidate(libraryPlaylistsProvider),
              ),
              data: (items) => items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('还没有歌单'),
                    )
                  : Column(
                      children: items
                          .map(
                            (playlist) => PlaylistTile(
                              title: playlist.name,
                              subtitle: '${playlist.count} 首歌曲',
                              artworkUrl: playlist.artworkUrl,
                              cacheId: 'playlist:${playlist.localId}',
                              badge: playlist.isMyFavorite
                                  ? '我喜欢'
                                  : playlist.isCollected
                                  ? '已收藏'
                                  : playlist.isPrivate
                                  ? '私密'
                                  : null,
                              onTap: () =>
                                  context.push('/playlist', extra: playlist),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBar extends ConsumerWidget {
  const _TitleBar({required this.authBusy});

  final bool authBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) => KgPageHeader(
    title: '我的',
    subtitle: '账号、同步与云端歌单',
    padding: EdgeInsets.zero,
    actions: [
      IconButton(
        tooltip: '立即同步',
        onPressed: authBusy
            ? null
            : () => ref.read(libraryRepositoryProvider).syncNow(),
        icon: const Icon(Icons.sync_rounded),
      ),
      PopupMenuButton<String>(
        tooltip: '更多设置',
        onSelected: (value) {
          if (value == 'logout') _confirmLogout(context, ref);
          if (value == 'clear_cache') _clearCaches(context, ref);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'clear_cache', child: Text('清理临时缓存')),
          PopupMenuItem(value: 'logout', child: Text('退出登录')),
        ],
      ),
    ],
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.vip,
    required this.fingerprint,
  });

  final AsyncValue<UserProfile> profile;
  final AsyncValue<UserVip> vip;
  final bool fingerprint;

  @override
  Widget build(BuildContext context) => KgSurface(
    padding: EdgeInsets.zero,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KgColors.elevatedHigh, KgColors.elevated],
        ),
      ),
      child: profile.when(
        loading: () => const SizedBox(
          height: 90,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Text(error.toString()),
        data: (user) => Row(
          children: [
            SongArtwork(
              url: user.avatarUrl,
              cacheId:
                  'user:${user.userId ?? user.username ?? user.displayName}',
              size: 72,
              radius: 36,
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
                      const SizedBox(width: 8),
                      if (vip.value?.active == true)
                        const Chip(
                          label: Text('VIP'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'ID ${user.userId ?? '-'} · ${fingerprint ? '设备已登记' : '设备待登记'}',
                    style: const TextStyle(color: KgColors.textMuted),
                  ),
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

class _SyncCard extends ConsumerWidget {
  const _SyncCard({required this.status});

  final LibrarySyncStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = status.failed ? Colors.orangeAccent : KgColors.textMuted;
    final text = switch (status.phase) {
      LibrarySyncPhase.syncing => '正在同步音乐库…',
      LibrarySyncPhase.failed =>
        status.message == null ? '同步失败' : '同步失败 · ${status.message}',
      LibrarySyncPhase.idle => '音乐库已同步',
    };
    return KgSurface(
      padding: EdgeInsets.zero,
      radius: 18,
      child: ListTile(
        leading: status.syncing
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                status.failed ? Icons.sync_problem_rounded : Icons.cloud_done,
                color: color,
              ),
        title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: status.failed ? null : const Text('下拉页面可刷新账号与歌单信息'),
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

Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
  final result = await promptPlaylistName(
    context,
    title: '创建歌单',
    confirmLabel: '创建',
  );
  if (result == null) return;
  try {
    await ref
        .read(libraryRepositoryProvider)
        .createPlaylist(result.name, private: result.private);
  } catch (error) {
    if (context.mounted) showAppError(context, error);
  }
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final accepted = await confirmDialog(
    context,
    title: '退出登录？',
    content: '本机音乐库会被清除；下次登录将从云端重新建立。',
    confirmLabel: '退出',
  );
  if (accepted) await ref.read(authControllerProvider).logout();
}

Future<void> _clearCaches(BuildContext context, WidgetRef ref) async {
  final accepted = await confirmDialog(
    context,
    title: '清理临时缓存？',
    content: '会清理歌曲文件、图片和接口缓存；音乐库与登录状态会保留。',
    confirmLabel: '清理',
  );
  if (accepted != true) return;
  try {
    await ref.read(cacheCoordinatorProvider).clearTransientCaches();
    if (context.mounted) showAppMessage(context, '临时缓存已清理');
  } catch (error) {
    if (context.mounted) showAppError(context, '清理缓存失败：$error');
  }
}
