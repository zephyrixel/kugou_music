import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/core/models/song.dart';

class LibraryPlaylist {
  const LibraryPlaylist({
    required this.localId,
    required this.name,
    required this.isPrivate,
    required this.isMyFavorite,
    required this.isDefaultCollect,
    required this.tracksLoaded,
    this.remoteListId,
    this.globalCollectionId,
    this.intro,
    this.artworkUrl,
    this.count = 0,
    this.listType,
    this.creatorUserId,
    this.creatorName,
    this.tags,
  });

  final String localId;
  final int? remoteListId;
  final String? globalCollectionId;
  final String name;
  final String? intro;
  final String? artworkUrl;
  final int count;
  final int? listType;
  final int? creatorUserId;
  final String? creatorName;
  final bool isPrivate;
  final bool isMyFavorite;
  final bool isDefaultCollect;
  final bool tracksLoaded;
  final String? tags;

  bool get isCollected => listType == 1;
  bool get isSystem => isMyFavorite || isDefaultCollect;
  bool get isWritable => !isCollected;

  CloudPlaylist toRemote() => CloudPlaylist(
    listId: remoteListId,
    globalCollectionId: globalCollectionId,
    name: name,
    intro: intro,
    artworkUrl: artworkUrl,
    count: count,
    listType: listType,
    creatorUserId: creatorUserId,
    creatorName: creatorName,
    isPrivate: isPrivate,
    isMyFavorite: isMyFavorite,
    isDefaultCollect: isDefaultCollect,
    tags: tags,
  );
}

class LibraryHistoryEntry {
  const LibraryHistoryEntry({
    required this.song,
    required this.playedAt,
    required this.playCount,
  });

  final Song song;
  final DateTime playedAt;
  final int playCount;
}

enum LibrarySyncPhase { idle, syncing, failed }

class LibrarySyncStatus {
  const LibrarySyncStatus({
    required this.phase,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.message,
  });

  const LibrarySyncStatus.idle()
    : phase = LibrarySyncPhase.idle,
      pendingCount = 0,
      lastSyncedAt = null,
      message = null;

  final LibrarySyncPhase phase;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? message;

  bool get syncing => phase == LibrarySyncPhase.syncing;
  bool get failed => phase == LibrarySyncPhase.failed;
}

class PendingLibraryOperation {
  const PendingLibraryOperation({
    required this.key,
    required this.operation,
    required this.payload,
    required this.revision,
    required this.attempts,
  });

  final String key;
  final String operation;
  final String payload;
  final int revision;
  final int attempts;
}
