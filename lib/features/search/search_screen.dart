import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/core/widgets/song_tile_actions.dart';

enum _SearchKind { songs, playlists }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Song> _songs = const [];
  List<PlaylistSearchHit> _playlists = const [];
  _SearchKind _kind = _SearchKind.songs;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _songs = const [];
        _playlists = const [];
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String keyword) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_kind == _SearchKind.songs) {
        final result = await ref.read(musicSdkProvider).search(keyword.trim());
        if (!mounted || keyword != _controller.text) return;
        setState(() => _songs = result.songs);
      } else {
        final result = await ref
            .read(musicSdkProvider)
            .searchPlaylists(keyword.trim());
        if (!mounted || keyword != _controller.text) return;
        setState(() => _playlists = result.items);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('搜索', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),
              SegmentedButton<_SearchKind>(
                segments: const [
                  ButtonSegment(
                    value: _SearchKind.songs,
                    icon: Icon(Icons.music_note_rounded),
                    label: Text('歌曲'),
                  ),
                  ButtonSegment(
                    value: _SearchKind.playlists,
                    icon: Icon(Icons.queue_music_rounded),
                    label: Text('歌单'),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (value) {
                  setState(() => _kind = value.first);
                  if (_controller.text.trim().isNotEmpty) {
                    _search(_controller.text);
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: _kind == _SearchKind.songs ? '歌曲、歌手或专辑' : '搜索公开歌单',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        Expanded(
          child: _kind == _SearchKind.songs
              ? _songResults()
              : _playlistResults(),
        ),
      ],
    ),
  );

  Widget _songResults() => _songs.isEmpty
      ? _Empty(query: _controller.text)
      : ListView.builder(
          itemCount: _songs.length,
          itemBuilder: (context, index) => SongTile(
            song: _songs[index],
            onTap: () => _play(_songs[index]),
            trailing: SongTileActions(song: _songs[index]),
          ),
        );

  Widget _playlistResults() => _playlists.isEmpty
      ? _Empty(query: _controller.text)
      : ListView.builder(
          itemCount: _playlists.length,
          itemBuilder: (context, index) {
            final playlist = _playlists[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 5,
              ),
              leading: SongArtwork(url: playlist.artworkUrl),
              title: Text(
                playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${playlist.creatorName ?? '未知创建者'} · ${playlist.songCount ?? 0} 首',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: playlist.globalCollectionId == null
                  ? null
                  : () => context.push('/playlist', extra: playlist),
            );
          },
        );

  Future<void> _play(Song song) async {
    try {
      await ref.read(audioHandlerProvider).playSong(song, queueSongs: _songs);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.query});
  final String query;
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      query.isEmpty ? '输入关键词，探索 Lite 曲库' : '没有找到结果',
      style: const TextStyle(color: KgColors.textMuted),
    ),
  );
}
