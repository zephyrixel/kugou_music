part of 'music_audio_handler.dart';

extension _MusicAudioTransitionRuntime on MusicAudioHandler {
  Future<void> _requestPlayback({
    required PlaybackQueueRequest request,
    required int index,
    Duration? initialPosition,
    bool autoPlay = true,
    bool recordHistory = true,
  }) async {
    if (_disposed || index < 0 || index >= request.songs.length) return;
    final generation = ++_loadGeneration;
    final queueIdentity = identical(request, _queueRequest)
        ? _queueController.identity
        : null;
    final song = request.songs[index];
    final requestedQuality = _preferredQuality;
    final previousQuality = _qualityState;
    _messages.add(null);
    _emitQualityState(
      PlaybackQualityState(requested: requestedQuality, switching: true),
    );
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        _PreparedPlayback? prepared;
        try {
          prepared = await _preparePlayback(
            song,
            requestedQuality,
            initialPosition: initialPosition,
          );
          if (!_isCurrentRequest(generation)) return;
          await _commitPlayback(
            prepared,
            request: request,
            index: index,
            generation: generation,
            queueIdentity: queueIdentity,
            autoPlay: autoPlay,
            recordHistory: recordHistory,
          );
          return;
        } on MusicSdkException catch (error) {
          if (!_isCurrentRequest(generation)) return;
          if (attempt == 0 && error.code == 20028) {
            await _sdk.registerDevice();
            if (!_isCurrentRequest(generation)) return;
            continue;
          }
          rethrow;
        } finally {
          if (prepared != null &&
              !identical(prepared.audioHandle, _currentAudioHandle)) {
            prepared.audioHandle.release();
          }
        }
      }
    } catch (error) {
      if (!_isCurrentRequest(generation)) return;
      _failPlayback(requestedQuality, error);
      rethrow;
    } finally {
      if (_isCurrentRequest(generation) && _qualityState.switching) {
        _emitQualityState(previousQuality);
      }
    }
  }

  Future<_PreparedPlayback> _preparePlayback(
    Song song,
    AudioQuality requestedQuality, {
    Duration? initialPosition,
  }) async {
    var resolution = await _sdk.resolve(song, quality: requestedQuality);
    if (resolution is DeniedResolution || resolution is UnavailableResolution) {
      resolution = await _sdk.resolve(
        song,
        quality: requestedQuality,
        freePreview: true,
      );
    }
    if (resolution is! PlayableResolution) {
      throw const _PlaybackUnavailableException();
    }
    final previewEnd =
        resolution is PreviewResolution && resolution.endMs != null
        ? Duration(milliseconds: resolution.endMs!)
        : null;
    final resolvedSong = _applyResolvedArtwork(song, resolution);
    var resumePosition = initialPosition;
    if (resumePosition != null &&
        previewEnd != null &&
        resumePosition >= previewEnd) {
      resumePosition = Duration.zero;
    }
    final audioHandle = await _audioCache.sourceFor(resolvedSong, resolution);
    return _PreparedPlayback(
      song: resolvedSong,
      resolution: resolution,
      audioHandle: audioHandle,
      initialPosition: resumePosition,
      previewEnd: previewEnd,
      requestedQuality: requestedQuality,
    );
  }

  Future<void> _commitPlayback(
    _PreparedPlayback prepared, {
    required PlaybackQueueRequest request,
    required int index,
    required int generation,
    required Object? queueIdentity,
    required bool autoPlay,
    required bool recordHistory,
  }) {
    late final Future<void> next;
    next = _commitTail.catchError((_) {}).then((_) async {
      if (!_isCurrentRequest(generation)) return;
      if (queueIdentity != null &&
          (!identical(queueIdentity, _queueController.identity) ||
              !_songs.any((song) => song.id == prepared.song.id))) {
        return;
      }
      final previousAudioHandle = _currentAudioHandle;
      final previousPosition = _player.position;
      final previousPlaying = _player.playing;
      Duration? actualDuration;
      try {
        actualDuration = await _player.setAudioSource(
          prepared.audioHandle.source,
          initialPosition: prepared.initialPosition,
        );
      } catch (_) {
        if (_isCurrentRequest(generation) && previousAudioHandle != null) {
          try {
            await _player.setAudioSource(
              previousAudioHandle.source,
              initialPosition: previousPosition,
            );
            if (_isCurrentRequest(generation) && previousPlaying) {
              _startPlayer();
            }
          } catch (error) {
            AppLog.warn('恢复上一音源失败', target: 'player.engine', error: error);
          }
        }
        rethrow;
      }
      if (!_isCurrentRequest(generation)) {
        await _player.stop();
        return;
      }
      if (recordHistory) await _finishRecommendationSession();
      if (!_isCurrentRequest(generation)) {
        await _player.stop();
        return;
      }
      if (queueIdentity != null &&
          (!identical(queueIdentity, _queueController.identity) ||
              !_songs.any((song) => song.id == prepared.song.id))) {
        await _player.stop();
        return;
      }
      _audioCache.setActive(prepared.audioHandle);
      _currentAudioHandle = prepared.audioHandle;
      previousAudioHandle?.release();
      _currentMediaDuration = actualDuration;
      _recommendationPlayTracker.activate(
        prepared.song,
        sourceBits: request.origin.profileSourceBits,
        newPlayback: recordHistory,
      );
      _restoredPosition = null;
      _previewEnd = prepared.previewEnd;
      _previewStopped = false;
      if (queueIdentity == null) {
        _prefetchAttemptedSongId = null;
        _loadingMore = false;
        final songs = [...request.songs];
        songs[index] = prepared.song;
        _queueController.replace(request.copyWith(songs: songs), index);
      } else {
        _queueController.selectSong(prepared.song);
      }
      _publishMediaQueue();
      mediaItem.add(
        _toMediaItem(prepared.song, actualDuration: _currentMediaDuration),
      );
      _emitQueueState(clearError: queueIdentity == null);
      _publishSystemPlaybackState();
      unawaited(_cacheArtwork(prepared.song, generation));
      _emitQualityState(
        PlaybackQualityState(
          requested: prepared.requestedQuality,
          actual: prepared.resolution is PreviewResolution
              ? AudioQuality.standard
              : prepared.resolution.quality,
          bitRate: prepared.resolution.bitRate,
          preview: prepared.resolution is PreviewResolution,
        ),
      );
      unawaited(_persistQueue());
      if (recordHistory && _isCurrentRequest(generation)) {
        try {
          await _recordPlayed(prepared.song);
        } catch (error) {
          AppLog.warn('记录播放历史失败', target: 'player.history', error: error);
        }
      }
      if (!_isCurrentRequest(generation)) return;
      if (autoPlay) {
        _startPlayer();
      } else {
        await _player.pause();
      }
      _maybePrefetchQueue();
    });
    _commitTail = next;
    return next;
  }

  void _failPlayback(AudioQuality requestedQuality, Object error) {
    AppLog.error(
      '播放切换失败 quality=${requestedQuality.name}',
      target: 'player.transition',
      error: error,
    );
    _emitQualityState(PlaybackQualityState(requested: requestedQuality));
    _messages.add('暂时无法播放这首歌曲，请稍后重试');
  }

  void _emitQualityState(PlaybackQualityState state) {
    if (_disposed) return;
    _qualityState = state;
    _qualityStates.add(state);
  }

  Future<void> _cacheArtwork(Song song, int generation) async {
    const prefetchSize = 720;
    final artworkUrl = normalizeArtworkUrl(song.artworkUrl, size: prefetchSize);
    if (artworkUrl == null) return;
    try {
      final file = await ArtworkCacheService.instance.getFile(
        url: artworkUrl,
        cacheId: 'song:${song.id}',
        pixelSize: prefetchSize,
      );
      if (!_isCurrentRequest(generation) ||
          _index < 0 ||
          _index >= _songs.length ||
          _songs[_index].id != song.id) {
        return;
      }
      mediaItem.add(
        _toMediaItem(
          song,
          actualDuration: _currentMediaDuration,
          artworkUri: Uri.file(file.path),
        ),
      );
    } catch (_) {
      // The remote artwork URI remains usable when local prefetch fails.
    }
  }

  Song _applyResolvedArtwork(Song song, PlayableResolution resolution) {
    final artworkUrl = resolution.artworkUrl?.trim();
    final normalizedArtworkUrl = normalizeArtworkUrl(artworkUrl);
    if (normalizedArtworkUrl == null ||
        normalizedArtworkUrl == normalizeArtworkUrl(song.artworkUrl)) {
      return song;
    }
    return song.copyWith(artworkUrl: artworkUrl);
  }

  bool _isCurrentRequest(int generation) =>
      !_disposed &&
      generation == _loadGeneration &&
      (accountSession == null || accountSession!.snapshot.authenticated);

  Future<void> _advanceAfterCompletion() async {
    if (_disposed || _advancing) return;
    _advancing = true;
    try {
      await _finishRecommendationSession();
      if (_order == PlaybackOrder.repeatOne) {
        if (_index >= 0 && _index < _songs.length) {
          _recommendationPlayTracker.activate(
            _songs[_index],
            sourceBits: _queueRequest?.origin.profileSourceBits ?? 0,
          );
        }
        await seek(Duration.zero);
        await play();
        return;
      }
      if (_order == PlaybackOrder.shuffle) {
        while (_queueController.hasShuffleCandidates ||
            _queueRequest?.hasMore == true) {
          try {
            await _skipToNextInternal();
            return;
          } on _PlaybackUnavailableException {
            _messages.add('已跳过一首暂时无法播放的歌曲');
          }
        }
        return;
      }

      var candidate = _index + 1;
      var wrapped = false;
      while (true) {
        if (candidate >= _songs.length && _queueRequest?.hasMore == true) {
          await loadMoreQueue();
        }
        if (candidate >= _songs.length) {
          if (_order == PlaybackOrder.repeatAll &&
              !wrapped &&
              _songs.isNotEmpty) {
            candidate = 0;
            wrapped = true;
          } else {
            await _player.pause();
            await _player.seek(Duration.zero);
            return;
          }
        }
        if (candidate == _index && wrapped) return;
        final request = _queueRequest;
        if (request == null) return;
        try {
          await _requestPlayback(
            request: request,
            index: candidate,
            initialPosition: Duration.zero,
            autoPlay: true,
            recordHistory: true,
          );
          return;
        } on _PlaybackUnavailableException {
          _messages.add('${request.songs[candidate].title} 暂时无法播放，已跳过');
          candidate += 1;
        }
      }
    } catch (error) {
      AppLog.error('自动切换下一首失败', target: 'player.transition', error: error);
      if (!_disposed) _messages.add('暂时无法切换到下一首，请稍后重试');
    } finally {
      _advancing = false;
    }
  }

  void _enforcePreviewEnd(Duration position) {
    final end = _previewEnd;
    if (_disposed || end == null || _previewStopped || position < end) return;
    _previewStopped = true;
    unawaited(_player.pause());
    _messages.add('试听片段已结束');
  }
}

class _PreparedPlayback {
  const _PreparedPlayback({
    required this.song,
    required this.resolution,
    required this.audioHandle,
    required this.initialPosition,
    required this.previewEnd,
    required this.requestedQuality,
  });

  final Song song;
  final PlayableResolution resolution;
  final CachedAudioHandle audioHandle;
  final Duration? initialPosition;
  final Duration? previewEnd;
  final AudioQuality requestedQuality;
}

class _PlaybackUnavailableException extends MusicSdkException {
  const _PlaybackUnavailableException() : super('当前歌曲暂时无法播放');
}
