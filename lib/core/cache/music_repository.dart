import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:kgmusic/core/auth/account_session.dart';
import 'package:kgmusic/core/cache/cache_codec.dart';
import 'package:kgmusic/core/cache/cache_policy.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/discovery_card.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';

class MusicRepository {
  MusicRepository(
    this._remote,
    this._database, {
    DateTime Function()? now,
    AccountSession? accountSession,
  }) : _now = now ?? _database.now,
       _session = accountSession;

  static const _keyVersion = 'v1';

  final BrowseSdk _remote;
  final AppDatabase _database;
  final AccountSession? _session;
  final DateTime Function() _now;
  final Map<String, Future<Object?>> _inFlight = {};
  final Map<String, DateTime> _lastRemoteRequestAt = {};

  Stream<List<Song>> everydayRecommendations({
    int? userId,
    CacheLoadMode mode = CacheLoadMode.normal,
  }) => _cachedStream(
    key: '${_scope(userId)}/daily',
    accountUserId: userId,
    codec: CacheCodecs.songs,
    policy: MusicCachePolicies.daily,
    mode: mode,
    remote: _remote.everydayRecommendations,
  );

  Stream<DiscoveryCard> discoveryCard(
    int cardId, {
    int? userId,
    int pageSize = 10,
    CacheLoadMode mode = CacheLoadMode.normal,
  }) => _cachedStream(
    key: '${_scope(userId)}/discovery/$cardId/$pageSize',
    accountUserId: userId,
    codec: CacheCodecs.discoveryCard,
    policy: MusicCachePolicies.discovery,
    mode: mode,
    remote: () => _remote.discoveryCard(cardId, pageSize: pageSize),
  );

  Stream<SearchPage> search(
    String keyword, {
    int? userId,
    int page = 1,
    int pageSize = 30,
    CacheLoadMode mode = CacheLoadMode.normal,
  }) => _cachedStream(
    key:
        '${_scope(userId)}/search/songs/${_queryHash(keyword)}/$page/$pageSize',
    accountUserId: userId,
    codec: CacheCodecs.searchPage,
    policy: MusicCachePolicies.search,
    mode: mode,
    remote: () => _remote.search(keyword, page: page, pageSize: pageSize),
  );

  Stream<PlaylistSearchPage> searchPlaylists(
    String keyword, {
    int? userId,
    int page = 1,
    int pageSize = 30,
    CacheLoadMode mode = CacheLoadMode.normal,
  }) => _cachedStream(
    key:
        '${_scope(userId)}/search/playlists/${_queryHash(keyword)}/$page/$pageSize',
    accountUserId: userId,
    codec: CacheCodecs.playlistSearchPage,
    policy: MusicCachePolicies.search,
    mode: mode,
    remote: () =>
        _remote.searchPlaylists(keyword, page: page, pageSize: pageSize),
  );

  Stream<UserProfile> userProfile(
    int userId, {
    CacheLoadMode mode = CacheLoadMode.normal,
  }) => _cachedStream(
    key: '${_scope(userId)}/account/profile',
    accountUserId: userId,
    codec: CacheCodecs.userProfile,
    policy: MusicCachePolicies.profile,
    mode: mode,
    remote: _remote.userProfile,
  );

  Stream<UserVip> userVip(
    int userId, {
    CacheLoadMode mode = CacheLoadMode.normal,
  }) => _cachedStream(
    key: '${_scope(userId)}/account/vip',
    accountUserId: userId,
    codec: CacheCodecs.userVip,
    policy: MusicCachePolicies.vip,
    mode: mode,
    remote: _remote.userVip,
  );

  Stream<SearchPage> publicPlaylistTracks(
    String globalCollectionId, {
    int? userId,
    int page = 1,
    int pageSize = 50,
    CacheLoadMode mode = CacheLoadMode.normal,
  }) => _cachedStream(
    key:
        '${_scope(userId)}/playlist/public/$globalCollectionId/$page/$pageSize',
    accountUserId: userId,
    codec: CacheCodecs.searchPage,
    policy: MusicCachePolicies.publicPlaylist,
    mode: mode,
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
    required CachePolicy policy,
    required CacheLoadMode mode,
    required Future<T> Function() remote,
  }) async* {
    final generation = _session?.generation;
    bool isCurrent() =>
        _session == null ||
        (_session.isCurrent(generation!) &&
            (accountUserId == null || _session.userId == accountUserId));
    if (!isCurrent()) throw const StaleSessionException();
    T? cached;
    DateTime? updatedAt;
    try {
      final row = await _database.readCachedResponse(key);
      if (row != null) {
        if (row.codecVersion == codec.version) {
          try {
            cached = codec.decode(row.payload);
            updatedAt = row.updatedAt;
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

    if (!isCurrent()) return;
    if (cached != null) yield cached;

    final now = _now();
    if (cached != null &&
        mode == CacheLoadMode.normal &&
        updatedAt != null &&
        policy.isFresh(updatedAt, now)) {
      return;
    }

    final lastRequest = _lastRemoteRequestAt[key];
    if (cached != null &&
        lastRequest != null &&
        now.difference(lastRequest) < policy.minimumRequestGap) {
      return;
    }

    try {
      final fresh = await _coalesced('$generation/$key', () {
        _lastRemoteRequestAt[key] = _now();
        if (_lastRemoteRequestAt.length > 500) {
          _lastRemoteRequestAt.remove(_lastRemoteRequestAt.keys.first);
        }
        return remote();
      });
      if (!isCurrent()) return;
      try {
        await _database.transaction(() async {
          if (!isCurrent()) return;
          await _database.writeCachedResponse(
            cacheKey: key,
            accountUserId: accountUserId,
            codecVersion: codec.version,
            payload: codec.encode(fresh),
            updatedAt: _now(),
          );
        });
      } catch (_) {
        // The network result remains useful even when local persistence fails.
      }
      if (isCurrent()) yield fresh;
    } on MusicSdkException catch (error) {
      if (cached != null && error.retryable) return;
      rethrow;
    }
  }

  Future<T> _coalesced<T>(String key, Future<T> Function() load) {
    final existing = _inFlight[key];
    if (existing != null) return existing.then((value) => value as T);

    late final Future<T> tracked;
    tracked = Future<T>.sync(load).whenComplete(() {
      if (identical(_inFlight[key], tracked)) _inFlight.remove(key);
    });
    _inFlight[key] = tracked;
    return tracked;
  }

  String _scope(int? userId) =>
      '$_keyVersion/${userId == null ? 'guest' : 'user/$userId'}';

  String _queryHash(String value) =>
      sha256.convert(utf8.encode(value.trim().toLowerCase())).toString();
}
