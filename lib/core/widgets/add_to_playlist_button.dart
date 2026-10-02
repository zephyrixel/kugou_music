import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/kg_overlays.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/playlist_tile.dart';

class AddToPlaylistButton extends ConsumerWidget {
  const AddToPlaylistButton({
    super.key,
    required this.song,
    this.compact = false,
  });

  final Song song;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: '添加到歌单',
      onPressed: ref.watch(libraryReadyProvider)
          ? () => showAddToPlaylist(context, ref, song)
          : null,
      padding: compact ? const EdgeInsets.all(8) : null,
      iconSize: compact ? 21 : null,
      icon: const Icon(Icons.playlist_add_rounded),
    );
  }
}

Future<void> showAddToPlaylist(
  BuildContext context,
  WidgetRef ref,
  Song song,
) async {
  try {
    final selected = await showKgModalBottomSheet<String>(
      context: context,
      builder: (_) => const _AddToPlaylistSheet(),
    );
    if (selected == null || !context.mounted) return;
    await ref.read(libraryRepositoryProvider).addSong(selected, song);
    if (context.mounted) showAppMessage(context, '已添加到歌单');
  } catch (_) {
    if (context.mounted) showAppError(context, '未能添加到歌单，请稍后重试');
  }
}

class _AddToPlaylistSheet extends ConsumerWidget {
  const _AddToPlaylistSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    child: CustomScrollView(
      shrinkWrap: true,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text('添加到歌单', style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        ref
            .watch(libraryPlaylistsProvider)
            .when(
              loading: () => const SliverToBoxAdapter(
                child: KgLoadingView(label: '正在读取歌单', compact: true),
              ),
              error: (_, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: KgErrorView(
                    message: '歌单读取失败',
                    compact: true,
                    onRetry: () async =>
                        ref.invalidate(libraryPlaylistsProvider),
                  ),
                ),
              ),
              data: (playlists) {
                final writable = playlists
                    .where(
                      (item) =>
                          item.isWritable &&
                          !item.isDefaultCollect &&
                          item.localId != null,
                    )
                    .toList();
                if (writable.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Text('暂无可添加的歌单，请先在“我的”中新建歌单。'),
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: writable.length,
                  itemBuilder: (context, index) {
                    final playlist = writable[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: HeroMode(
                        enabled: false,
                        child: PlaylistTile(
                          title: playlist.name,
                          cacheId: 'playlist:${playlist.localId}',
                          artworkUrl: playlist.artworkUrl,
                          subtitle: '${playlist.count} 首',
                          badge: playlist.isPrivate ? '私密' : null,
                          onTap: () =>
                              Navigator.pop(context, playlist.localId!),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    ),
  );
}
