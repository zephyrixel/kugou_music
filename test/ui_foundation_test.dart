import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/app/animated_branch_container.dart';
import 'package:kgmusic/app/delegated_transition_page.dart';
import 'package:kgmusic/app/navigation_focus_policy.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/artwork_backdrop.dart';
import 'package:kgmusic/core/widgets/kg_marquee_text.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
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

  testWidgets('首页长用户名不会挤压核心问候标题', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: _testApp(
          const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: DiscoverHeader(name: '这是一个非常非常长的用户昵称用于验证窄屏布局'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('今天想听什么？'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('滚动文本只在溢出时创建无缝循环内容', (tester) async {
    await tester.binding.setSurfaceSize(const Size(180, 80));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const longText = '这是一段需要无缝循环展示的超长歌曲标题';

    await tester.pumpWidget(
      _testApp(
        const Scaffold(
          body: Center(
            child: SizedBox(
              width: 100,
              child: KgMarqueeText(longText, startDelay: Duration.zero),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    final before = tester.getTopLeft(find.text(longText).first).dx;
    await tester.pump(const Duration(milliseconds: 300));
    final after = tester.getTopLeft(find.text(longText).first).dx;

    expect(find.text(longText), findsNWidgets(2));
    expect(after, lessThan(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('减少动画模式下滚动文本退化为单份静态文本', (tester) async {
    const longText = '这是一段在减少动画模式下保持静态的超长歌曲标题';
    await tester.pumpWidget(
      _testApp(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: SizedBox(width: 100, child: KgMarqueeText(longText)),
            ),
          ),
        ),
      ),
    );

    expect(find.text(longText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('未溢出的滚动文本只渲染一份内容', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const Scaffold(body: SizedBox(width: 240, child: KgMarqueeText('短标题'))),
      ),
    );

    expect(find.text('短标题'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('氛围背景保留标准高斯模糊并限制源纹理尺寸', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const SizedBox.expand(
          child: ArtworkBackdrop(url: null, cacheId: 'performance-test'),
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(
      tester.widget<SongArtwork>(find.byType(SongArtwork)).decodePixelSize,
      320,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('播放器进入时下层页面连续淡出而不是在结尾突变', (tester) async {
    const homeKey = ValueKey('transition-home');
    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) => Scaffold(
            key: homeKey,
            backgroundColor: Colors.red,
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  const PlayerTransitionPage<void>(
                    child: Scaffold(body: ColoredBox(color: Colors.blue)),
                  ).createRoute(context),
                ),
                child: const Text('打开播放器'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开播放器'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final firstOpacity = _lowestFadeOpacity(tester, homeKey);
    expect(
      tester
          .widgetList<SnapshotWidget>(find.byType(SnapshotWidget))
          .any((widget) => widget.controller.allowSnapshotting),
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 100));
    final secondOpacity = _lowestFadeOpacity(tester, homeKey);

    expect(firstOpacity, inExclusiveRange(0, 1));
    expect(secondOpacity, lessThan(firstOpacity));
    await tester.pumpAndSettle();
    expect(find.byKey(homeKey), findsNothing);
    expect(
      tester
          .widgetList<SnapshotWidget>(find.byType(SnapshotWidget))
          .every((widget) => !widget.controller.allowSnapshotting),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('透明底栏后的动态尾部留白允许内容完整滑出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const contentKey = ValueKey('last-scroll-content');

    await tester.pumpWidget(
      _testApp(
        Scaffold(
          extendBody: true,
          body: Builder(
            builder: (context) => CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 700)),
                const SliverToBoxAdapter(
                  child: SizedBox(key: contentKey, height: 50),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.paddingOf(context).bottom),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const SizedBox(height: 146),
        ),
      ),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(
      tester.getBottomRight(find.byKey(contentKey)).dy,
      lessThanOrEqualTo(500),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('底栏切页保留分支并执行方向一致的淡入滑动', (tester) async {
    Widget branches(int index) => _testApp(
      AnimatedBranchContainer(
        currentIndex: index,
        children: const [
          ColoredBox(
            color: Colors.red,
            child: Center(child: Text('发现页')),
          ),
          ColoredBox(
            color: Colors.blue,
            child: Center(child: Text('搜索页')),
          ),
        ],
      ),
    );

    await tester.pumpWidget(branches(0));
    final inactiveStart = tester.getCenter(find.text('搜索页')).dx;
    await tester.pumpWidget(branches(1));
    await tester.pump(const Duration(milliseconds: 100));
    final incomingMidpoint = tester.getCenter(find.text('搜索页')).dx;

    expect(find.text('发现页'), findsOneWidget);
    expect(find.text('搜索页'), findsOneWidget);
    expect(incomingMidpoint, lessThan(inactiveStart));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('持久化分支失活时会释放其输入焦点', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    Widget branches(int index) => _testApp(
      AnimatedBranchContainer(
        currentIndex: index,
        children: [
          Material(child: TextField(focusNode: focusNode)),
          const ColoredBox(color: Colors.blue),
        ],
      ),
    );

    await tester.pumpWidget(branches(0));
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.pumpWidget(branches(1));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('页面导航后返回不会恢复旧输入框焦点', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    late BuildContext navigationContext;
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [KeyboardDismissNavigatorObserver()],
        home: Builder(
          builder: (context) {
            navigationContext = context;
            return Scaffold(body: TextField(focusNode: focusNode));
          },
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    Navigator.of(
      navigationContext,
    ).push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
    await tester.pumpAndSettle();
    Navigator.of(navigationContext).pop();
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);
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

double _lowestFadeOpacity(WidgetTester tester, Key childKey) => tester
    .widgetList<FadeTransition>(
      find.ancestor(
        of: find.byKey(childKey),
        matching: find.byType(FadeTransition),
      ),
    )
    .map((transition) => transition.opacity.value)
    .reduce((left, right) => left < right ? left : right);
