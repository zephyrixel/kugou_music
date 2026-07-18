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

enum PersonalFmAction { play, garbage }

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
    this.syncNeed,
    this.syncPoint,
  });

  final String title;
  final String? subtitle;
  final String? markList;
  final String? mark;
  final int? syncNeed;
  final int? syncPoint;
  final List<Song> songs;
}

class RecommendationReportAck {
  const RecommendationReportAck({this.syncPoint, this.isClean});

  final int? syncPoint;
  final bool? isClean;
}

enum RecommendationProfileAction {
  collect(1),
  playComplete(3),
  playShort(4),
  trash(5);

  const RecommendationProfileAction(this.wireValue);
  final int wireValue;
}

class RecommendationProfileItem {
  static const myFavoriteFlag = 32;

  const RecommendationProfileItem({
    required this.action,
    required this.eventTimeMs,
    required this.count,
    required this.sourceBits,
    this.flagBits = 0,
    this.standardHash,
    this.mixSongId,
  });

  final RecommendationProfileAction action;
  final String? standardHash;
  final int? mixSongId;
  final int eventTimeMs;
  final int count;
  final int flagBits;
  final int sourceBits;

  bool get hasIdentity =>
      standardHash?.trim().isNotEmpty == true || mixSongId != null;
}
