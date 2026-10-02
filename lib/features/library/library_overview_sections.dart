import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class LibraryHeader extends ConsumerWidget {
  const LibraryHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    return Row(
      children: [
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SongArtwork(
              url: profile?.avatarUrl,
              cacheId: 'user:${profile?.userId}',
              placeholderIcon: Icons.person_outline_rounded,
              size: 48,
              radius: 24,
            ),
            title: Text(
              '我的音乐',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            subtitle: Text(
              profile?.displayName ?? '账号与会员',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: KgColors.textMuted),
            ),
            onTap: () => context.push('/account'),
          ),
        ),
        IconButton(
          tooltip: '设置',
          onPressed: () => context.push('/account/settings'),
          icon: const Icon(Icons.settings_outlined),
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
  Widget build(BuildContext context) => KgInteractiveSurface(
    onTap: onTap,
    gradient: KgGradients.warm,
    child: Row(
      children: [
        Icon(icon, color: KgColors.accentSecondary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
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
