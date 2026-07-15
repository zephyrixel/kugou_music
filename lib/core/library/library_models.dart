enum LibrarySyncPhase { idle, syncing, failed }

class LibrarySyncStatus {
  const LibrarySyncStatus({
    required this.phase,
    this.lastSyncedAt,
    this.message,
  });

  const LibrarySyncStatus.idle()
    : phase = LibrarySyncPhase.idle,
      lastSyncedAt = null,
      message = null;

  final LibrarySyncPhase phase;
  final DateTime? lastSyncedAt;
  final String? message;

  bool get syncing => phase == LibrarySyncPhase.syncing;
  bool get failed => phase == LibrarySyncPhase.failed;
}
