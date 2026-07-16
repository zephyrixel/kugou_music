import 'package:kgmusic/core/models/history_entry.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/native/music_sdk_models.dart';

/// Thin cloud I/O for the library (pull + mutations). No outbox / retries.
class LibraryRemote {
  LibraryRemote(this._sdk);

  static const pageSize = 100;
  static const historyLimit = 100;

  final LibrarySdk _sdk;

  Future<List<Playlist>> fetchAllPlaylists() async {
    final result = <Playlist>[];
    final known = <String>{};
    var page = 1;
    while (true) {
      final response = await _sdk.cloudPlaylists(
        page: page,
        pageSize: pageSize,
      );
      if (response.items.isEmpty) break;
      for (final item in response.items) {
        final playlist = _withLocalId(item);
        final id = playlist.localId!;
        if (known.add(id)) result.add(playlist);
      }
      if (!canLoadNextPage(
        loadedItemCount: result.length,
        lastPageItemCount: response.items.length,
        pageSize: response.pageSize,
        total: response.total,
      )) {
        break;
      }
      page += 1;
    }
    return result;
  }

  /// Single page of playlist tracks (newest-first when gid path is used).
  Future<SearchPage> fetchTracksPage(
    Playlist playlist, {
    required int page,
    int pageSize = LibraryRemote.pageSize,
  }) => _sdk.playlistTracks(playlist, page: page, pageSize: pageSize);

  /// Cloud history is oldest→newest; walk until limit then return newest-first.
  Future<List<HistoryEntry>> fetchHistory() async {
    final entries = <String, HistoryEntry>{};
    String? cursor;
    while (entries.length < historyLimit) {
      final response = await _sdk.cloudHistory(cursor: cursor);
      for (final item in response.items) {
        final current = entries[item.song.id];
        if (current == null || item.playedAt.isAfter(current.playedAt)) {
          entries[item.song.id] = item;
        }
      }
      final next = response.cursor;
      if (!response.hasMore || next == null || next.isEmpty || next == cursor) {
        break;
      }
      cursor = next;
    }
    final result = entries.values.toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return result.take(historyLimit).toList(growable: false);
  }

  Future<PlaylistMutation> createPlaylist(
    String name, {
    required bool private,
  }) => _sdk.createPlaylist(name, private: private);

  Future<PlaylistMutation> collectPlaylist(PlaylistSearchHit hit) =>
      _sdk.collectPlaylist(hit);

  Future<void> editPlaylist(PlaylistEditInput input) =>
      _sdk.editPlaylist(input);

  Future<void> deletePlaylist({required int listId, required bool collected}) =>
      _sdk.deletePlaylist(listId: listId, collected: collected);

  Future<PlaylistTracksMutation> addSong(int listId, Song song) =>
      _sdk.addSongToPlaylist(listId, song);

  Future<void> removeSong(int listId, int fileId) =>
      _sdk.removeSongFromPlaylist(listId, fileId);

  /// Locate fileId via listid physical order (oldest-first). Delete-only helper.
  Future<int?> findTrackFileId(int listId, Song target) async {
    var page = 1;
    var loaded = 0;
    while (true) {
      final response = await _sdk.playlistTracksByListId(
        listId,
        page: page,
        pageSize: pageSize,
      );
      if (response.songs.isEmpty) return null;
      loaded += response.songs.length;
      final fileId = response.songs
          .where((song) => _sameSong(song, target) && song.fileId != null)
          .map((song) => song.fileId!)
          .firstOrNull;
      if (fileId != null) return fileId;
      if (!canLoadNextPage(
        loadedItemCount: loaded,
        lastPageItemCount: response.songs.length,
        pageSize: response.pageSize,
        total: response.total,
      )) {
        return null;
      }
      page += 1;
    }
  }

  Future<void> uploadHistory(List<HistoryUpload> items) =>
      _sdk.uploadHistory(items);

  static Playlist _withLocalId(Playlist remote) {
    if (remote.listId != null) {
      return remote.copyWith(
        localId: Playlist.localIdForRemote(remote.listId!),
      );
    }
    // Collected cloud rows without listId yet (rare mid-sync edge).
    if (remote.globalCollectionId != null) {
      return remote.copyWith(
        localId: Playlist.localIdForCollected(remote.globalCollectionId!),
      );
    }
    throw StateError('云端歌单缺少 listId 与 globalCollectionId');
  }
}

bool _sameSong(Song left, Song right) {
  if (left.id == right.id) return true;
  if (left.mixSongId != null && left.mixSongId == right.mixSongId) return true;
  final hashes = _songHashes(left);
  return hashes.isNotEmpty &&
      hashes.intersection(_songHashes(right)).isNotEmpty;
}

Set<String> _songHashes(Song song) =>
    [
          song.hashes.standard,
          song.hashes.high,
          song.hashes.flac,
          song.hashes.hiRes,
          song.hashes.superHash,
        ]
        .whereType<String>()
        .map((hash) => hash.trim().toLowerCase())
        .where((hash) => hash.isNotEmpty)
        .toSet();
