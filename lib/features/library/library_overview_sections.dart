import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/library/library_models.dart';
import 'package:kgmusic/core/widgets/account_avatar_button.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

class LibraryHeader extends ConsumerWidget {
  const LibraryHeader({super.key, required this.sync});

  final LibrarySyncStatus? sync;

  @override
  Widget build(BuildContext context, WidgetRef ref) => KgPageHeader(
    title: '音乐库',
    padding: EdgeInsets.zero,
    subtitleWidget: AnimatedSwitcher(
      duration: KgMotion.resolve(context, KgMotion.fast),
      child: Text(
        _syncLabel(sync),
        key: ValueKey(sync?.phase),
        style: TextStyle(
          color: sync?.failed == true ? KgColors.warning : KgColors.textMuted,
        ),
      ),
    ),
    actions: [
      IconButton(
        tooltip: '立即同步',
        onPressed: sync?.syncing == true
            ? null
            : () => unawaited(ref.read(libraryRepositoryProvider).syncNow()),
        icon: sync?.syncing == true
            ? const KgBusyIndicator(size: 20)
            : const Icon(Icons.sync_rounded),
      ),
      const SizedBox(width: KgSpacing.xs),
      const AccountAvatarButton(),
    ],
  );

  String _syncLabel(LibrarySyncStatus? status) => switch (status?.phase) {
    LibrarySyncPhase.syncing => '正在同步音乐库…',
    LibrarySyncPhase.failed => '同步失败，点击同步按钮重试',
    _ => '收藏、历史与歌单都在这里',
  };
}

class LibraryCollectionCard extends StatelessWidget {
  const LibraryCollectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: colors.first,
    borderRadius: BorderRadius.circular(KgRadii.large),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Ink(
        height: 122,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(KgSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: Colors.white, size: 42),
            ],
          ),
        ),
      ),
    ),
  );
}
