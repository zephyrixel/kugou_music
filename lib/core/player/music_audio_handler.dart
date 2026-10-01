import 'dart:async';

import 'package:kgmusic/core/auth/account_session.dart';
import 'package:kgmusic/core/models/pagination.dart';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kgmusic/core/cache/artwork_cache.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/audio_player_port.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/player/playback_queue_controller.dart';
import 'package:kgmusic/core/player/playback_queue_sources.dart';
import 'package:kgmusic/core/player/playback_queue_store.dart';
import 'package:kgmusic/core/recommendation/recommendation_queue_source.dart';
import 'package:kgmusic/core/recommendation/recommendation_play_tracker.dart';
import 'package:kgmusic/core/player/system_media_projection.dart';

part 'music_audio_queue.dart';
part 'music_audio_transition.dart';

class MusicAudioHandler extends BaseAudioHandler
    with SeekHandler, WidgetsBindingObserver {
  MusicAudioHandler(
    this._sdk,
    this._recordPlayed,
    this._audioCache, {
    PlaybackProfileRecorder? recordRecommendationPlayback,
    this.queueStore,
    this.queueSourceFactory,
    this.accountSession,
    AudioPlayerPort? player,
    Future<void> Function()? configureSession,
    AudioQuality initialQuality = AudioQuality.standard,
    Future<void> Function(AudioQuality)? persistPreferredQuality,
    bool observeLifecycle = true,
    bool restoreQueueOnStart = true,
  }) : _player = player ?? JustAudioPlayerPort(),
       _preferredQuality = initialQuality,
       _qualityState = PlaybackQualityState(requested: initialQuality),
       _persistPreferredQuality = persistPreferredQuality ?? _ignoreQuality,
       _recommendationPlayTracker = RecommendationPlayTracker(
         recordRecommendationPlayback ??
             (_, {required listened, required sourceBits}) async {},
       ) {
    _subscriptions.add(
      _player.playbackEventStream.listen((event) {
        _updateRecommendationClock();
        _broadcastState(event);
      }),
    );
    _subscriptions.add(
      _player.processingStateStream.listen((state) {
        _updateRecommendationClock();
        if (state == ProcessingState.completed) {
          unawaited(_advanceAfterCompletion());
        }
      }),
    );
    _subscriptions.add(
      _player.positionStream.listen((position) {
        _enforcePreviewEnd(position);
        _updateRecommendationClock();
      }),
    );
    _observingLifecycle = observeLifecycle;
    if (_observingLifecycle) WidgetsBinding.instance.addObserver(this);
    unawaited(
      (configureSession ?? _configureSession)().catchError((Object error) {
        AppLog.warn('配置音频会话失败', target: 'player.engine', error: error);
      }),
    );
    if (restoreQueueOnStart) {
      unawaited(
        _restoreQueue().catchError((Object error) {
          AppLog.warn('恢复播放队列失败', target: 'player.queue', error: error);
        }),
      );
    }
  }

  final PlayerSdk _sdk;
  final AccountSession? accountSession;
  final Future<void> Function(Song) _recordPlayed;
  final AudioCache _audioCache;
  final PlaybackQueueStore? queueStore;
  final PlaybackQueueSourceFactory? queueSourceFactory;
  final AudioPlayerPort _player;
  final Future<void> Function(AudioQuality) _persistPreferredQuality;
  final RecommendationPlayTracker _recommendationPlayTracker;
  final StreamController<String?> _messages = StreamController.broadcast();
  final StreamController<PlaybackQualityState> _qualityStates =
      StreamController.broadcast(sync: true);
  final StreamController<PlaybackQueueState?> _queueStates =
      StreamController.broadcast(sync: true);
  final PlaybackQueueController _queueController = PlaybackQueueController();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  int _loadGeneration = 0;
  AudioQuality _preferredQuality;
  PlaybackQualityState _qualityState;
  Duration? _previewEnd;
  bool _previewStopped = false;
  CachedAudioHandle? _currentAudioHandle;
  Future<void> _commitTail = Future<void>.value();
  Future<void> _persistTail = Future<void>.value();
  bool _advancing = false;
  PlaybackQueueRequest? get _queueRequest => _queueController.request;
  PlaybackQueueState? _queueState;
  bool _loadingMore = false;
  Future<void>? _loadMoreOperation;
  Object? _loadMoreIdentity;
  Timer? _prefetchTimer;
  String? _prefetchAttemptedSongId;
  Duration? _restoredPosition;
  Duration? _currentMediaDuration;
  bool _observingLifecycle = false;
  bool _disposed = false;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<String?> get messages => _messages.stream;
  Stream<PlaybackQualityState> get qualityStateStream => _qualityStates.stream;
  Stream<PlaybackQueueState?> get queueStateStream => _queueStates.stream;
  PlaybackQualityState get qualityState => _qualityState;
  PlaybackQueueState? get queueState => _queueState;
  Duration get position => _player.position;
  List<Song> get _songs => _queueController.songs;
  int get _index => _queueController.currentIndex;
  PlaybackOrder get _order => _queueController.order;
  List<Song> get songs => _songs;
  int get currentIndex => _index;
  bool get isRecommendationQueue =>
      _queueRequest?.source is RecommendationFeedbackSource;

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playSong(
    Song song, {
    List<Song>? queueSongs,
    PlaybackQueueRequest? queueRequest,
  }) async {
    final request =
        queueRequest ??
        PlaybackQueueRequest.snapshot(
          title: '播放队列',
          songs: queueSongs?.isNotEmpty == true ? queueSongs! : [song],
        );
    final nextQueue = request.songs.isEmpty ? [song] : request.songs;
    var nextIndex = nextQueue.indexWhere((item) => item.id == song.id);
    if (nextIndex < 0) {
      nextIndex = 0;
    }
    await _requestPlayback(
      request: request.copyWith(songs: nextQueue),
      index: nextIndex,
      initialPosition: Duration.zero,
      autoPlay: true,
      recordHistory: true,
    );
  }

  Future<void> setPlaybackQuality(AudioQuality quality) async {
    if (quality == _preferredQuality &&
        _qualityState.actual == quality &&
        !_qualityState.switching) {
      return;
    }

    if (_index < 0 || _index >= _songs.length) {
      await _persistPreferredQuality(quality);
      _preferredQuality = quality;
      _emitQualityState(PlaybackQualityState(requested: quality));
      return;
    }

    final previousQuality = _preferredQuality;
    final previousState = _qualityState;
    final resumePosition = _player.position;
    final resumePlaying = _player.playing;
    await _persistPreferredQuality(quality);
    _preferredQuality = quality;
    AppLog.info(
      '切换播放音质 ${previousQuality.name} -> ${quality.name}',
      target: 'player.quality',
    );
    try {
      await _requestPlayback(
        request:
            _queueRequest ??
            PlaybackQueueRequest.snapshot(title: '播放队列', songs: _songs),
        index: _index,
        initialPosition: resumePosition,
        autoPlay: resumePlaying,
        recordHistory: false,
      );
    } catch (_) {
      if (_preferredQuality == quality) {
        _preferredQuality = previousQuality;
        _emitQualityState(previousState);
        try {
          await _persistPreferredQuality(previousQuality);
        } catch (error) {
          AppLog.warn('恢复播放音质偏好失败', target: 'player.quality', error: error);
        }
      }
      AppLog.warn('切换播放音质失败', target: 'player.quality');
      rethrow;
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) => _removeQueueItemAt(index);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persistQueue());
    }
  }

  MediaItem _toMediaItem(
    Song song, {
    Duration? actualDuration,
    Uri? artworkUri,
  }) => SystemMediaProjection.mediaItemForSong(
    song,
    actualDuration: actualDuration,
    artworkUri: artworkUri,
  );

  void _publishMediaQueue() {
    queue.add(
      List.generate(
        _songs.length,
        (index) => _toMediaItem(
          _songs[index],
          actualDuration: index == _index ? _currentMediaDuration : null,
        ),
        growable: false,
      ),
    );
  }

  void _publishSystemPlaybackState([PlaybackEvent? event]) {
    playbackState.add(
      SystemMediaProjection.playbackState(
        event: event ?? _player.playbackEvent,
        playing: _player.playing,
        order: _order,
        currentIndex: _index,
        speed: _player.speed,
      ),
    );
  }

  void _startPlayer() {
    if (_disposed) return;
    // just_audio completes play() only after pause, stop, or completion. Never
    // await it from the serialized transition queue or later switches deadlock.
    unawaited(
      _player.play().catchError((Object error) {
        AppLog.error('播放器启动播放失败', target: 'player.engine', error: error);
        if (!_disposed) _messages.add('播放未能开始，请稍后重试');
      }),
    );
  }

  @override
  Future<void> play() async {
    if (_disposed) return;
    if (_previewEnd != null &&
        (_previewStopped || _player.position >= _previewEnd!)) {
      await seek(Duration.zero);
    }
    final request = _queueRequest;
    if (_player.processingState == ProcessingState.idle &&
        request != null &&
        _index >= 0 &&
        _index < request.songs.length) {
      await _requestPlayback(
        request: request,
        index: _index,
        initialPosition: _restoredPosition,
        autoPlay: true,
        recordHistory: false,
      );
      return;
    }
    _startPlayer();
  }

  @override
  Future<void> pause() async {
    if (_disposed) return;
    await _player.pause();
    unawaited(_persistQueue());
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) =>
      switch (button) {
        MediaButton.media => _player.playing ? pause() : play(),
        MediaButton.next => skipToNext(),
        MediaButton.previous => skipToPrevious(),
      };

  @override
  Future<void> seek(Duration position) async {
    if (_disposed) return;
    final end = _previewEnd;
    var target = position < Duration.zero ? Duration.zero : position;
    if (end != null && target >= end) {
      target = end;
      _previewStopped = true;
      await _player.pause();
    } else {
      _previewStopped = false;
    }
    await _player.seek(target);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) =>
      setPlaybackOrder(
        SystemMediaProjection.applyRepeatMode(_order, repeatMode),
      );

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) =>
      setPlaybackOrder(
        SystemMediaProjection.applyShuffleMode(_order, shuffleMode),
      );

  @override
  Future<void> stop() async {
    if (_disposed) return;
    _loadGeneration += 1;
    _prefetchTimer?.cancel();
    _prefetchAttemptedSongId = null;
    await _persistQueue();
    await _player.stop();
    _audioCache.setActive(null);
    await _finishRecommendationSession();
    _currentAudioHandle?.release();
    _currentAudioHandle = null;
    await super.stop();
  }

  /// Flushes playback state and releases native audio resources exactly once.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _loadGeneration += 1;
    _prefetchTimer?.cancel();
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
    await _disposeStep('等待音源切换结束', () => _commitTail);
    await _disposeStep('保存播放队列', _persistQueue);
    await _disposeStep('结束推荐播放会话', _finishRecommendationSession);
    await _disposeStep('停止播放器', _player.stop);
    _audioCache.setActive(null);
    _currentAudioHandle?.release();
    _currentAudioHandle = null;
    for (final subscription in _subscriptions) {
      await _disposeStep('取消播放器订阅', subscription.cancel);
    }
    _subscriptions.clear();
    await _disposeStep('释放播放器', _player.dispose);
    await _disposeStep('关闭播放器消息流', _messages.close);
    await _disposeStep('关闭音质状态流', _qualityStates.close);
    await _disposeStep('关闭队列状态流', _queueStates.close);
  }

  Future<void> _disposeStep(
    String description,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } catch (error, stackTrace) {
      AppLog.warn(
        '$description失败',
        target: 'player.dispose',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> skipToNext() => _skipToNextInternal();

  Future<void> _skipToNextInternal({bool honorRepeatOne = true}) async {
    if (_disposed) return;
    if (_songs.isEmpty || _index < 0) return;
    if (honorRepeatOne && _order == PlaybackOrder.repeatOne) {
      await seek(Duration.zero);
      await play();
      return;
    }
    if (_order == PlaybackOrder.shuffle) {
      if (!_queueController.hasShuffleCandidates &&
          _queueRequest?.hasMore == true) {
        await loadMoreQueue();
      }
      if (_queueController.hasShuffleCandidates) {
        final target = _queueController.takeRandomIndex();
        if (target != null) {
          await _requestPlayback(
            request: _queueRequest!,
            index: target,
            initialPosition: Duration.zero,
            autoPlay: true,
            recordHistory: true,
          );
          return;
        }
      }
    }
    if (_index + 1 >= _songs.length && _queueRequest?.hasMore == true) {
      await loadMoreQueue();
    }
    if (_index + 1 >= _songs.length) {
      if (_order == PlaybackOrder.repeatAll) {
        await _requestPlayback(
          request: _queueRequest!,
          index: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
          recordHistory: true,
        );
        return;
      }
      _loadGeneration += 1;
      await _player.pause();
      await _player.seek(Duration.zero);
      return;
    }
    final request = _queueRequest;
    if (request == null) return;
    await _requestPlayback(
      request: request,
      index: _index + 1,
      initialPosition: Duration.zero,
      autoPlay: true,
      recordHistory: true,
    );
  }

  @override
  Future<void> skipToPrevious() async {
    if (_disposed) return;
    if (_index <= 0) {
      if (_order == PlaybackOrder.repeatAll && _songs.length > 1) {
        final request = _queueRequest;
        if (request == null) return;
        await _requestPlayback(
          request: request,
          index: _songs.length - 1,
          initialPosition: Duration.zero,
          autoPlay: true,
          recordHistory: true,
        );
        return;
      }
      await seek(Duration.zero);
      return;
    }
    final request = _queueRequest;
    if (request == null) return;
    await _requestPlayback(
      request: request,
      index: _index - 1,
      initialPosition: Duration.zero,
      autoPlay: true,
      recordHistory: true,
    );
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final request = _queueRequest;
    if (request == null || index < 0 || index >= _songs.length) return;
    await _requestPlayback(
      request: request,
      index: index,
      initialPosition: Duration.zero,
      autoPlay: true,
      recordHistory: index != _index,
    );
  }

  Future<void> dislikeCurrent() async {
    final feedback = _recommendationFeedbackContext();
    final source = _queueRequest?.source;
    final RecommendationFeedbackSource? feedbackSource =
        source is RecommendationFeedbackSource
        ? source as RecommendationFeedbackSource
        : null;
    if (feedback == null || feedbackSource == null) return;
    await _skipToNextInternal(honorRepeatOne: false);
    feedbackSource.reportDislike(feedback);
  }

  RecommendationFeedbackContext? _recommendationFeedbackContext() {
    final source = _queueRequest?.source;
    if (source is! RecommendationFeedbackSource ||
        _index < 0 ||
        _index >= _songs.length) {
      return null;
    }
    return RecommendationFeedbackContext(
      song: _songs[_index],
      remainSongCount: (_songs.length - _index - 1).clamp(0, _songs.length),
      position: _player.position,
    );
  }

  void _broadcastState(PlaybackEvent event) =>
      _publishSystemPlaybackState(event);

  void _updateRecommendationClock() => _recommendationPlayTracker.update(
    playing:
        !_disposed &&
        _player.playing &&
        _player.processingState == ProcessingState.ready,
  );

  Future<void> _finishRecommendationSession() async {
    try {
      await _recommendationPlayTracker.finish();
    } catch (error) {
      AppLog.warn('保存本地推荐画像失败', target: 'recommendation.profile', error: error);
    }
  }
}

Future<void> _ignoreQuality(AudioQuality _) async {}

class PlaybackQualityState {
  const PlaybackQualityState({
    required this.requested,
    this.actual,
    this.bitRate,
    this.switching = false,
    this.preview = false,
  });

  final AudioQuality requested;
  final AudioQuality? actual;
  final int? bitRate;
  final bool switching;
  final bool preview;

  int? get bitRateKbps {
    final value = bitRate;
    if (value == null || value <= 0) return null;
    return value >= 10000 ? value ~/ 1000 : value;
  }

  bool get fellBack => actual != null && actual != requested;
}
