import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/add_to_playlist_button.dart';
import 'package:kgmusic/core/widgets/song_favorite_button.dart';

enum _SongAction { favorite, addToPlaylist, remove }

class SongTileActions extends ConsumerWidget {
  const SongTileActions({
    super.key,
    required this.song,
    this.onRemove,
    this.removeLabel = '从当前歌单移除',
  });

  final Song song;
  final Future<void> Function()? onRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteSongIdsProvider);
    final liked = ids.value?.contains(song.id) ?? false;
    return SizedBox.square(
      dimension: 40,
      child: PopupMenuButton<_SongAction>(
        tooltip: '更多操作',
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: const Icon(Icons.more_vert_rounded),
        onSelected: (action) async {
          switch (action) {
            case _SongAction.favorite:
              await toggleSongFavorite(context, ref, song);
            case _SongAction.addToPlaylist:
              await showAddToPlaylist(context, ref, song);
            case _SongAction.remove:
              await onRemove?.call();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _SongAction.favorite,
            enabled: !ids.isLoading,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              ),
              title: Text(liked ? '取消喜欢' : '添加到我喜欢'),
            ),
          ),
          const PopupMenuItem(
            value: _SongAction.addToPlaylist,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.playlist_add_rounded),
              title: Text('添加到歌单'),
            ),
          ),
          if (onRemove != null)
            PopupMenuItem(
              value: _SongAction.remove,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.remove_circle_outline_rounded),
                title: Text(removeLabel),
              ),
            ),
        ],
      ),
    );
  }
}
