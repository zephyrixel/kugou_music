import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _scrollController = ScrollController();
  bool _handlingLoadMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 480) {
      return;
    }
    unawaited(_loadMorePlaylists());
  }

  Future<void> _loadMorePlaylists() async {
    if (_handlingLoadMore) return;
    _handlingLoadMore = true;
    try {
      await ref.read(cloudPlaylistsProvider.notifier).loadMore();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多歌单失败：$error')));
      }
    } finally {
      _handlingLoadMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.authenticated) {
      return _GuestAccount(
        message: auth.message,
        onClearCache: () => _clearCaches(context, ref),
      );
    }
    final profile = ref.watch(userProfileProvider);
    final vip = ref.watch(userVipProvider);
    final playlists = ref.watch(cloudPlaylistsProvider);
    final history = ref.watch(cloudHistoryProvider);
    return RefreshIndicator(
      onRefresh: () async {
        await auth.refreshIfDue(force: true);
        ref.invalidate(userProfileProvider);
        ref.invalidate(userVipProvider);
        ref.invalidate(cloudPlaylistsProvider);
        ref.invalidate(cloudHistoryProvider);
      },
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '我的',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              IconButton(
                tooltip: '刷新登录信息',
                onPressed: auth.busy
                    ? null
                    : () => auth.refreshIfDue(force: true),
                icon: auth.status.name == 'refreshing'
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Icon(Icons.sync_rounded),
              ),
              PopupMenuButton<String>(
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
          ),
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
          const SizedBox(height: 30),
          _SectionHeader(
            title: '云歌单',
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
            error: (error, _) => _InlineError(
              error: error,
              retry: () => ref.invalidate(cloudPlaylistsProvider),
            ),
            data: (page) => Column(
              children: page.items
                  .map((playlist) => _PlaylistRow(playlist: playlist))
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 28),
          const _SectionHeader(title: '云播放历史'),
          history.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => _InlineError(
              error: error,
              retry: () => ref.invalidate(cloudHistoryProvider),
            ),
            data: (songs) => songs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('暂无云播放历史'),
                  )
                : Column(
                    children: songs
                        .take(12)
                        .map(
                          (song) => SongTile(
                            song: song,
                            onTap: () => ref
                                .read(audioHandlerProvider)
                                .playSong(song, queueSongs: songs),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GuestAccount extends StatelessWidget {
  const _GuestAccount({this.message, required this.onClearCache});
  final String? message;
  final VoidCallback onClearCache;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '我的',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              IconButton(
                tooltip: '清理临时缓存',
                onPressed: onClearCache,
                icon: const Icon(Icons.cleaning_services_outlined),
              ),
            ],
          ),
          const Spacer(),
          const Icon(
            Icons.person_outline_rounded,
            size: 72,
            color: KgColors.accent,
          ),
          const SizedBox(height: 20),
          Text('登录后连接你的云音乐', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          const Text(
            '同步“我喜欢”、云歌单、播放历史和 Lite VIP 信息。',
            style: TextStyle(color: KgColors.textMuted),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: const TextStyle(color: Colors.orangeAccent)),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => context.push('/login'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: KgColors.accent,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.sms_outlined),
            label: const Text('短信验证码登录'),
          ),
          const Spacer(),
        ],
      ),
    ),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: KgColors.elevated,
      borderRadius: BorderRadius.circular(24),
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
            cacheId: 'user:${user.userId ?? user.username ?? user.displayName}',
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
                const SizedBox(height: 8),
                Text(
                  '关注 ${user.followingCount ?? 0}  粉丝 ${user.fanCount ?? 0}',
                  style: const TextStyle(color: KgColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      ?action,
    ],
  );
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({required this.playlist});
  final CloudPlaylist playlist;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 3),
    onTap: () => context.push('/playlist', extra: playlist),
    leading: SongArtwork(
      url: playlist.artworkUrl,
      cacheId: 'playlist:${playlist.listId ?? playlist.globalCollectionId}',
    ),
    title: Text(playlist.name),
    subtitle: Text(
      '${playlist.count ?? 0} 首${playlist.isMyFavorite
          ? ' · 我喜欢'
          : playlist.isCollected
          ? ' · 已收藏'
          : ''}',
      style: const TextStyle(color: KgColors.textMuted),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(error.toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: IconButton(
      onPressed: retry,
      icon: const Icon(Icons.refresh_rounded),
    ),
  );
}

Future<void> _createPlaylist(BuildContext context, WidgetRef ref) async {
  final name = TextEditingController();
  var private = false;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('创建云歌单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: '歌单名称'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('设为私密'),
              value: private,
              onChanged: (value) => setState(() => private = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('创建'),
          ),
        ],
      ),
    ),
  );
  if (accepted != true || name.text.trim().isEmpty) return;
  try {
    await ref
        .read(musicRepositoryProvider)
        .createPlaylist(
          ref.read(authControllerProvider).snapshot.userId!,
          name.text.trim(),
          private: private,
        );
    ref.invalidate(cloudPlaylistsProvider);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('退出登录？'),
      content: const Text('云端账号缓存会被清除，本地收藏和本地历史会保留。'),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          child: const Text('退出'),
        ),
      ],
    ),
  );
  if (accepted == true) await ref.read(authControllerProvider).logout();
}

Future<void> _clearCaches(BuildContext context, WidgetRef ref) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('清理临时缓存？'),
      content: const Text('会清理歌曲文件、图片和接口缓存，本地收藏、播放历史与登录状态会保留。'),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          child: const Text('清理'),
        ),
      ],
    ),
  );
  if (accepted != true) return;
  try {
    await ref.read(cacheCoordinatorProvider).clearTransientCaches();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('临时缓存已清理')));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('清理缓存失败：$error')));
    }
  }
}
