import 'dart:async';

import 'package:kgmusic/core/library/library_remote.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';

/// Local-first page cache for owned playlist tracks.
class PlaylistTrackLoader {
  PlaylistTrackLoader(this._store, this._remote, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const freshFor = Duration(minutes: 15);

  final LibraryStore _store;
  final LibraryRemote _remote;
  final DateTime Function() _now;
  final Map<String, Future<SearchPage>> _pageLoads = {};
  final Map<String, Future<void>> _fullLoads = {};
  int _generation = 0;

  Stream<SearchPage> page(
    String localId, {
    required int page,
    required int pageSize,
    required bool forceRefresh,
    required bool Function() isCurrent,
  }) async* {
    final playlist = await _store.playlist(localId);
    if (!isCurrent() || playlist == null) return;

    final local = await _store.playlistTracksPage(
      localId,
      page: page,
      pageSize: pageSize,
    );
    if (!isCurrent()) return;
    final localPage = SearchPage(
      songs: local,
      page: page,
      pageSize: pageSize,
      total: playlist.count,
    );
    if (playlist.count == 0 && !forceRefresh) {
      yield localPage;
      return;
    }
    if (local.isNotEmpty && !forceRefresh) yield localPage;

    final start = (page - 1) * pageSize;
    final localCoversPage =
        local.length == pageSize ||
        (playlist.count <= start + local.length && local.isNotEmpty);
    final updatedAt = playlist.tracksUpdatedAt;
    final cacheFresh =
        updatedAt != null && _now().difference(updatedAt) < freshFor;
    if (!forceRefresh && localCoversPage && cacheFresh) return;

    try {
      final remote = await _coalescedPage(
        '$localId/$page/$pageSize',
        () => _remote.fetchTracksPage(playlist, page: page, pageSize: pageSize),
      );
      if (!isCurrent()) return;
      await _store.replacePlaylistTrackPage(
        localId,
        remote.songs,
        startPosition: start,
        pageSize: pageSize,
        totalCount: remote.total,
      );
      if (!isCurrent()) return;
      final hasMore = canLoadNextPage(
        loadedItemCount: start + remote.songs.length,
        lastPageItemCount: remote.songs.length,
        pageSize: remote.pageSize,
        total: remote.total,
      );
      if (!hasMore) {
        await _store.finishPlaylistSnapshot(
          localId,
          totalCount: remote.total ?? start + remote.songs.length,
        );
      }
      yield remote;
    } on MusicSdkException catch (error) {
      if (local.isNotEmpty && error.retryable) return;
      rethrow;
    }
  }

  Future<void> refreshAll(
    String localId, {
    required bool Function() isCurrent,
    bool Function()? canCommit,
  }) async {
    final existing = _fullLoads[localId];
    if (existing != null) return existing;
    final generation = _generation;

    late final Future<void> tracked;
    tracked = () async {
      final playlist = await _store.playlist(localId);
      if (playlist == null || !isCurrent() || generation != _generation) return;

      final songs = <Song>[];
      final known = <String>{};
      var page = 1;
      var total = playlist.count;
      while (isCurrent() && generation == _generation) {
        final response = await _coalescedPage(
          '$localId/$page/${LibraryRemote.pageSize}',
          () => _remote.fetchTracksPage(
            playlist,
            page: page,
            pageSize: LibraryRemote.pageSize,
          ),
        );
        if (!isCurrent() || generation != _generation) return;
        total = response.total ?? total;
        for (final song in response.songs) {
          if (known.add(song.id)) songs.add(song);
        }
        if (!canLoadNextPage(
          loadedItemCount: songs.length,
          lastPageItemCount: response.songs.length,
          pageSize: response.pageSize,
          total: response.total,
        )) {
          break;
        }
        page += 1;
      }
      if (!isCurrent() ||
          generation != _generation ||
          canCommit?.call() == false) {
        return;
      }
      await _store.replacePlaylistTracksAtomic(
        localId,
        songs,
        totalCount: total,
      );
    }();
    _fullLoads[localId] = tracked;
    try {
      await tracked;
    } finally {
      if (identical(_fullLoads[localId], tracked)) {
        _fullLoads.remove(localId);
      }
    }
  }

  Future<SearchPage> _coalescedPage(
    String key,
    Future<SearchPage> Function() load,
  ) {
    final existing = _pageLoads[key];
    if (existing != null) return existing;
    late final Future<SearchPage> tracked;
    tracked = load().whenComplete(() {
      if (identical(_pageLoads[key], tracked)) _pageLoads.remove(key);
    });
    _pageLoads[key] = tracked;
    return tracked;
  }

  void cancelAll() {
    _generation += 1;
    _pageLoads.clear();
    _fullLoads.clear();
  }
}
