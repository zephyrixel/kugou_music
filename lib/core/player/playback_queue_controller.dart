import 'dart:math';

import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';

/// Owns the mutable, purely local portion of the playback queue.
///
/// Network pagination and actual audio transitions stay in [MusicAudioHandler];
/// this class only keeps queue order/index mutations deterministic and testable.
class PlaybackQueueController {
  PlaybackQueueController({Random? random}) : _random = random ?? Random();

  final Random _random;
  List<Song> _songs = const [];
  int _currentIndex = -1;
  PlaybackOrder _order = PlaybackOrder.sequential;
  final Set<String> _shuffleRemaining = {};

  List<Song> get songs => _songs;
  int get currentIndex => _currentIndex;
  PlaybackOrder get order => _order;
  bool get hasShuffleCandidates => _shuffleRemaining.isNotEmpty;

  void commit(List<Song> songs, int index, {required bool replacingQueue}) {
    _songs = List.unmodifiable(songs);
    _currentIndex = index.clamp(-1, _songs.length - 1);
    if (_order != PlaybackOrder.shuffle) return;
    if (replacingQueue) {
      _shuffleRemaining
        ..clear()
        ..addAll(_songs.map((song) => song.id));
    }
    if (_currentIndex >= 0) {
      _shuffleRemaining.remove(_songs[_currentIndex].id);
    }
  }

  void append(List<Song> songs) {
    if (songs.isEmpty) return;
    _songs = List.unmodifiable([..._songs, ...songs]);
    if (_order == PlaybackOrder.shuffle) {
      _shuffleRemaining.addAll(songs.map((song) => song.id));
    }
  }

  void setOrder(PlaybackOrder order) {
    _order = order;
    _shuffleRemaining.clear();
    if (order == PlaybackOrder.shuffle) {
      final currentId = _currentIndex >= 0 ? _songs[_currentIndex].id : null;
      _shuffleRemaining.addAll(
        _songs.where((song) => song.id != currentId).map((song) => song.id),
      );
    }
  }

  int? takeRandomIndex() {
    if (_shuffleRemaining.isEmpty) return null;
    final ids = _shuffleRemaining.toList(growable: false);
    final id = ids[_random.nextInt(ids.length)];
    _shuffleRemaining.remove(id);
    final index = _songs.indexWhere((song) => song.id == id);
    return index < 0 ? null : index;
  }

  bool removeAt(int index) {
    if (index < 0 || index >= _songs.length || index == _currentIndex) {
      return false;
    }
    final updated = [..._songs]..removeAt(index);
    if (index < _currentIndex) _currentIndex -= 1;
    _songs = List.unmodifiable(updated);
    _shuffleRemaining.removeWhere(
      (id) => !updated.any((song) => song.id == id),
    );
    return true;
  }

  bool clearUpcoming() {
    if (_currentIndex < 0 || _currentIndex + 1 >= _songs.length) return false;
    _songs = List.unmodifiable(_songs.take(_currentIndex + 1));
    _shuffleRemaining.clear();
    return true;
  }

  bool move(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _songs.length) return false;
    if (newIndex > oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, _songs.length - 1);
    if (oldIndex == newIndex) return false;
    final currentId = _currentIndex >= 0 ? _songs[_currentIndex].id : null;
    final updated = [..._songs];
    final song = updated.removeAt(oldIndex);
    updated.insert(newIndex, song);
    _songs = List.unmodifiable(updated);
    _currentIndex = currentId == null
        ? -1
        : updated.indexWhere((item) => item.id == currentId);
    return true;
  }

  void restore(List<Song> songs, int index, PlaybackOrder order) {
    _songs = List.unmodifiable(songs);
    _currentIndex = index.clamp(-1, _songs.length - 1);
    setOrder(order);
  }

  void clear() {
    _songs = const [];
    _currentIndex = -1;
    _shuffleRemaining.clear();
  }
}
