import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';

void main() {
  test('cloud playlist cache is account scoped and clearable', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    const playlist = CloudPlaylist(
      listId: 2,
      name: '我喜欢',
      isPrivate: true,
      isMyFavorite: true,
      isDefaultCollect: false,
      listType: 0,
    );
    await database.cacheCloudPlaylists(42, const [playlist]);

    expect(await database.watchCachedCloudPlaylists(42).first, hasLength(1));
    expect(await database.watchCachedCloudPlaylists(7).first, isEmpty);

    await database.clearCloudCache();
    expect(await database.watchCachedCloudPlaylists(42).first, isEmpty);
  });
}
