import 'package:kgmusic/core/models/song.dart';

class DiscoveryCard {
  const DiscoveryCard({
    required this.id,
    required this.title,
    required this.songs,
    this.subtitle,
  });

  final int id;
  final String title;
  final String? subtitle;
  final List<Song> songs;
}
