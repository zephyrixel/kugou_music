import 'dart:async';
import 'dart:collection';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/recommendation.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/recommendation/recommendation_playback.dart';
import 'package:kgmusic/core/recommendation/recommendation_profile_store.dart';
import 'package:kgmusic/core/recommendation/recommendation_queue_source.dart';
import 'package:kgmusic/core/recommendation/recommendation_reporter.dart';
import 'package:kgmusic/core/widgets/app_error_bus.dart';

void main() {
  late AppDatabase database;
  late RecommendationProfileStore profileStore;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    profileStore = RecommendationProfileStore(database);
  });

  tearDown(() => database.close());

  RecommendationReporter reporter(
    _FakeMusicSdk sdk, {
    AppErrorBus? errors,
    DateTime Function()? now,
    int Function()? jitterSeconds,
  }) {
    final value = RecommendationReporter(
      sdk,
      profileStore,
      errors ?? AppErrorBus(),
      now: now,
      jitterSeconds: jitterSeconds,
    );
    value.activate(7);
    return value;
  }

  test('推荐入口创建有明确来源且可继续加载的播放队列', () async {
    final sdk = _FakeMusicSdk()
      ..personalBatches.add(
        const RecommendationBatch(title: '猜你喜欢', songs: [songA, songB]),
      );
    final playback = RecommendationPlayback(sdk, reporter(sdk));

    final request = await playback.start(RecommendationKind.personalFm);

    expect(request.origin.kind, PlaybackQueueOriginKind.personalFm);
    expect(request.origin.profileSourceBits, 128);
    expect(request.origin.displayTitle, '猜你喜欢');
    expect(request.songs, [songA, songB]);
    expect(request.source, isA<RecommendationQueueSource>());
    expect(request.hasMore, isTrue);
  });

  test('猜你喜欢续拉回显会话字段并仅在成功响应后交付同步点', () async {
    final sdk = _FakeMusicSdk()
      ..personalBatches.addAll([
        const RecommendationBatch(
          title: '猜你喜欢',
          markList: 'mark-1',
          mark: 'current-1',
          songs: [songA, songB],
        ),
        const RecommendationBatch(
          title: '猜你喜欢',
          markList: 'mark-2',
          syncNeed: 1,
          syncPoint: 3,
          songs: [songB, songC],
        ),
      ]);
    final value = reporter(sdk);
    final source = RecommendationQueueSource(
      sdk,
      value,
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
    await value.flush();

    expect(first.songs, [songA, songB]);
    expect(page.songs, [songC]);
    expect(sdk.personalInputs.last.currentSong, songA);
    expect(sdk.personalInputs.last.remainSongCount, 1);
    expect(sdk.personalInputs.last.playtimeSecs, 37);
    expect(sdk.personalInputs.last.markList, 'mark-1');
    expect(sdk.personalInputs.last.currentMark, 'current-1');
    expect(sdk.repeatedReports.single.hashes, [songB.hashes.standard]);
    expect(sdk.historyReports, isEmpty);
  });

  test('红心电台续拉回传 mixSongId 且不触发 FM 画像同步', () async {
    final sdk = _FakeMusicSdk()
      ..heartBatches.addAll([
        const RecommendationBatch(title: '红心电台', songs: [songA, songB]),
        const RecommendationBatch(title: '红心电台', songs: [songC]),
      ]);
    final value = reporter(sdk);
    final source = RecommendationQueueSource(
      sdk,
      value,
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
    await value.flush();

    expect(sdk.heartMixIds, [
      const [],
      [11, 12],
    ]);
    expect(sdk.historyReports, isEmpty);
  });

  test('收藏点击反馈独立于 report_history', () async {
    final sdk = _FakeMusicSdk();
    final value = reporter(sdk);

    value.reportFavoriteChanged(songA, liked: true);
    value.reportFavoriteChanged(songB, liked: false);
    await value.flush();

    expect(sdk.favoriteClicks, [songA]);
    expect(sdk.historyReports, isEmpty);
  });

  test('普通播放只落本地，只有 sync_need=1 才同步画像', () async {
    final sdk = _FakeMusicSdk();
    final value = reporter(sdk, jitterSeconds: () => 0);
    await value.recordPlayback(
      songA,
      listened: const Duration(seconds: 121),
      sourceBits: 1,
    );

    value.onPersonalFmSuccess(syncNeed: null, syncPoint: null);
    value.onPersonalFmSuccess(syncNeed: 0, syncPoint: 2);
    await value.flush();
    expect(sdk.historyReports, isEmpty);

    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
    await value.flush();
    final report = sdk.historyReports.single;
    expect(report.complete, isTrue);
    expect(report.previousSyncPoint, 0);
    expect(
      report.items.single.action,
      RecommendationProfileAction.playComplete,
    );
    expect(report.items.single.sourceBits, 1);
  });

  test('同步按成功次数冷却并在自然日重置', () async {
    var now = DateTime(2026, 7, 18, 9);
    final sdk = _FakeMusicSdk();
    final value = reporter(sdk, now: () => now, jitterSeconds: () => 0);
    await value.recordPlayback(
      songA,
      listened: const Duration(seconds: 20),
      sourceBits: 8,
    );

    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
    await value.flush();
    // The first successful sync has only the random jitter cooldown. With a
    // zero-jitter test clock, the next trigger can run immediately.
    now = now.add(const Duration(seconds: 1));
    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
    await value.flush();
    expect(sdk.historyReports, hasLength(2));

    // The second sync uses the previous successful count (1), hence a
    // five-minute cooldown.
    now = now.add(const Duration(minutes: 4, seconds: 59));
    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
    await value.flush();
    expect(sdk.historyReports, hasLength(2));

    now = now.add(const Duration(seconds: 2));
    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
    await value.flush();
    expect(sdk.historyReports, hasLength(3));

    now = DateTime(2026, 7, 19, 0, 1);
    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
    await value.flush();
    expect(sdk.historyReports, hasLength(4));
  });

  test('自然日内最多完成五次画像同步', () async {
    var now = DateTime(2026, 7, 18, 0, 1);
    final sdk = _FakeMusicSdk();
    final value = reporter(sdk, now: () => now, jitterSeconds: () => 0);
    await value.recordPlayback(
      songA,
      listened: const Duration(seconds: 10),
      sourceBits: 1,
    );

    for (var index = 0; index < 6; index += 1) {
      value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
      await value.flush();
      now = now.add(const Duration(hours: 1));
    }

    expect(sdk.historyReports, hasLength(5));
  });

  test('FM 触发可等待完整收藏索引后继续同步', () async {
    final library = LibraryStore(database);
    await library.replaceLibrary(
      userId: 7,
      playlists: const [
        Playlist(
          localId: 'remote:2',
          listId: 2,
          name: '我喜欢',
          count: 1,
          isPrivate: false,
          isMyFavorite: true,
          isDefaultCollect: false,
        ),
      ],
      history: const [],
    );
    final sdk = _FakeMusicSdk();
    final value = reporter(sdk, jitterSeconds: () => 0);
    await value.recordPlayback(
      songA,
      listened: const Duration(seconds: 10),
      sourceBits: 1,
    );

    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
    await value.flush();
    expect(sdk.historyReports, isEmpty);

    await library.replacePlaylistTracksAtomic('remote:2', const [
      songB,
    ], remoteTotalCount: 1);
    value.notifyProfileReady();
    await value.flush();
    expect(sdk.historyReports.single.items, hasLength(2));
  });

  test('401 条画像按官方游标拆成 400 + 1 两包并反序', () async {
    var now = DateTime(2026, 7, 18, 8);
    final sdk = _FakeMusicSdk();
    final value = reporter(sdk, now: () => now, jitterSeconds: () => 0);
    for (var index = 0; index < 401; index += 1) {
      await value.recordPlayback(
        Song(
          id: 'song-$index',
          title: 'Song $index',
          hashes: AudioHashes(standard: 'hash-$index'),
        ),
        listened: const Duration(seconds: 10),
        sourceBits: 1,
      );
      now = now.add(const Duration(milliseconds: 1));
    }

    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
    await value.flush();

    expect(sdk.historyReports, hasLength(2));
    final first = sdk.historyReports.first;
    final second = sdk.historyReports.last;
    expect(first.items, hasLength(400));
    expect(first.complete, isFalse);
    expect(first.previousSyncPoint, 0);
    expect(first.items.first.standardHash, 'hash-1');
    expect(first.items.last.standardHash, 'hash-400');
    expect(second.items, hasLength(1));
    expect(second.complete, isTrue);
    expect(second.previousSyncPoint, first.nextSyncPoint);
    expect(second.lastUploadHash, 'hash-400');
  });

  test('report 失败通过全局错误总线暴露且不计成功次数', () async {
    final sdk = _FakeMusicSdk()..reportError = StateError('network down');
    final errors = AppErrorBus();
    final value = reporter(sdk, errors: errors, jitterSeconds: () => 0);
    final nextMessage = errors.messages.first;
    await value.recordPlayback(
      songA,
      listened: const Duration(seconds: 10),
      sourceBits: 1,
    );

    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);

    expect(await nextMessage, '推荐反馈暂未同步，不影响继续播放');
    await value.flush();
    sdk.reportError = null;
    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
    await value.flush();
    expect(sdk.historyReports, hasLength(1));
  });

  test('账号切换不会丢掉新账号等待中的画像同步', () async {
    final sdk = _FakeMusicSdk();
    final value = reporter(sdk, jitterSeconds: () => 0);
    await value.recordPlayback(
      songA,
      listened: const Duration(seconds: 10),
      sourceBits: 1,
    );
    final gate = Completer<void>();
    final started = Completer<void>();
    sdk.reportGate = gate;
    sdk.reportStarted = started;

    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
    await started.future;
    await value.deactivate();
    value.activate(8);
    await value.recordPlayback(
      songB,
      listened: const Duration(seconds: 10),
      sourceBits: 128,
    );
    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);

    gate.complete();
    await value.flush();

    expect(sdk.historyReports, hasLength(2));
    expect(
      sdk.historyReports.last.items.single.standardHash,
      songB.hashes.standard,
    );
  });

  test('上传期间新的猜你喜欢响应会保留下一次画像同步', () async {
    final sdk = _FakeMusicSdk();
    final value = reporter(sdk, jitterSeconds: () => 0);
    await value.recordPlayback(
      songA,
      listened: const Duration(seconds: 10),
      sourceBits: 1,
    );

    final gate = Completer<void>();
    final started = Completer<void>();
    sdk.reportGate = gate;
    sdk.reportStarted = started;
    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
    await started.future;

    await value.recordPlayback(
      songB,
      listened: const Duration(seconds: 10),
      sourceBits: 128,
    );
    value.onPersonalFmSuccess(syncNeed: 1, syncPoint: 0);
    gate.complete();
    await value.flush();

    expect(sdk.historyReports, hasLength(2));
    expect(sdk.historyReports.first.items.single.standardHash, 'ha');
    expect(
      sdk.historyReports.last.items.map((item) => item.standardHash),
      contains('hb'),
    );
  });

  testWidgets('全局错误监听器使用通用错误提示展示 report 失败', (tester) async {
    final errors = AppErrorBus();
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: messengerKey,
        builder: (context, child) => AppErrorListener(
          bus: errors,
          messengerKey: messengerKey,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: Text('home')),
      ),
    );

    errors.add('推荐反馈暂未同步，不影响继续播放');
    await tester.pump();

    expect(find.text('推荐反馈暂未同步，不影响继续播放'), findsOneWidget);
    expect(find.textContaining('network down'), findsNothing);
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

