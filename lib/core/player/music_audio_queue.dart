part of 'music_audio_handler.dart';

extension MusicAudioQueueCommands on MusicAudioHandler {
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
  }

  Future<void> loadMoreQueue() async {
    final request = _queueRequest;
    final source = request?.source;
    if (request == null || source == null || !request.hasMore || _loadingMore) {
      return;
    }
    _loadingMore = true;
    _emitQueueState();
    Object? loadError;
    try {
      final page = await source.loadPage(request.nextPage);
      final known = _songs.map((item) => item.id).toSet();
      final appended = page.songs.where((item) => known.add(item.id)).toList();
      final merged = [..._songs, ...appended];
      final hasMore = page.total == null
          ? page.songs.length >= page.pageSize
          : merged.length < page.total!;
      _queueRequest = request.copyWith(
        songs: merged,
        nextPage: page.page + 1,
        hasMore: hasMore,
        origin: request.origin.copyWith(totalCount: page.total),
      );
      _songs = List.unmodifiable(merged);
      if (_order == PlaybackOrder.shuffle) {
        _shuffleRemaining.addAll(appended.map((item) => item.id));
      }
      queue.add(_songs.map(_toMediaItem).toList(growable: false));
      _emitQueueState();
      unawaited(_persistQueue());
    } catch (error) {
      loadError = error;
      rethrow;
    } finally {
      _loadingMore = false;
      _emitQueueState(error: loadError);
    }
  }

  Future<void> setPlaybackOrder(PlaybackOrder order) async {
    _order = order;
    if (order == PlaybackOrder.shuffle) {
      _shuffleRemaining
        ..clear()
        ..addAll(
          _songs
              .where((song) => _index < 0 || song.id != _songs[_index].id)
              .map((song) => song.id),
        );
    } else {
      _shuffleRemaining.clear();
    }
    _emitQueueState();
    unawaited(_persistQueue());
  }

  Future<void> _removeQueueItemAt(int index) async {
    if (index < 0 || index >= _songs.length || index == _index) return;
    final updated = [..._songs]..removeAt(index);
    _index = index < _index ? _index - 1 : _index;
    _songs = List.unmodifiable(updated);
    _queueRequest = _queueRequest?.copyWith(songs: _songs);
    _shuffleRemaining.removeWhere(
      (id) => !updated.any((song) => song.id == id),
    );
    queue.add(_songs.map(_toMediaItem).toList(growable: false));
    _emitQueueState();
    unawaited(_persistQueue());
  }

  Future<void> clearUpcoming() async {
    if (_index < 0 || _index + 1 >= _songs.length) return;
    _songs = List.unmodifiable(_songs.take(_index + 1));
    _queueRequest = _queueRequest?.copyWith(songs: _songs, hasMore: false);
    _shuffleRemaining.clear();
    queue.add(_songs.map(_toMediaItem).toList(growable: false));
    _emitQueueState();
    unawaited(_persistQueue());
  }

  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _songs.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, _songs.length - 1);
    if (oldIndex == newIndex) return;
    final currentId = _index >= 0 ? _songs[_index].id : null;
    final updated = [..._songs];
    final song = updated.removeAt(oldIndex);
    updated.insert(newIndex, song);
    _songs = List.unmodifiable(updated);
    _index = currentId == null
        ? -1
        : updated.indexWhere((item) => item.id == currentId);
    _queueRequest = _queueRequest?.copyWith(songs: _songs);
    queue.add(_songs.map(_toMediaItem).toList(growable: false));
    _emitQueueState();
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
    _songs = List.unmodifiable(snapshot.request.songs);
    _index = snapshot.currentIndex.clamp(-1, _songs.length - 1);
    _order = snapshot.order;
    _restoredPosition = Duration(milliseconds: snapshot.positionMs);
    queue.add(_songs.map(_toMediaItem).toList(growable: false));
    if (_index >= 0) mediaItem.add(_toMediaItem(_songs[_index]));
    _emitQueueState();
  }

  Future<void> clearQueue() async {
    _loadGeneration += 1;
    await _persistTail.catchError((_) {});
    _audioCache.setActive(null);
    _currentAudioHandle = null;
    _queueRequest = null;
    _queueState = null;
    _songs = const [];
    _index = -1;
    _shuffleRemaining.clear();
    _restoredPosition = null;
    queue.add(const []);
    mediaItem.add(null);
    await _player.stop();
  }
}
