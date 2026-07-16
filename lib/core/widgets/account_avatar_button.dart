import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class AccountAvatarButton extends ConsumerWidget {
  const AccountAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final identity = profile?.userId ?? profile?.username ?? 'current';
    return Tooltip(
      message: '个人中心',
      child: InkResponse(
        onTap: () => context.push('/account'),
        radius: 25,
        child: Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: KgColors.accent.withValues(alpha: 0.65)),
          ),
          child: ClipOval(
            child: SongArtwork(
              url: profile?.avatarUrl,
              cacheId: 'user:$identity',
              size: 36,
              radius: 18,
            ),
          ),
        ),
      ),
    );
  }
}
