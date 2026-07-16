import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/recommendation/recommendation_queue_source.dart';
import 'package:kgmusic/core/recommendation/recommendation_reporter.dart';
import 'package:kgmusic/core/recommendation/recommendation_playback.dart';
import 'package:kgmusic/core/widgets/app_error_bus.dart';

void main() {
  test('推荐入口创建有明确来源且可继续加载的播放队列', () async {
    final sdk = _FakeMusicSdk()
      ..personalBatches.add(
        const RecommendationBatch(title: '猜你喜欢', songs: [songA, songB]),
      );
    final playback = RecommendationPlayback(
      sdk,
      RecommendationReporter(sdk, AppErrorBus()),
    );

    final request = await playback.start(RecommendationKind.personalFm);

    expect(request.origin.kind, PlaybackQueueOriginKind.personalFm);
    expect(request.origin.displayTitle, '猜你喜欢');
    expect(request.songs, [songA, songB]);
    expect(request.source, isA<RecommendationQueueSource>());
    expect(request.hasMore, isTrue);
  });

  test('猜你喜欢续拉会回显 mark、当前曲、剩余数量与播放时间', () async {
    final sdk = _FakeMusicSdk()
      ..personalBatches.addAll([
        const RecommendationBatch(
          title: '猜你喜欢',
          markList: 'mark-1',
          songs: [songA, songB],
        ),
        const RecommendationBatch(
          title: '猜你喜欢',
          markList: 'mark-2',
          songs: [songB, songC],
        ),
      ]);
    final reporter = RecommendationReporter(sdk, AppErrorBus());
    final source = RecommendationQueueSource(
      sdk,
      reporter,
      kind: RecommendationKind.personalFm,
    );

    final first = await source.start();
    final page = await source.loadPage(
      const PlaybackQueueLoadRequest(
        page: 2,
        currentIndex: 0,
        songs: [songA, songB],
        position: Duration(seconds: 37),
      ),
    );
    await reporter.flush();

    expect(first.songs, [songA, songB]);
    expect(page.songs, [songC]);
    expect(page.hasMore, isTrue);
    expect(sdk.personalInputs.last.currentSong, songA);
    expect(sdk.personalInputs.last.remainSongCount, 1);
    expect(sdk.personalInputs.last.playtimeSecs, 37);
    expect(sdk.personalInputs.last.markList, 'mark-1');
    expect(sdk.repeatedReports.single.hashes, [songB.hashes.standard]);
  });

  test('红心电台续拉会回传上一批 mixSongId', () async {
    final sdk = _FakeMusicSdk()
      ..heartBatches.addAll([
        const RecommendationBatch(title: '红心电台', songs: [songA, songB]),
        const RecommendationBatch(title: '红心电台', songs: [songC]),
      ]);
    final source = RecommendationQueueSource(
      sdk,
      RecommendationReporter(sdk, AppErrorBus()),
      kind: RecommendationKind.heartRadio,
    );

    await source.start();
    await source.loadPage(
      const PlaybackQueueLoadRequest(
        page: 2,
        currentIndex: 1,
        songs: [songA, songB],
        position: Duration.zero,
      ),
    );

    expect(sdk.heartMixIds, [
      const [],
      [11, 12],
    ]);
  });

  test('收藏反馈区分新增收藏与取消收藏', () async {
    final sdk = _FakeMusicSdk();
    final reporter = RecommendationReporter(sdk, AppErrorBus());

    reporter.reportFavoriteChanged(songA, liked: true);
    reporter.reportFavoriteChanged(songB, liked: false);
    await reporter.flush();

    expect(sdk.historyReports, hasLength(1));
    expect(
      sdk.historyReports.single.single.action,
      RecommendationHistoryAction.collect,
    );
    expect(sdk.favoriteClicks, [songA, songB]);
  });

  test('report 失败通过全局错误总线暴露', () async {
    final sdk = _FakeMusicSdk()..reportError = StateError('network down');
    final errors = AppErrorBus();
    final reporter = RecommendationReporter(sdk, errors);
    final nextError = errors.errors.first;

    reporter.reportPlayed(songA);

    expect(await nextError, contains('推荐播放记录上报失败'));
    await reporter.flush();
  });

  testWidgets('全局错误监听器使用通用错误提示展示 report 失败', (tester) async {
    final errors = AppErrorBus();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppErrorListener(
          bus: errors,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: Text('home')),
      ),
    );

    errors.add('推荐播放记录上报失败：network down');
    await tester.pump();

    expect(find.text('推荐播放记录上报失败：network down'), findsOneWidget);
  });
}

const songA = Song(
  id: 'a',
  title: 'A',
  mixSongId: 11,
  hashes: AudioHashes(standard: 'ha'),
);
const songB = Song(
  id: 'b',
  title: 'B',
  mixSongId: 12,
  hashes: AudioHashes(standard: 'hb'),
);
const songC = Song(
  id: 'c',
  title: 'C',
  mixSongId: 13,
  hashes: AudioHashes(standard: 'hc'),
);

class _RepeatedReport {
  const _RepeatedReport(this.hashes, this.remainSongCount);

  final List<String> hashes;
  final int remainSongCount;
}

class _FakeMusicSdk implements RecommendationSdk {
  final Queue<RecommendationBatch> personalBatches = Queue();
  final Queue<RecommendationBatch> heartBatches = Queue();
  final List<PersonalFmInput> personalInputs = [];
  final List<List<int>> heartMixIds = [];
  final List<List<RecommendationHistoryEvent>> historyReports = [];
  final List<_RepeatedReport> repeatedReports = [];
  final List<Song> favoriteClicks = [];
  Object? reportError;

  @override
  Future<RecommendationBatch> personalFm(PersonalFmInput input) async {
    personalInputs.add(input);
    return personalBatches.removeFirst();
  }

  @override
  Future<RecommendationBatch> heartRadio({
    List<int> currentMixSongIds = const [],
  }) async {
    heartMixIds.add(List.of(currentMixSongIds));
    return heartBatches.removeFirst();
  }

  @override
  Future<void> reportRecommendationHistory(
    List<RecommendationHistoryEvent> items,
  ) async {
    if (reportError case final error?) throw error;
    historyReports.add(List.of(items));
  }

  @override
  Future<void> reportRecommendationRepeated(
    List<String> hashes, {
    required int remainSongCount,
  }) async {
    repeatedReports.add(_RepeatedReport(List.of(hashes), remainSongCount));
  }

  @override
  Future<void> reportRecommendationFavoriteClick(Song song) async {
    favoriteClicks.add(song);
  }
}
