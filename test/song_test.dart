import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';

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

  test('audio quality availability follows exact resource hashes', () {
    const song = Song(
      id: 'quality',
      title: 'Quality',
      hashes: AudioHashes(standard: 'STD', high: 'HQ', flac: 'FLAC'),
    );
    expect(AudioQuality.standard.isAvailableFor(song), isTrue);
    expect(AudioQuality.high.isAvailableFor(song), isTrue);
    expect(AudioQuality.flac.isAvailableFor(song), isTrue);
    expect(AudioQuality.hiRes.isAvailableFor(song), isFalse);
    expect(AudioQuality.superQuality.isAvailableFor(song), isFalse);
  });

  test('playback quality state reports bitrate and fallback', () {
    const state = PlaybackQualityState(
      requested: AudioQuality.flac,
      actual: AudioQuality.high,
      bitRate: 320000,
    );
    expect(state.bitRateKbps, 320);
    expect(state.fellBack, isTrue);
  });
}
