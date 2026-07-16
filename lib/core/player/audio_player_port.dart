import 'package:just_audio/just_audio.dart';

/// Minimal just_audio surface used by the application player.
abstract interface class AudioPlayerPort {
  Stream<PlaybackEvent> get playbackEventStream;
  Stream<ProcessingState> get processingStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<Duration> get bufferedPositionStream;

  PlaybackEvent get playbackEvent;
  ProcessingState get processingState;
  bool get playing;
  Duration get position;
  double get speed;

  Future<Duration?> setAudioSource(
    AudioSource source, {
    Duration? initialPosition,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();
}

class JustAudioPlayerPort implements AudioPlayerPort {
  JustAudioPlayerPort([AudioPlayer? player])
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;
  @override
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;
  @override
  Stream<Duration> get positionStream => _player.positionStream;
  @override
  Stream<Duration?> get durationStream => _player.durationStream;
  @override
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  @override
  PlaybackEvent get playbackEvent => _player.playbackEvent;
  @override
  ProcessingState get processingState => _player.processingState;
  @override
  bool get playing => _player.playing;
  @override
  Duration get position => _player.position;
  @override
  double get speed => _player.speed;

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    Duration? initialPosition,
  }) => _player.setAudioSource(source, initialPosition: initialPosition);

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> stop() => _player.stop();
}
