part of 'music_audio_handler.dart';

extension _MusicAudioTransitionRuntime on MusicAudioHandler {
  Future<void> _requestPlayback({
    required PlaybackQueueRequest request,
    required int index,
    Duration? initialPosition,
    bool autoPlay = true,
    bool recordHistory = true,
  }) async {
    final generation = ++_loadGeneration;
    if (index < 0 || index >= request.songs.length) return;
    final song = request.songs[index];
    AppLog.info(
      '准备播放 song=${song.id} queueIndex=$index queueSize=${request.songs.length}',
      target: 'player.transition',
    );
    final requestedQuality = _preferredQuality;
    _messages.add(null);
    _emitQualityState(
      PlaybackQualityState(requested: requestedQuality, switching: true),
    );

    try {
      final prepared = await _preparePlayback(
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
        autoPlay: autoPlay,
        recordHistory: recordHistory,
      );
      AppLog.debug(
        '播放切换完成 song=${song.id} generation=$generation',
        target: 'player.transition',
      );
    } on MusicSdkException catch (error) {
      if (!_isCurrentRequest(generation)) return;
      if (error.code == 20028) {
        try {
          await _sdk.registerDevice();
          if (!_isCurrentRequest(generation)) return;
          final prepared = await _preparePlayback(
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
            autoPlay: autoPlay,
            recordHistory: recordHistory,
          );
          return;
        } catch (_) {
          // Keep the original security challenge as the user-facing error.
        }
      }
      _failPlayback(requestedQuality, error);
      rethrow;
    } catch (error) {
      if (!_isCurrentRequest(generation)) return;
      _failPlayback(requestedQuality, error);
      rethrow;
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
    required bool autoPlay,
    required bool recordHistory,
  }) {
    late final Future<void> next;
    next = _commitTail.catchError((_) {}).then((_) async {
      if (!_isCurrentRequest(generation)) return;
      final previousAudioHandle = _currentAudioHandle;
      Duration? actualDuration;
      try {
        actualDuration = await _player.setAudioSource(
          prepared.audioHandle.source,
          initialPosition: prepared.initialPosition,
        );
      } catch (_) {
        _audioCache.setActive(previousAudioHandle);
        rethrow;
      }
      if (!_isCurrentRequest(generation)) {
        await _player.stop();
        return;
      }
      _audioCache.setActive(prepared.audioHandle);
      _currentAudioHandle = prepared.audioHandle;
      _currentMediaDuration = actualDuration;
      final songDuration =
          actualDuration ??
          (prepared.song.durationSecs == null
              ? null
              : Duration(seconds: prepared.song.durationSecs!));
      final recommendationDuration =
          prepared.previewEnd != null &&
              (songDuration == null || prepared.previewEnd! < songDuration)
          ? prepared.previewEnd
          : songDuration;
      _recommendationPlayTracker.activate(
        prepared.song,
        newPlayback: recordHistory,
        duration: recommendationDuration,
      );
      _restoredPosition = null;
      _previewEnd = prepared.previewEnd;
      _previewStopped = false;
      final replacingQueue = !identical(_queueRequest, request);
      if (replacingQueue) _prefetchAttemptedSongId = null;
      final committedQueue = [...request.songs];
      committedQueue[index] = prepared.song;
      _queueRequest = request.copyWith(songs: committedQueue);
      _queueController.commit(
        committedQueue,
        index,
        replacingQueue: replacingQueue,
      );
      _publishMediaQueue();
      mediaItem.add(
        _toMediaItem(prepared.song, actualDuration: _currentMediaDuration),
      );
      _emitQueueState();
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
        await _recordPlayed(prepared.song);
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
    _messages.add(error.toString());
  }

  void _emitQualityState(PlaybackQualityState state) {
    _qualityState = state;
    _qualityStates.add(state);
  }

  Future<void> _cacheArtwork(Song song, int generation) async {
    final artworkUrl = normalizeArtworkUrl(song.artworkUrl, size: 720);
    if (artworkUrl == null) return;
    try {
      final file = await ArtworkCacheService.instance.getFile(
        url: artworkUrl,
        cacheId: 'song:${song.id}',
        pixelSize: 720,
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

  bool _isCurrentRequest(int generation) => generation == _loadGeneration;

  Future<void> _advanceAfterCompletion() async {
    if (_advancing) return;
    _advancing = true;
    try {
      if (_order == PlaybackOrder.repeatOne) {
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
      _messages.add(error.toString());
    } finally {
      _advancing = false;
    }
  }

  void _enforcePreviewEnd(Duration position) {
    final end = _previewEnd;
    if (end == null || _previewStopped || position < end) return;
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
