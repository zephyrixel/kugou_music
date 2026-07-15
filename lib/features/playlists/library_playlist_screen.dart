import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/player/playback_queue_sources.dart';
import 'package:kgmusic/core/widgets/app_dialogs.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/paged_list_footer.dart';
import 'package:kgmusic/core/widgets/song_tile_actions.dart';
import 'package:kgmusic/features/playlists/playlist_scaffold.dart';

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
    // Header prefers cloud metadata count while pages are still arriving.
    final count = playlist.count > songs.length ? playlist.count : songs.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          if (!playlist.isSystem)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit' && !playlist.isCollected) {
                  unawaited(_edit(playlist));
                }
                if (value == 'delete') unawaited(_delete(playlist));
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
      body: PlaylistSongsView(
        title: playlist.name,
        artwork: playlist.artworkUrl,
        cacheId: 'playlist:${playlist.localId}',
        count: count,
        songs: songs,
        // Only full-screen spinner when nothing to show yet.
        loading: _loading && songs.isEmpty,
        error: _loadError,
        onRefresh: () => _load(force: true),
        onRetry: _load,
        songTrailing: (context, ref, song) => SongTileActions(
          song: song,
          onRemove: playlist.isWritable
              ? () => ref
                    .read(libraryRepositoryProvider)
                    .removeSong(playlist.localId!, song)
              : null,
        ),
        // Reuse the same footer used by public playlists / search.
        footerSlivers: loadMoreFooterSlivers(
          loading: _loading && songs.isNotEmpty,
          error: songs.isNotEmpty ? _loadError : null,
          onRetry: _load,
        ),
        queueRequest: (items) => PlaybackQueueRequest(
          origin: PlaybackQueueOrigin(
            kind: playlist.isMyFavorite
                ? PlaybackQueueOriginKind.favorites
                : PlaybackQueueOriginKind.libraryPlaylist,
            title: playlist.name,
            id: playlist.localId,
            totalCount: count,
          ),
          songs: List.unmodifiable(items),
          source: LibraryPlaylistPlaybackQueueSource(
            repository: ref.read(libraryRepositoryProvider),
            localId: playlist.localId!,
          ),
          nextPage: ((items.length + 99) ~/ 100) + 1,
          hasMore: items.length < count,
          pageSize: 100,
        ),
      ),
    );
  }

  Future<void> _edit(Playlist playlist) async {
    final result = await promptPlaylistEdit(
      context,
      name: playlist.name,
      intro: playlist.intro ?? '',
      tags: playlist.tags ?? '',
      private: playlist.isPrivate,
    );
    if (result == null) return;
    try {
      await ref
          .read(libraryRepositoryProvider)
          .editPlaylist(
            playlist.localId!,
            name: result.name,
            intro: result.intro,
            tags: result.tags,
            private: result.private,
          );
    } catch (error) {
      if (mounted) showAppError(context, error);
    }
  }

  Future<void> _delete(Playlist playlist) async {
    final accepted = await confirmDialog(
      context,
      title: playlist.isCollected ? '取消收藏歌单？' : '删除歌单？',
      content: '操作会写入本机并同步到云端。',
    );
    if (!accepted) return;
    try {
      await ref
          .read(libraryRepositoryProvider)
          .deletePlaylist(playlist.localId!);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) showAppError(context, error);
    }
  }
}
