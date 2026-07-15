import 'package:flutter/widgets.dart';
import 'package:kgmusic/core/library/library_models.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/features/playlists/library_playlist_screen.dart';
import 'package:kgmusic/features/playlists/public_playlist_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.source});

  final Object source;

  @override
  Widget build(BuildContext context) => switch (source) {
    LibraryPlaylist playlist => LibraryPlaylistScreen(playlist: playlist),
    PlaylistSearchHit playlist => PublicPlaylistScreen(playlist: playlist),
    _ => const SizedBox.shrink(),
  };
}
