import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kgmusic/core/cache/artwork_cache.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/player/playback_queue_sources.dart';
import 'package:kgmusic/core/player/playback_queue_store.dart';
import 'package:kgmusic/core/player/system_media_projection.dart';

part 'music_audio_queue.dart';
part 'music_audio_transition.dart';

class MusicAudioHandler extends BaseAudioHandler
    with SeekHandler, WidgetsBindingObserver {
  MusicAudioHandler(
    this._sdk,
    this._library,
    this._audioCache, {
    this.queueStore,
    this.queueSourceFactory,
  }) {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        unawaited(_advanceAfterCompletion());
      }
    });
    _player.positionStream.listen(_enforcePreviewEnd);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_configureSession());
    unawaited(_restoreQueue());
  }

  final MusicSdk _sdk;
  final LibraryRepository _library;
  final AudioCacheManager _audioCache;
  final PlaybackQueueStore? queueStore;
  final PlaybackQueueSourceFactory? queueSourceFactory;
  final AudioPlayer _player = AudioPlayer();
  final StreamController<String?> _messages = StreamController.broadcast();
  final StreamController<PlaybackQualityState> _qualityStates =
      StreamController.broadcast(sync: true);
  final StreamController<PlaybackQueueState> _queueStates =
      StreamController.broadcast(sync: true);
  List<Song> _songs = const [];
  int _index = -1;
  int _loadGeneration = 0;
  AudioQuality _preferredQuality = AudioQuality.standard;
  PlaybackQualityState _qualityState = const PlaybackQualityState(
    requested: AudioQuality.standard,
  );
  Duration? _previewEnd;
  bool _previewStopped = false;
  CachedAudioHandle? _currentAudioHandle;
  Future<void> _commitTail = Future<void>.value();
  Future<void> _persistTail = Future<void>.value();
  bool _advancing = false;
  PlaybackQueueRequest? _queueRequest;
  PlaybackQueueState? _queueState;
  bool _loadingMore = false;
  PlaybackOrder _order = PlaybackOrder.sequential;
  final Random _random = Random();
  final Set<String> _shuffleRemaining = {};
  Duration? _restoredPosition;
  Duration? _currentMediaDuration;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<String?> get messages => _messages.stream;
  Stream<PlaybackQualityState> get qualityStateStream => _qualityStates.stream;
  Stream<PlaybackQueueState> get queueStateStream => _queueStates.stream;
  PlaybackQualityState get qualityState => _qualityState;
  PlaybackQueueState? get queueState => _queueState;
  Duration get position => _player.position;
  List<Song> get songs => List.unmodifiable(_songs);
  int get currentIndex => _index;

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
      _preferredQuality = quality;
      _emitQualityState(PlaybackQualityState(requested: quality));
      return;
    }

    final previousQuality = _preferredQuality;
    final previousState = _qualityState;
    final resumePosition = _player.position;
    final resumePlaying = _player.playing;
    _preferredQuality = quality;
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
      }
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
    // just_audio completes play() only after pause, stop, or completion. Never
    // await it from the serialized transition queue or later switches deadlock.
    unawaited(
      _player.play().catchError((Object error) {
        _messages.add('播放失败：$error');
      }),
    );
  }

  @override
  Future<void> play() async {
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
  Future<void> seek(Duration position) => _player.seek(position);

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
    _loadGeneration += 1;
    await _persistQueue();
    _audioCache.setActive(null);
    _currentAudioHandle = null;
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_songs.isEmpty || _index < 0) return;
    if (_order == PlaybackOrder.repeatOne) {
      await seek(Duration.zero);
      await play();
      return;
    }
    if (_order == PlaybackOrder.shuffle) {
      if (_shuffleRemaining.isEmpty && _queueRequest?.hasMore == true) {
        await loadMoreQueue();
      }
      if (_shuffleRemaining.isNotEmpty) {
        final ids = _shuffleRemaining.toList(growable: false);
        final id = ids[_random.nextInt(ids.length)];
        _shuffleRemaining.remove(id);
        final target = _songs.indexWhere((song) => song.id == id);
        if (target >= 0) {
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

  void _broadcastState(PlaybackEvent event) =>
      _publishSystemPlaybackState(event);
}

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
