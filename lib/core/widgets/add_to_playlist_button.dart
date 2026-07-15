import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/song.dart';

class AddToPlaylistButton extends ConsumerWidget {
  const AddToPlaylistButton({super.key, required this.song});
  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: '添加到歌单',
      onPressed: () => showAddToCloudPlaylist(context, ref, song),
      icon: const Icon(Icons.playlist_add_rounded),
    );
  }
}

Future<void> showAddToCloudPlaylist(
  BuildContext context,
  WidgetRef ref,
  Song song,
) async {
  try {
    final playlists = await ref.read(libraryPlaylistsProvider.future);
    final writable = playlists
        .where((item) => item.isWritable && !item.isDefaultCollect)
        .toList();
    if (!context.mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('添加到歌单')),
            ...writable.map(
              (playlist) => ListTile(
                leading: Icon(
                  playlist.isMyFavorite
                      ? Icons.favorite_rounded
                      : Icons.queue_music_rounded,
                ),
                title: Text(playlist.name),
                subtitle: Text('${playlist.count} 首'),
                onTap: () => context.pop(playlist.localId),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await ref.read(libraryRepositoryProvider).addSong(selected, song);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已添加到歌单，正在后台同步')));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
