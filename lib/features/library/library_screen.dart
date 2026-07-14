import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/song.dart';
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
              '本地音乐库',
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
              children: [
                _SongStream(provider: favoritesProvider, emptyText: '还没有收藏歌曲'),
                _SongStream(provider: historyProvider, emptyText: '播放记录会出现在这里'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SongStream extends ConsumerWidget {
  const _SongStream({required this.provider, required this.emptyText});
  final StreamProvider<List<Song>> provider;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (songs) => songs.isEmpty
          ? Center(child: Text(emptyText))
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) => SongTile(
                song: songs[index],
                onTap: () => ref
                    .read(audioHandlerProvider)
                    .playSong(songs[index], queueSongs: songs),
                trailing: IconButton(
                  tooltip: '切换收藏',
                  onPressed: () =>
                      ref.read(databaseProvider).toggleFavorite(songs[index]),
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
