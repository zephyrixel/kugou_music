part of 'music_audio_handler.dart';

extension MusicAudioQueueCommands on MusicAudioHandler {
  void _maybePrefetchQueue() {
    _prefetchTimer?.cancel();
    final request = _queueRequest;
    if (request == null || !request.hasMore || request.source == null) return;
    final remaining = _index < 0 ? _songs.length : _songs.length - _index - 1;
    if (remaining == 0) {
      unawaited(loadMoreQueue().catchError((_) {}));
      return;
    }
    if (remaining > 2 || _index < 0 || _index >= _songs.length) return;
    final source = request.source;
    final songId = _songs[_index].id;
    if (_prefetchAttemptedSongId == songId) return;
    _prefetchTimer = Timer(const Duration(seconds: 5), () {
      if (!identical(_queueRequest?.source, source) ||
          _index < 0 ||
          _index >= _songs.length ||
          _songs[_index].id != songId) {
        return;
      }
      _prefetchAttemptedSongId = songId;
      unawaited(loadMoreQueue().catchError((_) {}));
    });
  }

  void _emitQueueState({Object? error}) {
    final request = _queueRequest;
    if (request == null) return;
    final state = PlaybackQueueState(
      origin: request.origin,
      songs: List.unmodifiable(_songs),
      currentIndex: _index,
      order: _order,
      hasMore: request.hasMore,
      loadingMore: _loadingMore,
      error: error,
    );
    _queueState = state;
    _queueStates.add(state);
    queueTitle.add(request.origin.displayTitle);
  }

  Future<void> loadMoreQueue() async {
    final current = _loadMoreOperation;
    if (current != null) return current;
    final request = _queueRequest;
    final source = request?.source;
    if (request == null || source == null || !request.hasMore) {
      return;
    }
    late final Future<void> tracked;
    tracked =
        () async {
          _loadingMore = true;
          _emitQueueState();
          Object? loadError;
          try {
            final page = await source.loadPage(
              PlaybackQueueLoadRequest(
                page: request.nextPage,
                currentIndex: _index,
                songs: _songs,
                position: _player.position,
              ),
            );
            final activeRequest = _queueRequest;
            if (activeRequest == null ||
                !identical(activeRequest.source, source)) {
              return;
            }
            final known = _songs.map((item) => item.id).toSet();
            final appended = page.songs
                .where((item) => known.add(item.id))
                .toList();
            final merged = [..._songs, ...appended];
            final hasMore =
                page.hasMore ??
                (page.total == null
                    ? page.songs.length >= page.pageSize
                    : merged.length < page.total!);
            _queueRequest = activeRequest.copyWith(
              songs: merged,
              nextPage: page.page + 1,
              hasMore: hasMore,
              origin: activeRequest.origin.copyWith(totalCount: page.total),
            );
            _queueController.append(appended);
            _publishMediaQueue();
            _emitQueueState();
            unawaited(_persistQueue());
          } catch (error) {
            loadError = error;
            rethrow;
          } finally {
            _loadingMore = false;
            _emitQueueState(error: loadError);
          }
        }().whenComplete(() {
          if (identical(_loadMoreOperation, tracked)) {
            _loadMoreOperation = null;
            _maybePrefetchQueue();
          }
        });
    _loadMoreOperation = tracked;
    return tracked;
  }

  Future<void> setPlaybackOrder(PlaybackOrder order) async {
    _queueController.setOrder(order);
    _emitQueueState();
    _publishSystemPlaybackState();
    unawaited(_persistQueue());
  }

  Future<void> _removeQueueItemAt(int index) async {
    if (!_queueController.removeAt(index)) return;
    _queueRequest = _queueRequest?.copyWith(songs: _songs);
    _publishMediaQueue();
    _emitQueueState();
    _publishSystemPlaybackState();
    unawaited(_persistQueue());
  }

  Future<void> clearUpcoming() async {
    if (!_queueController.clearUpcoming()) return;
    _queueRequest = _queueRequest?.copyWith(songs: _songs, hasMore: false);
    _publishMediaQueue();
    _emitQueueState();
    _publishSystemPlaybackState();
    unawaited(_persistQueue());
  }

  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (!_queueController.move(oldIndex, newIndex)) return;
    _queueRequest = _queueRequest?.copyWith(songs: _songs);
    _publishMediaQueue();
    _emitQueueState();
    _publishSystemPlaybackState();
    unawaited(_persistQueue());
  }

  Future<int?> _accountUserId() => _sdk.authState().then(
    (snapshot) => snapshot.authenticated ? snapshot.userId : null,
  );

  Future<void> _persistQueue() {
    final store = queueStore;
    final request = _queueRequest;
    if (store == null || request == null) return Future<void>.value();
    final snapshot = PlaybackQueueSnapshot(
      request: request,
      currentIndex: _index,
      order: _order,
      positionMs: _player.position.inMilliseconds,
    );
    late final Future<void> next;
    next = _persistTail.catchError((_) {}).then((_) async {
      final userId = await _accountUserId();
      if (userId != null) await store.write(userId, snapshot);
    });
    _persistTail = next;
    return next;
  }

  Future<void> _restoreQueue() async {
    final store = queueStore;
    if (store == null) return;
    final generation = _loadGeneration;
    final userId = await _accountUserId();
    if (userId == null) return;
    final snapshot = await store.read(userId);
    if (snapshot == null ||
        snapshot.request.songs.isEmpty ||
        generation != _loadGeneration ||
        _queueRequest != null) {
      return;
    }
    final restoredSource = await queueSourceFactory?.restore(
      snapshot.request.origin,
      pageSize: snapshot.request.pageSize,
    );
    if (generation != _loadGeneration || _queueRequest != null) return;
    _queueRequest = snapshot.request.copyWith(
      source: restoredSource,
      hasMore: restoredSource != null && snapshot.request.hasMore,
    );
    _queueController.restore(
      snapshot.request.songs,
      snapshot.currentIndex,
      snapshot.order,
    );
    _restoredPosition = Duration(milliseconds: snapshot.positionMs);
    _currentMediaDuration = null;
    _publishMediaQueue();
    if (_index >= 0) mediaItem.add(_toMediaItem(_songs[_index]));
    _emitQueueState();
    _publishSystemPlaybackState();
  }

  Future<void> clearQueue() async {
    _loadGeneration += 1;
    _prefetchTimer?.cancel();
    _prefetchAttemptedSongId = null;
    await _persistTail.catchError((_) {});
    _audioCache.setActive(null);
    _currentAudioHandle = null;
    _queueRequest = null;
    _queueState = null;
    _queueController.clear();
    _restoredPosition = null;
    _currentMediaDuration = null;
    queue.add(const []);
    queueTitle.add('');
    mediaItem.add(null);
    await _player.stop();
    _publishSystemPlaybackState();
  }
}
