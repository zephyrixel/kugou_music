import 'package:kgmusic/core/library/library_remote.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';

/// Progressively loads one playlist into Drift while coalescing duplicate work.
class PlaylistTrackLoader {
  PlaylistTrackLoader(this._store, this._remote);

  final LibraryStore _store;
  final LibraryRemote _remote;
  final Map<String, Future<void>> _loads = {};
  final Map<String, int> _tokens = {};

  Future<void> ensure(
    String localId, {
    required bool force,
    required bool Function() isCurrent,
  }) async {
    final playlist = await _store.playlist(localId);
    if (!isCurrent() || playlist == null) return;
    if (playlist.tracksLoaded && !force) return;

    final existing = _loads[localId];
    if (existing != null && !force) return existing;

    final token = (_tokens[localId] ?? 0) + 1;
    _tokens[localId] = token;
    bool loadIsCurrent() => isCurrent() && _tokens[localId] == token;

    final tracked = _loadAll(
      localId,
      playlist: playlist,
      isCurrent: loadIsCurrent,
    );
    _loads[localId] = tracked;
    try {
      await tracked;
    } finally {
      if (identical(_loads[localId], tracked)) _loads.remove(localId);
    }
  }

  Future<void> _loadAll(
    String localId, {
    required Playlist playlist,
    required bool Function() isCurrent,
  }) async {
    await _store.clearPlaylistTracks(localId);
    if (!isCurrent()) return;

    var page = 1;
    var loaded = 0;
    final known = <String>{};

    while (isCurrent()) {
      final response = await _remote.fetchTracksPage(playlist, page: page);
      if (!isCurrent()) return;

      final fresh = <Song>[
        for (final song in response.songs)
          if (known.add(song.id)) song,
      ];
      if (fresh.isNotEmpty || response.total != null) {
        await _store.appendPlaylistTracks(
          localId,
          fresh,
          startPosition: loaded,
          totalCount: response.total,
        );
        loaded += fresh.length;
      }
      if (!isCurrent()) return;

      final hasMore = canLoadNextPage(
        loadedItemCount: loaded,
        lastPageItemCount: response.songs.length,
        pageSize: response.pageSize,
        total: response.total,
      );
      if (!hasMore) {
        await _store.markPlaylistTracksLoaded(localId, count: loaded);
        return;
      }
      page += 1;
    }
  }

  void cancelAll() {
    for (final localId in _tokens.keys.toList()) {
      _tokens[localId] = (_tokens[localId] ?? 0) + 1;
    }
    _loads.clear();
  }
}
