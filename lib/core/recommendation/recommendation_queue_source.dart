import 'dart:async';

import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/recommendation/recommendation_reporter.dart';

class RecommendationFeedbackContext {
  const RecommendationFeedbackContext({
    required this.song,
    required this.remainSongCount,
    required this.position,
  });

  final Song song;
  final int remainSongCount;
  final Duration position;
}

abstract interface class RecommendationFeedbackSource {
  RecommendationKind get kind;
  void reportSkip(RecommendationFeedbackContext context);
  void reportDislike(RecommendationFeedbackContext context);
}

class RecommendationQueueSource
    implements PlaybackQueueSource, RecommendationFeedbackSource {
  RecommendationQueueSource(this._sdk, this._reporter, {required this.kind});

  @override
  final RecommendationKind kind;
  final RecommendationSdk _sdk;
  final RecommendationReporter _reporter;
  Future<void> _operationTail = Future<void>.value();
  String? _markList;
  String? _currentMark;
  List<int> _heartMixIds = const [];
  final List<Song> _pending = [];

  Future<RecommendationBatch> start() async {
    final batch = await _serialized(() => _fetch());
    return RecommendationBatch(
      title: batch.title,
      subtitle: batch.subtitle,
      markList: batch.markList,
      mark: batch.mark,
      songs: _filterNew(batch.songs, const []),
    );
  }

  @override
  Future<PlaybackQueuePage> loadPage(PlaybackQueueLoadRequest request) async {
    final pending = _takePending(request);
    if (pending.isNotEmpty) {
      return PlaybackQueuePage(
        page: request.page,
        pageSize: pending.length,
        songs: pending,
        hasMore: true,
      );
    }

    var unique = <Song>[];
    for (var attempt = 0; attempt < 2 && unique.isEmpty; attempt += 1) {
      final batch = await _serialized(
        () => _fetch(
          currentSong: request.currentSong,
          remainSongCount: request.remainingCount,
          playtimeSecs: request.position.inSeconds,
          fallbackHeartSongs: request.songs,
        ),
      );
      unique = _filterNew(
        batch.songs,
        request.songs,
        reportRemainCount: request.remainingCount,
      );
    }
    return PlaybackQueuePage(
      page: request.page,
      pageSize: unique.isEmpty ? 1 : unique.length,
      songs: unique,
      hasMore: unique.isNotEmpty,
    );
  }

  @override
  void reportSkip(RecommendationFeedbackContext context) {
    if (kind != RecommendationKind.personalFm) return;
    _runFeedback('跳过', PersonalFmAction.skip, context);
  }

  @override
  void reportDislike(RecommendationFeedbackContext context) {
    _reporter.reportTrash(context.song);
    if (kind != RecommendationKind.personalFm) return;
    _runFeedback('不感兴趣', PersonalFmAction.garbage, context);
  }

  void _runFeedback(
    String label,
    PersonalFmAction action,
    RecommendationFeedbackContext context,
  ) {
    unawaited(
      _serialized(
            () => _fetch(
              action: action,
              currentSong: context.song,
              remainSongCount: context.remainSongCount,
              playtimeSecs: context.position.inSeconds,
            ),
          )
          .then((batch) {
            _pending.addAll(
              _filterNew(batch.songs, _pending, reportRepeated: false),
            );
          })
          .catchError((Object error) {
            _reporter.reportError(label, error);
          }),
    );
  }

  Future<RecommendationBatch> _fetch({
    PersonalFmAction action = PersonalFmAction.play,
    Song? currentSong,
    int remainSongCount = 0,
    int? playtimeSecs,
    List<Song> fallbackHeartSongs = const [],
  }) async {
    final batch = switch (kind) {
      RecommendationKind.personalFm => _sdk.personalFm(
        PersonalFmInput(
          action: action,
          currentSong: currentSong,
          remainSongCount: remainSongCount,
          playtimeSecs: playtimeSecs,
          markList: _markList,
          currentMark: _currentMark,
        ),
      ),
      RecommendationKind.heartRadio => _sdk.heartRadio(
        currentMixSongIds: _heartMixIds.isNotEmpty
            ? _heartMixIds
            : fallbackHeartSongs
                  .map((song) => song.mixSongId)
                  .whereType<int>()
                  .toList(growable: false),
      ),
    };
    final value = await batch;
    if (value.markList?.trim().isNotEmpty == true) {
      _markList = value.markList;
    }
    if (value.mark?.trim().isNotEmpty == true) {
      _currentMark = value.mark;
    }
    if (kind == RecommendationKind.heartRadio) {
      _heartMixIds = value.songs
          .map((song) => song.mixSongId)
          .whereType<int>()
          .toList(growable: false);
    }
    return value;
  }

  List<Song> _takePending(PlaybackQueueLoadRequest request) {
    if (_pending.isEmpty) return const [];
    final result = _filterNew(
      List<Song>.of(_pending),
      request.songs,
      reportRemainCount: request.remainingCount,
    );
    _pending.clear();
    return result;
  }

  List<Song> _filterNew(
    List<Song> incoming,
    List<Song> existing, {
    int? reportRemainCount,
    bool reportRepeated = true,
  }) {
    final knownIds = existing.map((song) => song.id).toSet();
    final knownHashes = existing
        .map((song) => song.hashes.standard?.trim().toLowerCase())
        .whereType<String>()
        .where((hash) => hash.isNotEmpty)
        .toSet();
    final duplicateHashes = <String>[];
    final unique = <Song>[];
    for (final song in incoming) {
      final hash = song.hashes.standard?.trim();
      final normalizedHash = hash?.toLowerCase();
      final duplicate =
          knownIds.contains(song.id) ||
          (normalizedHash != null &&
              normalizedHash.isNotEmpty &&
              knownHashes.contains(normalizedHash));
      if (!duplicate) {
        knownIds.add(song.id);
        if (normalizedHash != null && normalizedHash.isNotEmpty) {
          knownHashes.add(normalizedHash);
        }
        unique.add(song);
      } else {
        if (hash != null && hash.isNotEmpty) duplicateHashes.add(hash);
      }
    }
    if (reportRepeated) {
      _reporter.reportRepeated(
        duplicateHashes,
        remainSongCount: (reportRemainCount ?? 0) + unique.length,
      );
    }
    return unique;
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _operationTail = _operationTail.catchError((_) {}).then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
