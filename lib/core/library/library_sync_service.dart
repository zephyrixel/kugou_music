import 'dart:async';
import 'dart:convert';

import 'package:kgmusic/core/library/library_models.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/models/cloud_playlist.dart';
import 'package:kgmusic/core/models/pagination.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/native/music_sdk_models.dart';

part 'library_sync_pull.dart';
part 'library_sync_push.dart';

class LibrarySyncService {
  LibrarySyncService(this._sdk, this._store);

  static const _pageSize = 100;
  static const _historyLimit = 100;
  static const _retryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 10),
  ];

  final MusicSdk _sdk;
  final LibraryStore _store;
  final StreamController<LibrarySyncStatus> _statuses =
      StreamController.broadcast(sync: true);
  LibrarySyncStatus _status = const LibrarySyncStatus.idle();
  Future<void>? _running;
  _SyncContext? _runningContext;
  _SyncContext? _context;
  Timer? _retryTimer;
  int _generation = 0;
  bool _disposed = false;

  Stream<LibrarySyncStatus> get statuses async* {
    yield _status;
    yield* _statuses.stream;
  }

  LibrarySyncStatus get status => _status;

  Future<void> activate(int userId) async {
    final context = _SyncContext(++_generation, userId);
    _context = context;
    _retryTimer?.cancel();

    final state = await _store.syncState;
    if (!_isCurrent(context)) return;
    if (state != null && state.userId != userId) {
      await _store.clearLibrary();
      if (!_isCurrent(context)) return;
    }
    if (state?.userId != userId || state?.baselineComplete != true) {
      await _track(context, () => _buildBaseline(context));
      return;
    }
    unawaited(sync(pullRemote: true));
  }

  Future<void> deactivate() async {
    final generation = ++_generation;
    _context = null;
    _retryTimer?.cancel();
    await _store.clearLibrary();
    if (!_disposed && generation == _generation && _context == null) {
      _emit(const LibrarySyncStatus.idle());
    }
  }

  void trigger() {
    if (_context == null || _disposed) return;
    unawaited(sync());
  }

  Future<void> sync({bool pullRemote = false, bool force = false}) {
    final context = _context;
    if (context == null || _disposed) return Future.value();
    return _track(
      context,
      () => _runSync(context, pullRemote: pullRemote, force: force),
    );
  }

  Future<void> ensurePlaylistLoaded(String localId, {bool force = false}) =>
      _ensurePlaylistLoaded(localId, force: force);

  Future<void> _track(_SyncContext context, Future<void> Function() action) {
    final current = _running;
    if (current != null && identical(_runningContext, context)) return current;

    late final Future<void> tracked;
    tracked = Future.sync(action).whenComplete(() {
      if (identical(_running, tracked)) {
        _running = null;
        _runningContext = null;
      }
    });
    _running = tracked;
    _runningContext = context;
    return tracked;
  }

  Future<void> _runSync(
    _SyncContext context, {
    required bool pullRemote,
    required bool force,
  }) async {
    if (!_isCurrent(context)) return;
    _retryTimer?.cancel();
    if (force) {
      await _store.retryNow();
      if (!_isCurrent(context)) return;
    }
    final pendingBeforePush = await _store.pendingCount();
    if (!_isCurrent(context)) return;
    _emitFor(
      context,
      LibrarySyncStatus(
        phase: LibrarySyncPhase.syncing,
        pendingCount: pendingBeforePush,
      ),
    );

    String? error;
    try {
      await _pushReadyOperations(context);
      if (!_isCurrent(context)) return;
      final pending = await _store.pendingCount();
      if (!_isCurrent(context)) return;
      if (pullRemote && pendingBeforePush == 0 && pending == 0) {
        await _pullRemote(context, baseline: false);
      }
    } catch (value) {
      if (!_isCurrent(context)) return;
      error = value.toString();
    }

    if (!_isCurrent(context)) return;
    final pending = await _store.pendingCount();
    if (!_isCurrent(context)) return;
    await _store.setSyncResult(userId: context.userId, error: error);
    if (!_isCurrent(context)) return;
    _emitFor(
      context,
      LibrarySyncStatus(
        phase: error == null ? LibrarySyncPhase.idle : LibrarySyncPhase.failed,
        pendingCount: pending,
        lastSyncedAt: error == null ? DateTime.now() : null,
        message: error,
      ),
    );
    if (pending > 0) {
      final ready = await _store.readyOperations(limit: 1);
      if (!_isCurrent(context)) return;
      if (ready.isNotEmpty) {
        _retryTimer = Timer(Duration.zero, () {
          if (_isCurrent(context)) trigger();
        });
        return;
      }
    }
    await _scheduleRetry(context);
  }

  Future<void> _scheduleRetry(_SyncContext context) async {
    if (!_isCurrent(context)) return;
    _retryTimer?.cancel();
    final next = await _store.nextRetryAt();
    if (!_isCurrent(context) || next == null) return;
    final delay = next.difference(DateTime.now());
    _retryTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (_isCurrent(context)) trigger();
    });
  }

  bool _isCurrent(_SyncContext context) =>
      !_disposed &&
      _context?.generation == context.generation &&
      _context?.userId == context.userId;

  void _emitFor(_SyncContext context, LibrarySyncStatus value) {
    if (_isCurrent(context)) _emit(value);
  }

  void _emit(LibrarySyncStatus value) {
    if (_disposed) return;
    _status = value;
    _statuses.add(value);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation += 1;
    _context = null;
    _retryTimer?.cancel();
    await _statuses.close();
  }
}

class _SyncContext {
  const _SyncContext(this.generation, this.userId);

  final int generation;
  final int userId;
}
