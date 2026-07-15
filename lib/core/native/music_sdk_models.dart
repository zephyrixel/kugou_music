class PlaylistMutation {
  const PlaylistMutation({required this.listId, this.globalCollectionId});

  final int listId;
  final String? globalCollectionId;
}

class PlaylistTracksMutation {
  const PlaylistTracksMutation({required this.fileIds});

  final List<int> fileIds;
}
