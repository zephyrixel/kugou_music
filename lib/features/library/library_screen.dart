import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 2,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              '音乐库',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: '收藏'),
              Tab(text: '最近播放'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [const _FavoriteSongs(), const _HistorySongs()],
            ),
          ),
        ],
      ),
    ),
  );
}

class _FavoriteSongs extends ConsumerWidget {
  const _FavoriteSongs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(favoriteSongsProvider);
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (songs) => songs.isEmpty
          ? const Center(child: Text('还没有收藏歌曲'))
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) => SongTile(
                song: songs[index],
                onTap: () => ref
                    .read(audioHandlerProvider)
                    .playSong(songs[index], queueSongs: songs),
                trailing: IconButton(
                  tooltip: '取消喜欢',
                  onPressed: () => ref
                      .read(libraryRepositoryProvider)
                      .toggleFavorite(songs[index]),
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  padding: const EdgeInsets.all(8),
                  iconSize: 20,
                  icon: const Icon(Icons.favorite_rounded),
                ),
              ),
            ),
    );
  }
}

class _HistorySongs extends ConsumerWidget {
  const _HistorySongs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(historyEntriesProvider);
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (entries) {
        final songs = entries
            .map((entry) => entry.song)
            .toList(growable: false);
        if (songs.isEmpty) {
          return const Center(child: Text('播放记录会出现在这里'));
        }
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) => SongTile(
            song: songs[index],
            onTap: () => ref
                .read(audioHandlerProvider)
                .playSong(songs[index], queueSongs: songs),
          ),
        );
      },
    );
  }
}
