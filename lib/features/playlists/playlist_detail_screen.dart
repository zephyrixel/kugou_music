import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/features/playlists/library_playlist_screen.dart';
import 'package:kgmusic/features/playlists/public_playlist_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.source});
  final PlaylistTarget? source;

  @override
  Widget build(BuildContext context) => switch (source) {
    LibraryPlaylistTarget(:final playlist) => LibraryPlaylistScreen(
      playlist: playlist,
    ),
    PublicPlaylistTarget(:final playlist) => PublicPlaylistScreen(
      playlist: playlist,
    ),
    null => Scaffold(
      appBar: AppBar(title: const Text('歌单')),
      body: KgEmptyView(
        '歌单信息已失效，请从音乐库或搜索重新打开',
        action: FilledButton(
          onPressed: () => context.go('/library'),
          child: const Text('返回音乐库'),
        ),
      ),
    ),
  };
}
