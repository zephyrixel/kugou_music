import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kgmusic/core/cache/artwork_cache.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';

class MusicAudioHandler extends BaseAudioHandler with SeekHandler {
  MusicAudioHandler(this._sdk, this._library, this._audioCache) {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        unawaited(skipToNext());
      }
    });
    _player.positionStream.listen(_enforcePreviewEnd);
    unawaited(_configureSession());
  }

  final MusicSdk _sdk;
  final LibraryRepository _library;
  final AudioCacheManager _audioCache;
  final AudioPlayer _player = AudioPlayer();
  final StreamController<String?> _messages = StreamController.broadcast();
  final StreamController<PlaybackQualityState> _qualityStates =
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

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<String?> get messages => _messages.stream;
  Stream<PlaybackQualityState> get qualityStateStream => _qualityStates.stream;
  PlaybackQualityState get qualityState => _qualityState;
  Duration get position => _player.position;
  List<Song> get songs => List.unmodifiable(_songs);
  int get currentIndex => _index;

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playSong(Song song, {List<Song>? queueSongs}) async {
    final nextQueue = queueSongs?.isNotEmpty == true ? queueSongs! : [song];
    var nextIndex = nextQueue.indexWhere((item) => item.id == song.id);
    if (nextIndex < 0) {
      nextIndex = 0;
    }
    _songs = List.unmodifiable(nextQueue);
    _index = nextIndex;
    queue.add(_songs.map(_toMediaItem).toList(growable: false));
    await _loadCurrent();
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
      await _loadCurrent(
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

  Future<void> _loadCurrent({
    Duration? initialPosition,
    bool autoPlay = true,
    bool recordHistory = true,
  }) async {
    final generation = ++_loadGeneration;
    if (_index < 0 || _index >= _songs.length) return;
    final song = _songs[_index];
    final requestedQuality = _preferredQuality;
    _messages.add(null);
    _previewEnd = null;
    _previewStopped = false;
    mediaItem.add(_toMediaItem(song));
    _emitQualityState(
      PlaybackQualityState(requested: requestedQuality, switching: true),
    );

    try {
      await _resolveAndPlay(
        song,
        generation,
        requestedQuality,
        initialPosition: initialPosition,
        autoPlay: autoPlay,
        recordHistory: recordHistory,
      );
    } on MusicSdkException catch (error) {
      if (!_isCurrentLoad(generation, song)) return;
      if (error.code == 20028) {
        try {
          await _sdk.registerDevice();
          if (!_isCurrentLoad(generation, song)) return;
          await _resolveAndPlay(
            song,
            generation,
            requestedQuality,
            initialPosition: initialPosition,
            autoPlay: autoPlay,
            recordHistory: recordHistory,
          );
          return;
        } catch (_) {
          // Keep the original security challenge as the user-facing error.
        }
      }
      _finishQualityLoadWithError(requestedQuality);
      _messages.add(error.toString());
      rethrow;
    } catch (error) {
      if (!_isCurrentLoad(generation, song)) return;
      _finishQualityLoadWithError(requestedQuality);
      _messages.add(error.toString());
      rethrow;
    }
  }

  Future<void> _resolveAndPlay(
    Song song,
    int generation,
    AudioQuality requestedQuality, {
    Duration? initialPosition,
    required bool autoPlay,
    required bool recordHistory,
  }) async {
    var resolution = await _sdk.resolve(song, quality: requestedQuality);
    if (!_isCurrentLoad(generation, song)) return;
    if (resolution is DeniedResolution || resolution is UnavailableResolution) {
      resolution = await _sdk.resolve(
        song,
        quality: requestedQuality,
        freePreview: true,
      );
      if (!_isCurrentLoad(generation, song)) return;
    }
    if (resolution is! PlayableResolution) {
      throw const MusicSdkException('当前歌曲暂时无法播放');
    }
    if (resolution is PreviewResolution && resolution.endMs != null) {
      _previewEnd = Duration(milliseconds: resolution.endMs!);
    }
    final resolvedSong = _applyResolvedArtwork(song, resolution, generation);
    var resumePosition = initialPosition;
    final previewEnd = _previewEnd;
    if (resumePosition != null &&
        previewEnd != null &&
        resumePosition >= previewEnd) {
      resumePosition = Duration.zero;
    }
    final audioHandle = await _audioCache.sourceFor(resolvedSong, resolution);
    final previousAudioHandle = _currentAudioHandle;
    _audioCache.setActive(audioHandle);
    try {
      await _player.setAudioSource(
        audioHandle.source,
        initialPosition: resumePosition,
      );
    } catch (_) {
      _audioCache.setActive(previousAudioHandle);
      rethrow;
    }
    _currentAudioHandle = audioHandle;
    if (!_isCurrentLoad(generation, resolvedSong)) return;
    unawaited(_cacheArtwork(resolvedSong, generation));
    _emitQualityState(
      PlaybackQualityState(
        requested: requestedQuality,
        actual: resolution is PreviewResolution
            ? AudioQuality.standard
            : resolution.quality,
        bitRate: resolution.bitRate,
        preview: resolution is PreviewResolution,
      ),
    );
    if (recordHistory) await _library.recordPlayed(resolvedSong);
    if (!_isCurrentLoad(generation, resolvedSong)) return;
    if (autoPlay) {
      await _player.play();
    } else {
      await _player.pause();
    }
  }

  void _finishQualityLoadWithError(AudioQuality requestedQuality) {
    _emitQualityState(PlaybackQualityState(requested: requestedQuality));
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
      if (!_isCurrentLoad(generation, song)) return;
      mediaItem.add(_toMediaItem(song, artworkUri: Uri.file(file.path)));
    } catch (_) {
      // The remote artwork URI remains usable when local prefetch fails.
    }
  }

  Song _applyResolvedArtwork(
    Song song,
    PlayableResolution resolution,
    int generation,
  ) {
    final artworkUrl = resolution.artworkUrl?.trim();
    final normalizedArtworkUrl = normalizeArtworkUrl(artworkUrl);
    if (normalizedArtworkUrl == null ||
        normalizedArtworkUrl == normalizeArtworkUrl(song.artworkUrl) ||
        !_isCurrentLoad(generation, song)) {
      return song;
    }

    final resolvedSong = song.copyWith(artworkUrl: artworkUrl);
    final updatedQueue = [..._songs];
    updatedQueue[_index] = resolvedSong;
    _songs = List.unmodifiable(updatedQueue);
    queue.add(_songs.map(_toMediaItem).toList(growable: false));
    mediaItem.add(_toMediaItem(resolvedSong));
    return resolvedSong;
  }

  bool _isCurrentLoad(int generation, Song song) =>
      generation == _loadGeneration &&
      _index >= 0 &&
      _index < _songs.length &&
      _songs[_index].id == song.id;

  void _enforcePreviewEnd(Duration position) {
    final end = _previewEnd;
    if (end == null || _previewStopped || position < end) return;
    _previewStopped = true;
    unawaited(_player.pause());
    _messages.add('试听片段已结束');
  }

  MediaItem _toMediaItem(Song song, {Uri? artworkUri}) {
    final artworkUrl = normalizeArtworkUrl(song.artworkUrl);
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artistLabel,
      album: song.album,
      duration: song.durationSecs == null
          ? null
          : Duration(seconds: song.durationSecs!),
      artUri: artworkUri ?? (artworkUrl == null ? null : Uri.parse(artworkUrl)),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    _loadGeneration += 1;
    _audioCache.setActive(null);
    _currentAudioHandle = null;
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_index + 1 >= _songs.length) {
      _loadGeneration += 1;
      await _player.pause();
      await _player.seek(Duration.zero);
      return;
    }
    _index += 1;
    await _loadCurrent();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 4)) {
      await seek(Duration.zero);
      return;
    }
    if (_index <= 0) {
      await seek(Duration.zero);
      return;
    }
    _index -= 1;
    await _loadCurrent();
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _index < 0 ? null : _index,
      ),
    );
  }
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
