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

String? normalizeArtworkUrl(String? rawUrl, {int size = 480}) {
  var value = rawUrl?.trim();
  if (value == null || value.isEmpty || value == '-') return null;

  value = value
      .replaceAll(RegExp(r'\{size\}', caseSensitive: false), '$size')
      .replaceAll(RegExp(r'%7Bsize%7D', caseSensitive: false), '$size')
      .replaceAll(RegExp(r'\{width\}', caseSensitive: false), '$size')
      .replaceAll(RegExp(r'\{height\}', caseSensitive: false), '$size');
  if (value.startsWith('//')) value = 'https:$value';

  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasAuthority ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  final host = uri.host.toLowerCase();
  final isKugouImageHost =
      host == 'kugou.com' ||
      host.endsWith('.kugou.com') ||
      host == 'kgimg.com' ||
      host.endsWith('.kgimg.com');
  return uri.scheme == 'http' && isKugouImageHost
      ? uri.replace(scheme: 'https').toString()
      : uri.toString();
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
