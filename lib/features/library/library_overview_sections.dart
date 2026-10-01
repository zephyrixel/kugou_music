import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class LibraryHeader extends ConsumerWidget {
  const LibraryHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KgPageHeader(
          title: '我的',
          padding: EdgeInsets.zero,
          actions: [
            IconButton(
              tooltip: '设置',
              onPressed: () => context.push('/account/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        const SizedBox(height: KgSpacing.lg),
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SongArtwork(
              url: profile?.avatarUrl,
              cacheId: 'user:${profile?.userId}',
              size: 52,
              radius: 26,
            ),
            title: Text(
              profile?.displayName ?? '账号',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: const Text(
              '账号与会员',
              style: TextStyle(color: KgColors.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => context.push('/account'),
          ),
        ),
      ],
    );
  }
}

class LibraryCollectionCard extends StatelessWidget {
  const LibraryCollectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: KgColors.surface,
    borderRadius: BorderRadius.circular(KgRadii.large),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(KgSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: KgColors.accent, size: 24),
            const SizedBox(height: KgSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

Future<void> syncLibrary(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(libraryRepositoryProvider).syncNow();
  } catch (_) {
    if (context.mounted) showAppError(context, '音乐库同步失败，请重试');
  }
}
