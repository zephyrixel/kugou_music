/// Library + cloud playlist entity (single domain type).
class Playlist {
  const Playlist({
    required this.name,
    required this.isPrivate,
    required this.isMyFavorite,
    required this.isDefaultCollect,
    this.localId,
    this.listId,
    this.globalCollectionId,
    this.intro,
    this.artworkUrl,
    this.count = 0,
    this.listType,
    this.creatorUserId,
    this.creatorName,
    this.tracksLoaded = false,
    this.tags,
  });

  /// Drift primary key when persisted. Null for pure-remote snapshots mid-map.
  final String? localId;
  final int? listId;
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

  Playlist copyWith({
    String? localId,
    int? listId,
    String? globalCollectionId,
    String? name,
    String? intro,
    String? artworkUrl,
    int? count,
    int? listType,
    int? creatorUserId,
    String? creatorName,
    bool? isPrivate,
    bool? isMyFavorite,
    bool? isDefaultCollect,
    bool? tracksLoaded,
    String? tags,
  }) => Playlist(
    localId: localId ?? this.localId,
    listId: listId ?? this.listId,
    globalCollectionId: globalCollectionId ?? this.globalCollectionId,
    name: name ?? this.name,
    intro: intro ?? this.intro,
    artworkUrl: artworkUrl ?? this.artworkUrl,
    count: count ?? this.count,
    listType: listType ?? this.listType,
    creatorUserId: creatorUserId ?? this.creatorUserId,
    creatorName: creatorName ?? this.creatorName,
    isPrivate: isPrivate ?? this.isPrivate,
    isMyFavorite: isMyFavorite ?? this.isMyFavorite,
    isDefaultCollect: isDefaultCollect ?? this.isDefaultCollect,
    tracksLoaded: tracksLoaded ?? this.tracksLoaded,
    tags: tags ?? this.tags,
  );

  /// Stable local id for a remote-owned list.
  static String localIdForRemote(int listId) => 'remote:$listId';

  /// Stable local id for a collected public list before/after listId attach.
  static String localIdForCollected(String globalCollectionId) =>
      'collected:$globalCollectionId';

  static String localIdForNewLocal() =>
      'local:${DateTime.now().microsecondsSinceEpoch}';
}

class PlaylistPage {
  const PlaylistPage({
    required this.items,
    required this.page,
    required this.pageSize,
    this.total,
    this.totalVersion,
  });

  final List<Playlist> items;
  final int page;
  final int pageSize;
  final int? total;
  final int? totalVersion;
}

class PlaylistSearchHit {
  const PlaylistSearchHit({
    required this.name,
    this.specialId,
    this.globalCollectionId,
    this.intro,
    this.artworkUrl,
    this.songCount,
    this.playCount,
    this.collectCount,
    this.creatorName,
    this.creatorUserId,
    this.tags,
  });

  final int? specialId;
  final String? globalCollectionId;
  final String name;
  final String? intro;
  final String? artworkUrl;
  final int? songCount;
  final int? playCount;
  final int? collectCount;
  final String? creatorName;
  final int? creatorUserId;
  final String? tags;
}

class PlaylistSearchPage {
  const PlaylistSearchPage({
    required this.items,
    required this.page,
    required this.pageSize,
    this.total,
  });
  final List<PlaylistSearchHit> items;
  final int page;
  final int pageSize;
  final int? total;
}

class PlaylistEditInput {
  const PlaylistEditInput({
    required this.listId,
    this.name,
    this.private,
    this.intro,
    this.tags,
    this.totalVersion,
  });
  final int listId;
  final String? name;
  final bool? private;
  final String? intro;
  final String? tags;
  final int? totalVersion;
}
