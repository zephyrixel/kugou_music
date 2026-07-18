import 'package:kgmusic/core/models/song.dart';

typedef PlaybackProfileRecorder =
    Future<void> Function(
      Song song, {
      required Duration listened,
      required int sourceBits,
    });

/// Tracks wall-clock listening time for one playback session.
class RecommendationPlayTracker {
  RecommendationPlayTracker(this._record, {Duration Function()? elapsedNow})
    : _elapsedNow = elapsedNow ?? _defaultElapsedNow;

  static final Stopwatch _clock = Stopwatch()..start();

  final PlaybackProfileRecorder _record;
  final Duration Function() _elapsedNow;
  Song? _song;
  int _sourceBits = 0;
  Duration _listened = Duration.zero;
  Duration? _playingSince;

  void activate(Song song, {required int sourceBits, bool newPlayback = true}) {
    if (!newPlayback && _song?.id == song.id) {
      _song = song;
      _sourceBits |= sourceBits;
      return;
    }
    _song = song;
    _sourceBits = sourceBits;
    _listened = Duration.zero;
    _playingSince = null;
  }

  void update({required bool playing}) {
    if (_song == null) return;
    final now = _elapsedNow();
    if (playing) {
      _playingSince ??= now;
      return;
    }
    final startedAt = _playingSince;
    if (startedAt != null && now > startedAt) {
      _listened += now - startedAt;
    }
    _playingSince = null;
  }

  Future<void> finish() async {
    update(playing: false);
    final song = _song;
    final listened = _listened;
    final sourceBits = _sourceBits;
    reset();
    if (song == null || listened <= Duration.zero) return;
    await _record(song, listened: listened, sourceBits: sourceBits);
  }

  void reset() {
    _song = null;
    _sourceBits = 0;
    _listened = Duration.zero;
    _playingSince = null;
  }

  static Duration _defaultElapsedNow() => _clock.elapsed;
}
