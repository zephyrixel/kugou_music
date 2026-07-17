enum LibrarySyncPhase { idle, syncing, failed }

class LibrarySyncStatus {
  const LibrarySyncStatus({required this.phase, this.lastSyncedAt});

  const LibrarySyncStatus.idle()
    : phase = LibrarySyncPhase.idle,
      lastSyncedAt = null;

  final LibrarySyncPhase phase;
  final DateTime? lastSyncedAt;

  bool get syncing => phase == LibrarySyncPhase.syncing;
  bool get failed => phase == LibrarySyncPhase.failed;
}
