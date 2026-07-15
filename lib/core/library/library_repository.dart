import 'dart:async';

import 'package:kgmusic/core/library/library_models.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/library/library_sync_service.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/core/models/song.dart';

class LibraryRepository {
  LibraryRepository(this._store, this._sync);

  final LibraryStore _store;
  final LibrarySyncService _sync;
  bool _active = false;

  Stream<List<LibraryPlaylist>> watchPlaylists() => _store.watchPlaylists();
  Stream<List<Song>> watchFavorites() => _store.watchFavoriteSongs();
  Stream<List<LibraryHistoryEntry>> watchHistory() => _store.watchHistory();
  Stream<List<Song>> watchPlaylistTracks(String localId) =>
      _store.watchPlaylistTracks(localId);
  Stream<LibrarySyncStatus> get syncStatuses => _sync.statuses;

  Future<void> activate(int userId) async {
    _active = false;
    await _sync.activate(userId);
    _active = true;
  }

  Future<void> deactivate() async {
    _active = false;
    await _sync.deactivate();
  }

  Future<void> toggleFavorite(Song song) async {
    if (await _store.toggleFavorite(song)) _sync.trigger();
  }

  Future<void> recordPlayed(Song song) async {
    if (!_active) return;
    await _store.recordPlayed(song);
    _sync.trigger();
  }

  Future<String> createPlaylist(String name, {required bool private}) async {
    final localId = await _store.createPlaylist(name, private: private);
    _sync.trigger();
    return localId;
  }

  Future<String> collectPlaylist(PlaylistSearchHit playlist) async {
    if (playlist.globalCollectionId == null) {
      throw ArgumentError.value(
        playlist.globalCollectionId,
        'globalCollectionId',
        '收藏歌单缺少全局 ID',
      );
    }
    final localId = await _store.collectPlaylist(
      LibraryPlaylist(
        localId: 'gid:${playlist.globalCollectionId}',
        globalCollectionId: playlist.globalCollectionId,
        name: playlist.name,
        intro: playlist.intro,
        artworkUrl: playlist.artworkUrl,
        count: playlist.songCount ?? 0,
        listType: 1,
        creatorUserId: playlist.creatorUserId,
        creatorName: playlist.creatorName,
        isPrivate: false,
        isMyFavorite: false,
        isDefaultCollect: false,
        tracksLoaded: false,
        tags: playlist.tags,
      ),
    );
    _sync.trigger();
    return localId;
  }

  Future<void> editPlaylist(
    String localId, {
    required String name,
    required String intro,
    required String tags,
    required bool private,
  }) async {
    await _store.editPlaylist(
      localId,
      name: name,
      intro: intro,
      tags: tags,
      private: private,
    );
    _sync.trigger();
  }

  Future<void> deletePlaylist(String localId) async {
    await _store.deletePlaylist(localId);
    _sync.trigger();
  }

  Future<void> addSong(String playlistLocalId, Song song) async {
    if (await _store.setTrackMembership(playlistLocalId, song, present: true)) {
      _sync.trigger();
    }
  }

  Future<void> removeSong(String playlistLocalId, Song song) async {
    if (await _store.setTrackMembership(
      playlistLocalId,
      song,
      present: false,
    )) {
      _sync.trigger();
    }
  }

  Future<void> ensurePlaylistLoaded(String localId, {bool force = false}) =>
      _sync.ensurePlaylistLoaded(localId, force: force);

  Future<void> ensureFavoriteLoaded() => _sync.ensureFavoriteLoaded();

  Future<void> syncNow() => _sync.sync(pullRemote: true, force: true);
}
