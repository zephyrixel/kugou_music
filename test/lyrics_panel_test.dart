import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/models/lyric.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/lyrics_sdk.dart';
import 'package:kgmusic/features/player/lyrics/lyrics_panel.dart';

void main() {
  const song = Song(
    id: 'mix:1',
    title: '测试',
    mixSongId: 1,
    hashes: AudioHashes(standard: 'hash'),
  );
  const document = LyricDocument(
    format: LyricFormat.krc,
    offsetMs: -100,
    lines: [
      LyricLine(startMs: 1000, durationMs: 500, text: '第一句'),
      LyricLine(startMs: 2000, durationMs: 500, text: '第二句'),
    ],
  );

  testWidgets('tapping a lyric line seeks to its adjusted start', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final positions = StreamController<Duration>.broadcast();
    addTearDown(positions.close);
    Duration? sought;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          lyricsSdkProvider.overrideWithValue(_StaticLyricsSdk(document)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: LyricsPanel(
                song: song,
                positionStream: positions.stream,
                onSeek: (position) async => sought = position,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('第二句'));
    await tester.pump();
    expect(sought, const Duration(milliseconds: 1900));
  });

  testWidgets('active lyric line stays at the viewport center', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final positions = StreamController<Duration>.broadcast();
    addTearDown(positions.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          lyricsSdkProvider.overrideWithValue(_StaticLyricsSdk(document)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: LyricsPanel(
                song: song,
                positionStream: positions.stream,
                onSeek: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    positions.add(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    final panelCenter = tester.getCenter(find.byType(LyricsPanel)).dy;
    final activeLineCenter = tester.getCenter(find.text('第二句')).dy;
    expect(activeLineCenter, closeTo(panelCenter, 1));
  });

  testWidgets('failed load exposes a retry action', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final remote = _RetryLyricsSdk(document);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          lyricsSdkProvider.overrideWithValue(remote),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 320,
              child: LyricsPanel(
                song: song,
                positionStream: const Stream.empty(),
                onSeek: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('歌词加载失败'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('第一句'), findsOneWidget);
    expect(remote.calls, 2);
  });
}

class _StaticLyricsSdk implements LyricsSdk {
  const _StaticLyricsSdk(this.document);
  final LyricDocument document;

  @override
  Future<LyricDocument?> fetchLyrics(Song song) async => document;
}

class _RetryLyricsSdk implements LyricsSdk {
  _RetryLyricsSdk(this.document);
  final LyricDocument document;
  int calls = 0;

  @override
  Future<LyricDocument?> fetchLyrics(Song song) async {
    calls += 1;
    if (calls == 1) throw StateError('offline');
    return document;
  }
}
