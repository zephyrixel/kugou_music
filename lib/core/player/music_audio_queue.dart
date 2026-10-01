part of 'music_audio_handler.dart';

extension MusicAudioQueueCommands on MusicAudioHandler {
  void _maybePrefetchQueue() {
    _prefetchTimer?.cancel();
    if (_disposed || _queueState?.error != null) return;
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

  void _emitQueueState({Object? error, bool clearError = false}) {
    final request = _queueRequest;
    if (_disposed) return;
    if (request == null) {
      _queueState = null;
      _queueStates.add(null);
      queueTitle.add('');
      return;
    }
    final state = PlaybackQueueState(
      origin: request.origin,
      songs: _songs,
      currentIndex: _index,
      order: _order,
      hasMore: request.hasMore,
      loadingMore: _loadingMore,
      error: clearError ? null : error ?? _queueState?.error,
    );
    _queueState = state;
    _queueStates.add(state);
    queueTitle.add(request.origin.displayTitle);
  }

  Future<void> loadMoreQueue() async {
    if (_disposed) return;
    final identity = _queueController.identity;
    final current = _loadMoreOperation;
    if (current != null && identical(_loadMoreIdentity, identity)) {
      return current;
    }
    _loadMoreIdentity = identity;
    final request = _queueRequest;
    final source = request?.source;
    if (request == null || source == null || !request.hasMore) {
      return;
    }
    late final Future<void> tracked;
    tracked =
        () async {
          _loadingMore = true;
          _emitQueueState(clearError: true);
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
            if (_disposed ||
                activeRequest == null ||
                !activeRequest.hasMore ||
                !identical(_queueController.identity, identity)) {
              return;
            }
            final known = _songs.map((item) => item.id).toSet();
            final appended = page.songs
                .where((item) => known.add(item.id))
                .toList();
            final hasMore =
                appended.isNotEmpty &&
                canLoadNextPage(
                  loadedItemCount: 0,
                  lastPageItemCount: page.songs.length,
                  pageSize: page.pageSize,
                  page: page.page,
                  total: page.total,
                  hasMore: page.hasMore,
                );
            _queueController.append(appended);
            _queueController.updatePagination(
              nextPage: page.page + 1,
              hasMore: hasMore,
              total: page.total,
            );
            _publishMediaQueue();
            _emitQueueState();
            unawaited(_persistQueue());
          } catch (error) {
            if (_disposed || !identical(identity, _queueController.identity)) {
              return;
            }
            loadError = error;
            AppLog.warn('播放队列加载更多失败', target: 'player.queue', error: error);
            rethrow;
          } finally {
            if (!_disposed && identical(identity, _queueController.identity)) {
              _loadingMore = false;
              _emitQueueState(error: loadError);
            }
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
    if (_disposed) return;
    _queueController.setOrder(order);
    _emitQueueState();
    _publishSystemPlaybackState();
    unawaited(_persistQueue());
  }

  Future<void> _removeQueueItemAt(int index) async {
    if (_disposed) return;
    if (!_queueController.removeAt(index)) return;
    _publishMediaQueue();
    _emitQueueState();
    _publishSystemPlaybackState();
    unawaited(_persistQueue());
  }

  Future<void> clearUpcoming() async {
    if (_disposed) return;
    if (!_queueController.clearUpcoming()) return;
    _publishMediaQueue();
    _emitQueueState();
    _publishSystemPlaybackState();
    unawaited(_persistQueue());
  }

  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (_disposed) return;
    if (!_queueController.move(oldIndex, newIndex)) return;
    _publishMediaQueue();
    _emitQueueState();
    _publishSystemPlaybackState();
    unawaited(_persistQueue());
  }

  Future<int?> _accountUserId() => accountSession != null
      ? Future.value(accountSession!.userId)
      : _sdk.authState().then(
          (snapshot) => snapshot.authenticated ? snapshot.userId : null,
        );

  Future<void> _persistQueue() {
    final store = queueStore;
    final request = _queueRequest;
    if (store == null || request == null) return Future<void>.value();
    final generation = accountSession?.generation;
    final accountId = _accountUserId();
    final snapshot = PlaybackQueueSnapshot(
      request: request,
      currentIndex: _index,
      order: _order,
      positionMs: _player.position.inMilliseconds,
    );
    late final Future<void> next;
    next = _persistTail.catchError((_) {}).then((_) async {
      final userId = await accountId;
      if (accountSession != null && !accountSession!.isCurrent(generation!)) {
        return;
      }
      if (userId != null) await store.write(userId, snapshot);
    });
    _persistTail = next;
    return next.catchError((Object error) {
      AppLog.warn('保存播放队列失败', target: 'player.queue', error: error);
    });
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
    _queueController.replace(
      snapshot.request.copyWith(
        source: restoredSource,
        hasMore: restoredSource != null && snapshot.request.hasMore,
      ),
      snapshot.currentIndex,
    );
    _queueController.setOrder(snapshot.order);
    _restoredPosition = Duration(milliseconds: snapshot.positionMs);
    _currentMediaDuration = null;
    _publishMediaQueue();
    if (_index >= 0) mediaItem.add(_toMediaItem(_songs[_index]));
    _emitQueueState();
    _publishSystemPlaybackState();
  }

  Future<void> clearQueue() async {
    if (_disposed) return;
    _loadGeneration += 1;
    _prefetchTimer?.cancel();
    _prefetchAttemptedSongId = null;
    await _persistTail.catchError((_) {});
    await _player.stop();
    _audioCache.setActive(null);
    await _finishRecommendationSession();
    _currentAudioHandle?.release();
    _currentAudioHandle = null;
    _queueController.clear();
    _loadingMore = false;
    _previewEnd = null;
    _previewStopped = false;
    _emitQueueState();
    _restoredPosition = null;
    _currentMediaDuration = null;
    queue.add(const []);
    queueTitle.add('');
    mediaItem.add(null);
    _publishSystemPlaybackState();
  }
}
