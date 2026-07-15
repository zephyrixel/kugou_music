import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
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
          const KgPageHeader(title: '音乐库', subtitle: '收藏与最近听过的音乐'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: KgColors.elevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const TabBar(
                indicator: BoxDecoration(
                  color: KgColors.elevatedHigh,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: '收藏'),
                  Tab(text: '最近播放'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
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

class _FavoriteSongs extends ConsumerStatefulWidget {
  const _FavoriteSongs();

  @override
  ConsumerState<_FavoriteSongs> createState() => _FavoriteSongsState();
}

class _FavoriteSongsState extends ConsumerState<_FavoriteSongs> {
  bool _requested = false;
  bool _loading = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  Future<void> _ensureLoaded() async {
    if (_requested) return;
    _requested = true;
    if (mounted) setState(() => _loading = true);
    try {
      await ref.read(libraryRepositoryProvider).ensureFavoriteLoaded();
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(favoriteSongsProvider);
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => KgErrorView(
        error: error,
        onRetry: () async {
          _requested = false;
          await _ensureLoaded();
        },
      ),
      data: (songs) => songs.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator())
          : songs.isEmpty && _loadError != null
          ? KgErrorView(
              error: _loadError!,
              onRetry: () async {
                _requested = false;
                _loadError = null;
                await _ensureLoaded();
              },
            )
          : songs.isEmpty
          ? const KgEmptyView('还没有收藏歌曲', icon: Icons.favorite_border_rounded)
          : _SongCollectionList(
              songs: songs,
              label: '${songs.length} 首收藏',
              trailingBuilder: (song) => IconButton(
                tooltip: '取消喜欢',
                onPressed: () =>
                    ref.read(libraryRepositoryProvider).toggleFavorite(song),
                icon: const Icon(Icons.favorite_rounded, size: 20),
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
      error: (error, _) => KgErrorView(
        error: error,
        onRetry: () async => ref.invalidate(historyEntriesProvider),
      ),
      data: (entries) {
        final songs = entries
            .map((entry) => entry.song)
            .toList(growable: false);
        if (songs.isEmpty) {
          return const KgEmptyView('播放记录会出现在这里', icon: Icons.history_rounded);
        }
        return _SongCollectionList(songs: songs, label: '最近 ${songs.length} 首');
      },
    );
  }
}

class _SongCollectionList extends ConsumerWidget {
  const _SongCollectionList({
    required this.songs,
    required this.label,
    this.trailingBuilder,
  });

  final List<Song> songs;
  final String label;
  final Widget Function(Song song)? trailingBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView.builder(
    padding: const EdgeInsets.only(top: 8, bottom: 24),
    itemCount: songs.length + 1,
    itemBuilder: (context, index) {
      if (index == 0) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: KgColors.textMuted),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () =>
                    playSong(context, ref, songs.first, queue: songs),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('播放全部'),
              ),
            ],
          ),
        );
      }
      final song = songs[index - 1];
      return SongTile(
        song: song,
        onTap: () => playSong(context, ref, song, queue: songs),
        trailing: trailingBuilder?.call(song),
      );
    },
  );
}
