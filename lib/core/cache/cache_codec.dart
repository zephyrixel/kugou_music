import 'dart:convert';

import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';

class CacheCodec<T> {
  const CacheCodec({
    required this.encodeValue,
    required this.decodeValue,
    this.version = 1,
  });

  final Object? Function(T value) encodeValue;
  final T Function(Object? value) decodeValue;
  final int version;

  String encode(T value) => jsonEncode(encodeValue(value));

  T decode(String value) => decodeValue(jsonDecode(value));
}

abstract final class CacheCodecs {
  static final songs = CacheCodec<List<Song>>(
    encodeValue: (value) => value.map(_songToJson).toList(growable: false),
    decodeValue: (value) => _list(
      value,
    ).map((item) => _songFromJson(_map(item))).toList(growable: false),
  );

  static final searchPage = CacheCodec<SearchPage>(
    encodeValue: (value) => {
      'songs': value.songs.map(_songToJson).toList(growable: false),
      'page': value.page,
      'pageSize': value.pageSize,
      'total': value.total,
    },
    decodeValue: (value) {
      final map = _map(value);
      return SearchPage(
        songs: _list(
          map['songs'],
        ).map((item) => _songFromJson(_map(item))).toList(growable: false),
        page: _int(map['page']) ?? 1,
        pageSize: _int(map['pageSize']) ?? 30,
        total: _int(map['total']),
      );
    },
  );

  static final playlistSearchPage = CacheCodec<PlaylistSearchPage>(
    encodeValue: (value) => {
      'items': value.items
          .map(_playlistSearchHitToJson)
          .toList(growable: false),
      'page': value.page,
      'pageSize': value.pageSize,
      'total': value.total,
    },
    decodeValue: (value) {
      final map = _map(value);
      return PlaylistSearchPage(
        items: _list(map['items'])
            .map((item) => _playlistSearchHitFromJson(_map(item)))
            .toList(growable: false),
        page: _int(map['page']) ?? 1,
        pageSize: _int(map['pageSize']) ?? 30,
        total: _int(map['total']),
      );
    },
  );

  static final cloudPlaylistPage = CacheCodec<CloudPlaylistPage>(
    encodeValue: (value) => {
      'items': value.items.map(_cloudPlaylistToJson).toList(growable: false),
      'page': value.page,
      'pageSize': value.pageSize,
      'total': value.total,
      'totalVersion': value.totalVersion,
    },
    decodeValue: (value) {
      final map = _map(value);
      return CloudPlaylistPage(
        items: _list(map['items'])
            .map((item) => _cloudPlaylistFromJson(_map(item)))
            .toList(growable: false),
        page: _int(map['page']) ?? 1,
        pageSize: _int(map['pageSize']) ?? 50,
        total: _int(map['total']),
        totalVersion: _int(map['totalVersion']),
      );
    },
  );

  static final userProfile = CacheCodec<UserProfile>(
    encodeValue: (value) => {
      'userId': value.userId,
      'displayName': value.displayName,
      'username': value.username,
      'avatarUrl': value.avatarUrl,
      'gender': value.gender,
      'birthday': value.birthday,
      'city': value.city,
      'province': value.province,
      'signature': value.signature,
      'followingCount': value.followingCount,
      'fanCount': value.fanCount,
      'visitorCount': value.visitorCount,
    },
    decodeValue: (value) {
      final map = _map(value);
      return UserProfile(
        userId: _int(map['userId']),
        displayName: _string(map['displayName']) ?? '酷狗用户',
        username: _string(map['username']),
        avatarUrl: _string(map['avatarUrl']),
        gender: _int(map['gender']),
        birthday: _string(map['birthday']),
        city: _string(map['city']),
        province: _string(map['province']),
        signature: _string(map['signature']),
        followingCount: _int(map['followingCount']),
        fanCount: _int(map['fanCount']),
        visitorCount: _int(map['visitorCount']),
      );
    },
  );