class _HistoryReport {
  const _HistoryReport({
    required this.items,
    required this.complete,
    required this.previousSyncPoint,
    required this.nextSyncPoint,
    this.lastUploadHash,
  });

  final List<RecommendationProfileItem> items;
  final bool complete;
  final int previousSyncPoint;
  final int nextSyncPoint;
  final String? lastUploadHash;
}

class _FakeMusicSdk implements RecommendationSdk {
  final Queue<RecommendationBatch> personalBatches = Queue();
  final Queue<RecommendationBatch> heartBatches = Queue();
  final List<PersonalFmInput> personalInputs = [];
  final List<List<int>> heartMixIds = [];
  final List<_HistoryReport> historyReports = [];
  final List<_RepeatedReport> repeatedReports = [];
  final List<Song> favoriteClicks = [];
  Object? reportError;
  Completer<void>? reportGate;
  Completer<void>? reportStarted;

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
  Future<RecommendationReportAck> reportRecommendationHistory(
    List<RecommendationProfileItem> items, {
    required bool complete,
    required int previousSyncPoint,
    required int nextSyncPoint,
    String? lastUploadHash,
  }) async {
    if (reportError case final error?) throw error;
    reportStarted?.complete();
    reportStarted = null;
    final gate = reportGate;
    reportGate = null;
    if (gate != null) await gate.future;
    historyReports.add(
      _HistoryReport(
        items: List.of(items),
        complete: complete,
        previousSyncPoint: previousSyncPoint,
        nextSyncPoint: nextSyncPoint,
        lastUploadHash: lastUploadHash,
      ),
    );
    return const RecommendationReportAck();
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
