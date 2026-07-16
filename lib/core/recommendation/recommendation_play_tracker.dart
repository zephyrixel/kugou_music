import 'dart:async';

import 'package:kgmusic/core/models/song.dart';

/// Reports a song after meaningful playback time instead of on resource load.
class RecommendationPlayTracker {
  RecommendationPlayTracker(this._onQualifiedPlay);

  final Future<void> Function(Song song) _onQualifiedPlay;
  Song? _song;
  Duration? _duration;
  bool _reported = false;

  void activate(Song song, {Duration? duration, bool newPlayback = true}) {
    if (!newPlayback && _song?.id == song.id) {
      _song = song;
      _duration = duration ?? _duration;
      return;
    }
    _song = song;
    _duration = duration;
    _reported = false;
  }

  void update({
    required Duration position,
    required bool playing,
    Duration? duration,
  }) {
    if (!playing || _reported || _song == null) return;
    _duration = duration ?? _duration;
    if (position < _threshold) return;
    _reported = true;
    unawaited(_onQualifiedPlay(_song!));
  }

  void reset() {
    _song = null;
    _duration = null;
    _reported = false;
  }

  Duration get _threshold {
    final duration = _duration;
    if (duration == null || duration <= Duration.zero) {
      return const Duration(seconds: 30);
    }
    final half = duration ~/ 2;
    if (half <= Duration.zero) return const Duration(seconds: 1);
    return half < const Duration(seconds: 30)
        ? half
        : const Duration(seconds: 30);
  }
}
