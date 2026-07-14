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
    final auth = ref.watch(authControllerProvider);
    if (!auth.authenticated) {
      final favorites = ref.watch(favoritesProvider).value ?? const <Song>[];
      final liked = favorites.any((item) => item.id == song.id);
      return IconButton(
        tooltip: liked ? '取消本地收藏' : '本地收藏',
        onPressed: () => toggleSongFavorite(
          context,
          ref,
          song,
          liked: liked,
          likedSongs: favorites,
        ),
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

    final songs = ref.watch(myFavoriteSongsProvider);
    final liked = songs.value?.any((item) => item.id == song.id) ?? false;
    return IconButton(
      tooltip: liked ? '从云端我喜欢移除' : '添加到云端我喜欢',
      onPressed: songs.isLoading
          ? null
          : () => toggleSongFavorite(
              context,
              ref,
              song,
              liked: liked,
              likedSongs: songs.value ?? const [],
            ),
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
  Song song, {
  bool? liked,
  List<Song>? likedSongs,
}) async {
  final authenticated = ref.read(authControllerProvider).authenticated;
  if (!authenticated) {
    await ref.read(databaseProvider).toggleFavorite(song);
    return;
  }

  try {
    final List<Song> cloudFavorites =
        likedSongs ?? (await ref.read(myFavoriteSongsProvider.future));
    final isLiked = liked ?? cloudFavorites.any((item) => item.id == song.id);
    final playlist = await ref.read(myFavoritePlaylistProvider.future);
    if (playlist?.listId == null) throw Exception('账号没有可用的“我喜欢”歌单');
    if (isLiked) {
      final cached = cloudFavorites.firstWhere((item) => item.id == song.id);
      if (cached.fileId == null) throw Exception('缺少云端 fileId，请刷新“我喜欢”后重试');
      await ref
          .read(musicSdkProvider)
          .removeSongFromPlaylist(playlist!.listId!, cached.fileId!);
    } else {
      await ref
          .read(musicSdkProvider)
          .addSongToPlaylist(playlist!.listId!, song);
    }
    ref.invalidate(myFavoriteSongsProvider);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
