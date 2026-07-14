import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/song.dart';

void main() {
  test('duration formatter uses music time notation', () {
    expect(formatDuration(const Duration(seconds: 65)), '1:05');
  });

  test('song exposes a safe artist label', () {
    const song = Song(id: '1', title: 'Test', hashes: AudioHashes());
    expect(song.artistLabel, '未知歌手');
  });

  test('artwork URL resolves Kugou templates and protocol-relative URLs', () {
    expect(
      normalizeArtworkUrl('//imge.kugou.com/stdmusic/{size}/cover.jpg'),
      'https://imge.kugou.com/stdmusic/480/cover.jpg',
    );
    expect(
      normalizeArtworkUrl(
        'http://imge.kugou.com/stdmusic/%7Bsize%7D/cover.jpg',
        size: 720,
      ),
      'https://imge.kugou.com/stdmusic/720/cover.jpg',
    );
  });

  test('artwork URL rejects invalid and non-network values', () {
    expect(normalizeArtworkUrl(null), isNull);
    expect(normalizeArtworkUrl(''), isNull);
    expect(normalizeArtworkUrl('/local/cover.jpg'), isNull);
    expect(normalizeArtworkUrl('file:///tmp/cover.jpg'), isNull);
  });
}
