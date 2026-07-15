import 'package:flutter/widgets.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/features/playlists/library_playlist_screen.dart';
import 'package:kgmusic/features/playlists/public_playlist_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.source});

  final Object source;

  @override
  Widget build(BuildContext context) => switch (source) {
    Playlist playlist => LibraryPlaylistScreen(playlist: playlist),
    PlaylistSearchHit playlist => PublicPlaylistScreen(playlist: playlist),
    _ => const SizedBox.shrink(),
  };
}
