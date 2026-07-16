import 'package:kgmusic/core/models/song.dart';

enum RecommendationKind { personalFm, heartRadio }

extension RecommendationKindInfo on RecommendationKind {
  String get title => switch (this) {
    RecommendationKind.personalFm => '猜你喜欢',
    RecommendationKind.heartRadio => '红心电台',
  };

  String get subtitle => switch (this) {
    RecommendationKind.personalFm => '根据最近的播放和收藏持续发现',
    RecommendationKind.heartRadio => '从偏爱的声音出发继续推荐',
  };
}

enum PersonalFmAction { play, skip, garbage }

class PersonalFmInput {
  const PersonalFmInput({
    this.action = PersonalFmAction.play,
    this.currentSong,
    this.remainSongCount = 0,
    this.playtimeSecs,
    this.markList,
    this.currentMark,
  });

  final PersonalFmAction action;
  final Song? currentSong;
  final int remainSongCount;
  final int? playtimeSecs;
  final String? markList;
  final String? currentMark;
}

class RecommendationBatch {
  const RecommendationBatch({
    required this.title,
    required this.songs,
    this.subtitle,
    this.markList,
    this.mark,
  });

  final String title;
  final String? subtitle;
  final String? markList;
  final String? mark;
  final List<Song> songs;
}

class RecommendationReportAck {
  const RecommendationReportAck({this.syncPoint, this.isClean});

  final int? syncPoint;
  final bool? isClean;
}

enum RecommendationHistoryAction { play, collect, trash }

class RecommendationHistoryEvent {
  const RecommendationHistoryEvent({required this.action, required this.song});

  final RecommendationHistoryAction action;
  final Song song;
}
