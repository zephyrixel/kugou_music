import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';
import 'package:kgmusic/features/home/discover_sections.dart';
import 'package:kgmusic/features/playlists/playlist_header.dart';

void main() {
  const song = Song(
    id: 'song:responsive',
    title: '一首标题非常长但仍然需要正确省略而不能挤压操作按钮的歌曲',
    artist: '歌手名称同样很长',
    album: '测试专辑',
    durationSecs: 245,
    hashes: AudioHashes(standard: 'hash'),
  );

  testWidgets('发现页 Hero 在窄屏和减少动画模式下不会溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _testApp(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            disableAnimations: true,
          ),
          child: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(12),
              child: DailyRecommendationHero(
                songs: [song],
                loading: false,
                onPlay: null,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('今天的声音'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('歌单沉浸式头部在手机和大屏宽度下保持可读', (tester) async {
    for (final width in [360.0, 900.0]) {
      await tester.binding.setSurfaceSize(Size(width, 640));
      await tester.pumpWidget(
        _testApp(
          const Scaffold(
            body: SizedBox(
              height: 310,
              child: PlaylistHeader(
                title: '标题很长的测试歌单，用于验证窄屏排版不会发生溢出',
                subtitle: '测试创建者',
                description: '这是歌单简介，允许显示两行并在空间不足时正确省略。',
                artwork: null,
                cacheId: 'playlist:test',
                count: 999,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('歌曲行优先保留标题空间并维持触控高度', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 160));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _testApp(
        Scaffold(
          body: SongTile(
            song: song,
            variant: SongTileVariant.artwork,
            onTap: () {},
            trailing: const SizedBox.square(
              dimension: 40,
              child: Icon(Icons.more_vert_rounded),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(ListTile)).height,
      greaterThanOrEqualTo(68),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('减少动画设置会关闭设计系统动效', (tester) async {
    Duration? resolved;
    await tester.pumpWidget(
      _testApp(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              resolved = KgMotion.resolve(context, KgMotion.slow);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(resolved, Duration.zero);
  });
}

Widget _testApp(Widget child) =>
    MaterialApp(theme: buildKgTheme(), home: child);
