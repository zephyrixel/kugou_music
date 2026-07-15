import 'package:kgmusic/core/models/lyric.dart';
import 'package:kgmusic/core/models/song.dart';

abstract interface class LyricsSdk {
  Future<LyricDocument?> fetchLyrics(Song song);
}
