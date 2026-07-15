import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';

abstract final class SystemMediaProjection {
  static MediaItem mediaItemForSong(
    Song song, {
    Duration? actualDuration,
    Uri? artworkUri,
  }) {
    final artworkUrl = normalizeArtworkUrl(song.artworkUrl);
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artistLabel,
      album: song.album,
      duration:
          actualDuration ??
          (song.durationSecs == null
              ? null
              : Duration(seconds: song.durationSecs!)),
      artUri: artworkUri ?? (artworkUrl == null ? null : Uri.parse(artworkUrl)),
      displayTitle: song.title,
      displaySubtitle: song.artistLabel,
    );
  }

  static PlaybackState playbackState({
    required PlaybackEvent event,
    required bool playing,
    required PlaybackOrder order,
    required int currentIndex,
    required double speed,
  }) {
    final hasError = event.errorCode != null;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        MediaControl(
          androidIcon: playing
              ? 'drawable/audio_service_pause'
              : 'drawable/audio_service_play_arrow',
          label: playing ? 'Pause' : 'Play',
          action: MediaAction.playPause,
        ),
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: hasError
          ? AudioProcessingState.error
          : switch (event.processingState) {
              ProcessingState.idle => AudioProcessingState.idle,
              ProcessingState.loading => AudioProcessingState.loading,
              ProcessingState.buffering => AudioProcessingState.buffering,
              ProcessingState.ready => AudioProcessingState.ready,
              ProcessingState.completed => AudioProcessingState.completed,
            },
      playing: playing,
      repeatMode: repeatModeFor(order),
      shuffleMode: shuffleModeFor(order),
      updatePosition: event.updatePosition,
      bufferedPosition: event.bufferedPosition,
      speed: speed,
      updateTime: event.updateTime,
      errorCode: event.errorCode,
      errorMessage: event.errorMessage,
      queueIndex: currentIndex < 0 ? null : currentIndex,
    );
  }

  static AudioServiceRepeatMode repeatModeFor(PlaybackOrder order) =>
      switch (order) {
        PlaybackOrder.repeatOne => AudioServiceRepeatMode.one,
        PlaybackOrder.repeatAll => AudioServiceRepeatMode.all,
        PlaybackOrder.sequential ||
        PlaybackOrder.shuffle => AudioServiceRepeatMode.none,
      };

  static AudioServiceShuffleMode shuffleModeFor(PlaybackOrder order) =>
      order == PlaybackOrder.shuffle
      ? AudioServiceShuffleMode.all
      : AudioServiceShuffleMode.none;

  static PlaybackOrder applyRepeatMode(
    PlaybackOrder current,
    AudioServiceRepeatMode repeatMode,
  ) => switch (repeatMode) {
    AudioServiceRepeatMode.one => PlaybackOrder.repeatOne,
    AudioServiceRepeatMode.all => PlaybackOrder.repeatAll,
    AudioServiceRepeatMode.none || AudioServiceRepeatMode.group =>
      current == PlaybackOrder.repeatOne || current == PlaybackOrder.repeatAll
          ? PlaybackOrder.sequential
          : current,
  };

  static PlaybackOrder applyShuffleMode(
    PlaybackOrder current,
    AudioServiceShuffleMode shuffleMode,
  ) => switch (shuffleMode) {
    AudioServiceShuffleMode.all ||
    AudioServiceShuffleMode.group => PlaybackOrder.shuffle,
    AudioServiceShuffleMode.none =>
      current == PlaybackOrder.shuffle ? PlaybackOrder.sequential : current,
  };
}
