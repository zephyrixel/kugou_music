import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/cache/cache_codec.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/core/models/song.dart';

void main() {
  test('song cache codec preserves playback and playlist identifiers', () {
    const song = Song(
      id: 'mix:42',
      title: 'Cached Song',
      artist: 'Artist',
      album: 'Album',
      artworkUrl: 'https://example.com/cover.jpg',
      fileId: 99,
      mixSongId: 42,
      hashes: AudioHashes(standard: 'standard', high: 'high', flac: 'flac'),
    );

    final decoded = CacheCodecs.songs
        .decode(CacheCodecs.songs.encode(const [song]))
        .single;

    expect(decoded.id, song.id);
    expect(decoded.fileId, 99);
    expect(decoded.hashes.high, 'high');
    expect(decoded.artworkUrl, song.artworkUrl);
  });

  test('cloud playlist cache codec preserves pagination metadata', () {
    const page = CloudPlaylistPage(
      items: [
        CloudPlaylist(
          listId: 7,
          name: 'My List',
          isPrivate: true,
          isMyFavorite: false,
          isDefaultCollect: false,
        ),
      ],
      page: 2,
      pageSize: 50,
      total: 75,
      totalVersion: 3,
    );

    final decoded = CacheCodecs.cloudPlaylistPage.decode(
      CacheCodecs.cloudPlaylistPage.encode(page),
    );

    expect(decoded.page, 2);
    expect(decoded.total, 75);
    expect(decoded.items.single.listId, 7);
    expect(decoded.items.single.isPrivate, isTrue);
  });

  test('account cache codecs preserve profile and VIP state', () {
    const profile = UserProfile(
      userId: 42,
      displayName: 'Listener',
      avatarUrl: 'https://example.com/avatar.jpg',
      followingCount: 8,
    );
    const vip = UserVip(vipType: 1, productType: 'music');

    final decodedProfile = CacheCodecs.userProfile.decode(
      CacheCodecs.userProfile.encode(profile),
    );
    final decodedVip = CacheCodecs.userVip.decode(
      CacheCodecs.userVip.encode(vip),
    );

    expect(decodedProfile.displayName, 'Listener');
    expect(decodedProfile.followingCount, 8);
    expect(decodedVip.active, isTrue);
    expect(decodedVip.productType, 'music');
  });
}
