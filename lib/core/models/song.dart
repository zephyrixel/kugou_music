class Song {
  const Song({
    required this.id,
    required this.title,
    required this.hashes,
    this.artist,
    this.album,
    this.durationSecs,
    this.artworkUrl,
    this.privilege,
    this.albumId,
    this.mixSongId,
    this.fileId,
  });

  final String id;
  final String title;
  final String? artist;
  final String? album;
  final int? durationSecs;
  final String? artworkUrl;
  final int? privilege;
  final int? albumId;
  final int? mixSongId;
  final int? fileId;
  final AudioHashes hashes;

  String get artistLabel =>
      artist?.trim().isNotEmpty == true ? artist! : '未知歌手';

  Song copyWith({String? artworkUrl}) => Song(
    id: id,
    title: title,
    artist: artist,
    album: album,
    durationSecs: durationSecs,
    artworkUrl: artworkUrl ?? this.artworkUrl,
    privilege: privilege,
    albumId: albumId,
    mixSongId: mixSongId,
    fileId: fileId,
    hashes: hashes,
  );
}

class AudioHashes {
  const AudioHashes({
    this.standard,
    this.high,
    this.flac,
    this.hiRes,
    this.superHash,
  });

  final String? standard;
  final String? high;
  final String? flac;
  final String? hiRes;
  final String? superHash;
}

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
