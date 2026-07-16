import 'package:kgmusic/core/models/song.dart';

/// Stable JSON representation shared by response caches and queue snapshots.
///
/// Keep persistence details here instead of maintaining one codec per cache
/// implementation. Unknown fields are intentionally ignored when decoding so
/// older snapshots remain readable after the model gains new metadata.
abstract final class SongCodec {
  static Map<String, Object?> encode(Song value) => {
    'id': value.id,
    'title': value.title,
    'artist': value.artist,
    'album': value.album,
    'durationSecs': value.durationSecs,
    'artworkUrl': value.artworkUrl,
    'privilege': value.privilege,
    'albumId': value.albumId,
    'mixSongId': value.mixSongId,
    'fileId': value.fileId,
    'hashes': {
      'standard': value.hashes.standard,
      'high': value.hashes.high,
      'flac': value.hashes.flac,
      'hiRes': value.hashes.hiRes,
      'super': value.hashes.superHash,
    },
  };

  static Song decode(Object? value) {
    final map = _map(value);
    final hashes = _map(map['hashes']);
    return Song(
      id: _string(map['id']) ?? 'unknown',
      title: _string(map['title']) ?? '未知歌曲',
      artist: _string(map['artist']),
      album: _string(map['album']),
      durationSecs: _int(map['durationSecs']),
      artworkUrl: _string(map['artworkUrl']),
      privilege: _int(map['privilege']),
      albumId: _int(map['albumId']),
      mixSongId: _int(map['mixSongId']),
      fileId: _int(map['fileId']),
      hashes: AudioHashes(
        standard: _string(hashes['standard']),
        high: _string(hashes['high']),
        flac: _string(hashes['flac']),
        hiRes: _string(hashes['hiRes']),
        superHash: _string(hashes['super']),
      ),
    );
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is! Map) throw const FormatException('歌曲缓存对象格式无效');
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String? _string(Object? value) => value is String ? value : null;

  static int? _int(Object? value) => value is num ? value.toInt() : null;
}
