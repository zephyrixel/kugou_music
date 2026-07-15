import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';

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
    final ids = ref.watch(favoriteSongIdsProvider);
    final liked = ids.value?.contains(song.id) ?? false;
    return IconButton(
      tooltip: liked ? '取消喜欢' : '添加到我喜欢',
      onPressed: ids.isLoading
          ? null
          : () => toggleSongFavorite(context, ref, song),
      constraints: compact
          ? const BoxConstraints.tightFor(width: 40, height: 40)
          : null,
      padding: compact ? const EdgeInsets.all(8) : null,
      iconSize: compact ? 20 : null,
      icon: Icon(
        liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
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
    await ref.read(libraryRepositoryProvider).toggleFavorite(song);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
