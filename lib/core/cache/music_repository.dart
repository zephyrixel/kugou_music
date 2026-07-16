import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:kgmusic/core/cache/cache_codec.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';

class MusicRepository {
  MusicRepository(this._remote, this._database);

  static const _keyVersion = 'v1';

  final BrowseSdk _remote;
  final AppDatabase _database;
  final Map<String, Future<Object?>> _inFlight = {};

  Stream<List<Song>> everydayRecommendations({int? userId}) => _cachedStream(
    key: '${_scope(userId)}/daily',
    accountUserId: userId,
    codec: CacheCodecs.songs,
    remote: _remote.everydayRecommendations,
  );

  Stream<SearchPage> search(
    String keyword, {
    int? userId,
    int page = 1,
    int pageSize = 30,
  }) => _cachedStream(
    key:
        '${_scope(userId)}/search/songs/${_queryHash(keyword)}/$page/$pageSize',
    accountUserId: userId,
    codec: CacheCodecs.searchPage,
    remote: () => _remote.search(keyword, page: page, pageSize: pageSize),
  );

  Stream<PlaylistSearchPage> searchPlaylists(
    String keyword, {
    int? userId,
    int page = 1,
    int pageSize = 30,
  }) => _cachedStream(
    key:
        '${_scope(userId)}/search/playlists/${_queryHash(keyword)}/$page/$pageSize',
    accountUserId: userId,
    codec: CacheCodecs.playlistSearchPage,
    remote: () =>
        _remote.searchPlaylists(keyword, page: page, pageSize: pageSize),
  );

  Stream<UserProfile> userProfile(int userId) => _cachedStream(
    key: '${_scope(userId)}/account/profile',
    accountUserId: userId,
    codec: CacheCodecs.userProfile,
    remote: _remote.userProfile,
  );

  Stream<UserVip> userVip(int userId) => _cachedStream(
    key: '${_scope(userId)}/account/vip',
    accountUserId: userId,
    codec: CacheCodecs.userVip,
    remote: _remote.userVip,
  );

  Stream<SearchPage> publicPlaylistTracks(
    String globalCollectionId, {
    int? userId,
    int page = 1,
    int pageSize = 50,
  }) => _cachedStream(
    key:
        '${_scope(userId)}/playlist/public/$globalCollectionId/$page/$pageSize',
    accountUserId: userId,
    codec: CacheCodecs.searchPage,
    remote: () => _remote.publicPlaylistTracks(
      globalCollectionId,
      page: page,
      pageSize: pageSize,
    ),
  );

  Stream<T> _cachedStream<T>({
    required String key,
    required int? accountUserId,
    required CacheCodec<T> codec,
    required Future<T> Function() remote,
  }) async* {
    T? cached;
    try {
      final row = await _database.readCachedResponse(key);
      if (row != null) {
        if (row.codecVersion == codec.version) {
          try {
            cached = codec.decode(row.payload);
          } catch (_) {
            await _database.deleteCachedResponse(key);
          }
        } else {
          await _database.deleteCachedResponse(key);
        }
      }
    } catch (_) {
      // A cache read must never make an otherwise valid remote request fail.
    }

    if (cached != null) yield cached;

    try {
      final fresh = await _coalesced(key, remote);
      try {
        await _database.writeCachedResponse(
          cacheKey: key,
          accountUserId: accountUserId,
          codecVersion: codec.version,
          payload: codec.encode(fresh),
        );
      } catch (_) {
        // The network result remains useful even when local persistence fails.
      }
      yield fresh;
    } on MusicSdkException catch (error) {
      if (cached != null && error.retryable) return;
      rethrow;
    }
  }

  Future<T> _coalesced<T>(String key, Future<T> Function() load) {
    final existing = _inFlight[key];
    if (existing != null) return existing.then((value) => value as T);

    late final Future<T> tracked;
    tracked = () async {
      try {
        return await load();
      } finally {
        if (identical(_inFlight[key], tracked)) _inFlight.remove(key);
      }
    }();
    _inFlight[key] = tracked;
    return tracked;
  }

  String _scope(int? userId) =>
      '$_keyVersion/${userId == null ? 'guest' : 'user/$userId'}';

  String _queryHash(String value) =>
      sha256.convert(utf8.encode(value.trim().toLowerCase())).toString();
}
