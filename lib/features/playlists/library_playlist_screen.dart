import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/play_song.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/core/widgets/song_tile_actions.dart';
import 'package:kgmusic/features/playlists/playlist_header.dart';

class LibraryPlaylistScreen extends ConsumerStatefulWidget {
  const LibraryPlaylistScreen({super.key, required this.playlist});

  final Playlist playlist;

  @override
  ConsumerState<LibraryPlaylistScreen> createState() =>
      _LibraryPlaylistScreenState();
}

class _LibraryPlaylistScreenState extends ConsumerState<LibraryPlaylistScreen> {
  Object? _loadError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool force = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await ref
          .read(libraryRepositoryProvider)
          .ensurePlaylistLoaded(widget.playlist.localId!, force: force);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(libraryPlaylistsProvider).value ?? const [];
    final current = playlists
        .where((item) => item.localId == widget.playlist.localId)
        .firstOrNull;
    final playlist = current ?? widget.playlist;
    final tracks = ref.watch(
      libraryPlaylistTracksProvider(widget.playlist.localId!),
    );
    final songs = tracks.value ?? const <Song>[];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          if (!playlist.isSystem)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit' && !playlist.isCollected) {
                  _edit(playlist);
                }
                if (value == 'delete') _delete(playlist);
              },
              itemBuilder: (_) => [
                if (!playlist.isCollected)
                  const PopupMenuItem(value: 'edit', child: Text('编辑歌单')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(playlist.isCollected ? '取消收藏' : '删除歌单'),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PlaylistHeader(
                title: playlist.name,
                artwork: playlist.artworkUrl,
                cacheId: 'playlist:${playlist.localId}',
                count: songs.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: songs.isEmpty
                        ? null
                        : () => playSong(context, ref, songs.first, queue: songs),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('播放全部'),
                  ),
                ),
              ),
            ),
            if (_loading && songs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null && songs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: PlaylistLoadError(error: _loadError!, retry: _load),
              )
            else if (songs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('歌单中没有歌曲')),
              )
            else
              SliverList.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return SongTile(
                    song: song,
                    index: index + 1,
                    onTap: () => playSong(context, ref, song, queue: songs),
                    trailing: SongTileActions(
                      song: song,
                      onRemove: playlist.isWritable
                          ? () => ref
                                .read(libraryRepositoryProvider)
                                .removeSong(playlist.localId!, song)
                          : null,
                    ),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(Playlist playlist) async {
    final name = TextEditingController(text: playlist.name);
    final intro = TextEditingController(text: playlist.intro);
    final tags = TextEditingController(text: playlist.tags);
    var private = playlist.isPrivate;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑歌单'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: intro,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '简介'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tags,
                decoration: const InputDecoration(labelText: '标签（逗号分隔）'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('私密歌单'),
                value: private,
                onChanged: (value) => setState(() => private = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    final nextName = name.text.trim();
    final nextIntro = intro.text.trim();
    final nextTags = tags.text.trim();
    name.dispose();
    intro.dispose();
    tags.dispose();
    if (accepted != true || nextName.isEmpty) return;
    await ref
        .read(libraryRepositoryProvider)
        .editPlaylist(
          playlist.localId!,
          name: nextName,
          intro: nextIntro,
          tags: nextTags,
          private: private,
        );
  }

  Future<void> _delete(Playlist playlist) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(playlist.isCollected ? '取消收藏歌单？' : '删除歌单？'),
        content: const Text('操作会写入本机并同步到云端。'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await ref.read(libraryRepositoryProvider).deletePlaylist(playlist.localId!);
    if (mounted) context.pop();
  }
}
