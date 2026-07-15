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
  });

  final PersonalFmAction action;
  final Song? currentSong;
  final int remainSongCount;
  final int? playtimeSecs;
  final String? markList;
}

class RecommendationBatch {
  const RecommendationBatch({
    required this.title,
    required this.songs,
    this.subtitle,
    this.markList,
  });

  final String title;
  final String? subtitle;
  final String? markList;
  final List<Song> songs;
}

enum RecommendationHistoryAction { play, collect, trash }

class RecommendationHistoryEvent {
  const RecommendationHistoryEvent({required this.action, required this.song});

  final RecommendationHistoryAction action;
  final Song song;
}
