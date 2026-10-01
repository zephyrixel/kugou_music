import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

class SongFavoriteButton extends ConsumerWidget {
  const SongFavoriteButton({
    super.key,
    required this.song,
    this.compact = false,
  });
  final Song song;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite = ref.watch(songIsFavoriteProvider(song.id));
    final liked = favorite.value ?? false;
    return IconButton(
      tooltip: liked ? '取消喜欢' : '添加到我喜欢',
      onPressed: favorite.isLoading || !ref.watch(libraryReadyProvider)
          ? null
          : () => toggleSongFavorite(context, ref, song),
      padding: compact ? const EdgeInsets.all(8) : null,
      iconSize: compact ? 20 : null,
      icon: AnimatedSwitcher(
        duration: KgMotion.resolve(context, KgMotion.fast),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(liked),
        ),
      ),
      color: liked ? KgColors.accent : null,
    );
  }
}

Future<void> toggleSongFavorite(
  BuildContext context,
  WidgetRef ref,
  Song song,
) async {
  try {
    final liked = ref.read(songIsFavoriteProvider(song.id)).value ?? false;
    await ref.read(libraryRepositoryProvider).setFavorite(song, liked: !liked);
  } catch (_) {
    if (context.mounted) showAppError(context, '未能更新“我喜欢”，请稍后重试');
  }
}
