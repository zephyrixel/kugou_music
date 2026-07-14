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
}