  static final userVip = CacheCodec<UserVip>(
    encodeValue: (value) => {
      'vipType': value.vipType,
      'musicPackageType': value.musicPackageType,
      'yearlyType': value.yearlyType,
      'vipEndTime': value.vipEndTime,
      'musicEndTime': value.musicEndTime,
      'yearlyEndTime': value.yearlyEndTime,
      'productType': value.productType,
    },
    decodeValue: (value) {
      final map = _map(value);
      return UserVip(
        vipType: _int(map['vipType']),
        musicPackageType: _int(map['musicPackageType']),
        yearlyType: _int(map['yearlyType']),
        vipEndTime: _string(map['vipEndTime']),
        musicEndTime: _string(map['musicEndTime']),
        yearlyEndTime: _string(map['yearlyEndTime']),
        productType: _string(map['productType']),
      );
    },
  );
}

Map<String, Object?> _songToJson(Song value) => {
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

Song _songFromJson(Map<String, Object?> value) {
  final hashes = _map(value['hashes']);
  return Song(
    id: _string(value['id']) ?? 'unknown',
    title: _string(value['title']) ?? '未知歌曲',
    artist: _string(value['artist']),
    album: _string(value['album']),
    durationSecs: _int(value['durationSecs']),
    artworkUrl: _string(value['artworkUrl']),
    privilege: _int(value['privilege']),
    albumId: _int(value['albumId']),
    mixSongId: _int(value['mixSongId']),
    fileId: _int(value['fileId']),
    hashes: AudioHashes(
      standard: _string(hashes['standard']),
      high: _string(hashes['high']),
      flac: _string(hashes['flac']),
      hiRes: _string(hashes['hiRes']),
      superHash: _string(hashes['super']),
    ),
  );
}

Map<String, Object?> _cloudPlaylistToJson(CloudPlaylist value) => {
  'listId': value.listId,
  'globalCollectionId': value.globalCollectionId,
  'name': value.name,
  'intro': value.intro,
  'artworkUrl': value.artworkUrl,
  'count': value.count,
  'listType': value.listType,
  'creatorUserId': value.creatorUserId,
  'creatorName': value.creatorName,
  'isPrivate': value.isPrivate,
  'isMyFavorite': value.isMyFavorite,
  'isDefaultCollect': value.isDefaultCollect,
  'tags': value.tags,
};

CloudPlaylist _cloudPlaylistFromJson(Map<String, Object?> value) =>
    CloudPlaylist(
      listId: _int(value['listId']),
      globalCollectionId: _string(value['globalCollectionId']),
      name: _string(value['name']) ?? '未命名歌单',
      intro: _string(value['intro']),
      artworkUrl: _string(value['artworkUrl']),
      count: _int(value['count']),
      listType: _int(value['listType']),
      creatorUserId: _int(value['creatorUserId']),
      creatorName: _string(value['creatorName']),
      isPrivate: value['isPrivate'] == true,
      isMyFavorite: value['isMyFavorite'] == true,
      isDefaultCollect: value['isDefaultCollect'] == true,
      tags: _string(value['tags']),
    );

Map<String, Object?> _playlistSearchHitToJson(PlaylistSearchHit value) => {
  'specialId': value.specialId,
  'globalCollectionId': value.globalCollectionId,
  'name': value.name,
  'intro': value.intro,
  'artworkUrl': value.artworkUrl,
  'songCount': value.songCount,
  'playCount': value.playCount,
  'collectCount': value.collectCount,
  'creatorName': value.creatorName,
  'creatorUserId': value.creatorUserId,
  'tags': value.tags,
};

PlaylistSearchHit _playlistSearchHitFromJson(Map<String, Object?> value) =>
    PlaylistSearchHit(
      specialId: _int(value['specialId']),
      globalCollectionId: _string(value['globalCollectionId']),
      name: _string(value['name']) ?? '未命名歌单',
      intro: _string(value['intro']),
      artworkUrl: _string(value['artworkUrl']),
      songCount: _int(value['songCount']),
      playCount: _int(value['playCount']),
      collectCount: _int(value['collectCount']),
      creatorName: _string(value['creatorName']),
      creatorUserId: _int(value['creatorUserId']),
      tags: _string(value['tags']),
    );

Map<String, Object?> _map(Object? value) {
  if (value is! Map) throw const FormatException('缓存对象格式无效');
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<Object?> _list(Object? value) {
  if (value is! List) throw const FormatException('缓存列表格式无效');
  return value.cast<Object?>();
}

String? _string(Object? value) => value is String ? value : null;

int? _int(Object? value) => value is num ? value.toInt() : null;
