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
    final auth = ref.watch(authControllerProvider);
    if (!auth.authenticated) return const SizedBox.shrink();
    return IconButton(
      tooltip: '添加到云歌单',
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
    final page = await ref.read(cloudPlaylistsProvider.future);
    final writable = page.items
        .where((item) => item.isWritable && !item.isDefaultCollect)
        .toList();
    if (!context.mounted) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('添加到云歌单')),
            ...writable.map(
              (playlist) => ListTile(
                leading: Icon(
                  playlist.isMyFavorite
                      ? Icons.favorite_rounded
                      : Icons.queue_music_rounded,
                ),
                title: Text(playlist.name),
                subtitle: Text('${playlist.count ?? 0} 首'),
                onTap: () => context.pop(playlist.listId),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final userId = ref.read(authControllerProvider).snapshot.userId;
    if (userId == null) return;
    await ref
        .read(musicRepositoryProvider)
        .addSongToPlaylist(userId, selected, song);
    ref.invalidate(myFavoriteSongsProvider);
    ref.invalidate(cloudPlaylistsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已添加到云歌单')));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
