import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';

void main() {
  test('my favorite is a protected writable system playlist', () {
    const playlist = CloudPlaylist(
      listId: 2,
      name: '我喜欢',
      isPrivate: true,
      isMyFavorite: true,
      isDefaultCollect: false,
      listType: 0,
    );
    expect(playlist.isSystem, isTrue);
    expect(playlist.isWritable, isTrue);
    expect(playlist.isCollected, isFalse);
  });

  test('collected playlists are not track-writable', () {
    const playlist = CloudPlaylist(
      listId: 9,
      name: '收藏歌单',
      isPrivate: false,
      isMyFavorite: false,
      isDefaultCollect: false,
      listType: 1,
    );
    expect(playlist.isCollected, isTrue);
    expect(playlist.isWritable, isFalse);
  });
}
