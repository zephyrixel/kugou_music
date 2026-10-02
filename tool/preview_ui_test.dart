// Explicit visual review tool: flutter test tool/preview_ui_test.dart
// Writes screenshots, never compares them against a pixel-locked baseline.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_choice_tabs.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/kg_motion.dart';
import 'package:kgmusic/features/player/mini_player.dart';
import 'package:kgmusic/features/player/player_screen.dart';

import '../test/support/ui_app_harness.dart';

void main() {
  testWidgets('render UI review with sample data', (tester) async {
    final disableShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      const outputPath = String.fromEnvironment(
        'UI_REVIEW_DIR',
        defaultValue: 'build/ui-review',
      );
      const artworkPath = String.fromEnvironment(
        'UI_ARTWORK_DIR',
        defaultValue: 'build/ui-review/artwork',
      );
      const fontPath = String.fromEnvironment(
        'UI_FONT',
        defaultValue: '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
      );
      final output = Directory(outputPath).absolute;
      await tester.runAsync(() async {
        await output.create(recursive: true);
        final font = File(fontPath);
        if (await font.exists()) {
          final bytes = await font.readAsBytes();
          for (final family in ['ReviewFont']) {
            await (FontLoader(
              family,
            )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
          }
        }
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      final covers = ['forest', 'sea', 'mountain'].map((name) {
        final file = File('$artworkPath/$name.jpg').absolute;
        return file.existsSync() ? file.uri.toString() : null;
      }).toList();
      const titles = [
        '山海之间',
        '海风吹过的夏天',
        '在夜色里',
        '慢慢',
        '沿海公路',
        '晚风',
        '城市的另一面',
        '温柔的回声',
        '日落以后',
      ];
      final songs = List.generate(
        titles.length,
        (index) => Song(
          id: 'preview-$index',
          title: titles[index],
          artist: ['陈屿', '林间回声', '白日漫游'][index % 3],
          album: '沿途的风景',
          artworkUrl: covers[index % 3],
          durationSecs: 240,
          hashes: AudioHashes(standard: 'preview-$index'),
        ),
      );
      final playlists = List.generate(
        4,
        (index) => Playlist(
          name: ['适合散步的声音', '夜晚的独处时间', '沿海公路', '周末慢慢听'][index],
          localId: 'preview-list-$index',
          isPrivate: index == 1,
          isMyFavorite: false,
          isDefaultCollect: false,
          count: songs.length,
          creatorName: '听风',
          artworkUrl: covers[index % 3],
        ),
      );
      final playlist = PlaylistTarget.public(
        PlaylistSearchHit(
          name: '沿海公路',
          globalCollectionId: 'preview',
          creatorName: '听风',
          intro: '把步调放慢一点。收集适合散步、看海和独处时听的歌，让音乐陪伴沿途的风景。',
          artworkUrl: covers[1],
          songCount: songs.length,
        ),
      );
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const reviewLayout = String.fromEnvironment('UI_REVIEW_LAYOUT');

      for (final configuration in [
        (name: 'phone', size: const Size(390, 844), scale: 1.0),
        (name: 'narrow', size: const Size(320, 568), scale: 1.0),
        (name: 'narrow-large-text', size: const Size(320, 568), scale: 2.0),
        (name: 'large-text', size: const Size(390, 844), scale: 2.0),
        (name: 'landscape', size: const Size(844, 390), scale: 1.0),
        (name: 'desktop', size: const Size(1280, 800), scale: 1.0),
      ]) {
        if (reviewLayout.isNotEmpty && reviewLayout != configuration.name) {
          continue;
        }
        await tester.binding.setSurfaceSize(configuration.size);
        final harness = await UiAppHarness.create(
          songs: songs,
          playlists: playlists,
        );
        final canvas = GlobalKey();
        await tester.pumpWidget(
          harness.app(
            textScale: configuration.scale,
            theme: _reviewTheme(),
            builder: (context, child) =>
                RepaintBoundary(key: canvas, child: child),
          ),
        );

        Future<void> capture(String name) async {
          await tester.pumpAndSettle();
          // IO and image decode complete on the real clock; Image widgets then
          // consume their callbacks on the test clock. Alternate both until ready.
          for (var attempt = 0; attempt < 40; attempt++) {
            final pending = tester
                .widgetList<RawImage>(find.byType(RawImage))
                .any((image) => image.image == null);
            if (!pending) break;
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 50)),
            );
            await tester.pump(const Duration(milliseconds: 50));
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final boundary =
                canvas.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(
              pixelRatio: configuration.name == 'desktop' ? 1 : 2,
            );
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '${output.path}/${configuration.name}-$name.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await capture('home');
        if (configuration.name == 'phone') {
          await tester.drag(
            find.byType(CustomScrollView).first,
            const Offset(0, -900),
          );
          await capture('discovery');
        }
        harness.router.push<void>('/playlist', extra: playlist);
        await capture('playlist');
        if (configuration.name == 'phone' &&
            const bool.fromEnvironment('UI_MOTION')) {
          await tester.pumpWidget(
            harness.app(
              reduceMotion: false,
              theme: _reviewTheme(),
              builder: (context, child) =>
                  RepaintBoundary(key: canvas, child: child),
            ),
          );
          await tester.pumpAndSettle();
          final frames = Directory('${output.path}/motion');
          await tester.runAsync(() => frames.create(recursive: true));
          var frame = 0;
          Future<void> record(int count) async {
            for (var index = 0; index < count; index++) {
              await tester.pump(const Duration(milliseconds: 16));
              final target =
                  '${frames.path}/${(frame++).toString().padLeft(3, '0')}.png';
              await tester.runAsync(() async {
                final boundary =
                    canvas.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final image = await boundary.toImage(pixelRatio: 2);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(target).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
          }

          await record(12);
          await tester.tap(find.byKey(const ValueKey('mini-player-open')));
          await record(42);
          await tester.tap(find.byTooltip('收起播放器'));
          await record(36);
          await tester.tap(find.byTooltip('播放队列'));
          await record(28);
          Navigator.of(
            tester.element(find.text('播放队列')),
            rootNavigator: true,
          ).pop();
          await record(24);
          harness.router.push<void>('/account/settings');
          await record(28);
          harness.router.pop();
          await record(24);
          harness.router.go('/search');
          await record(24);
          await tester.tap(find.text('歌单'));
          await record(24);
          harness.router.go('/library');
          await record(24);
          await tester.tap(find.byTooltip('创建歌单'));
          await record(24);
          final press = await tester.startGesture(
            tester.getCenter(find.text('取消')),
          );
          await record(6);
          await press.up();
          await record(24);
          await tester.pumpAndSettle();
          await tester.pumpWidget(
            harness.app(
              theme: _reviewTheme(),
              builder: (context, child) =>
                  RepaintBoundary(key: canvas, child: child),
            ),
          );
          await tester.pumpAndSettle();
        }
        {
          await tester.tap(find.byTooltip('播放队列'));
          await capture('queue');
          Navigator.of(
            tester.element(find.text('播放队列')),
            rootNavigator: true,
          ).pop();
          await tester.pumpAndSettle();
        }
        harness.router.push<void>('/player');
        await capture('player');
        if (configuration.name == 'phone') {
          await tester.tap(find.text('歌词'));
          await capture('lyrics');
        }
        harness.router.go('/library');
        await capture('library');
        await Scrollable.ensureVisible(
          tester.element(find.byTooltip('创建歌单')),
          alignment: 0.25,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('创建歌单'));
        await capture('playlist-dialog');
        await tester.tap(find.text('创建').last);
        await capture('playlist-dialog-error');
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        harness.router.push<void>('/account/settings');
        await capture('settings');
        await tester.tap(find.text('默认播放音质'));
        await capture('quality');
        Navigator.of(
          tester.element(find.text('默认播放音质').last),
          rootNavigator: true,
        ).pop();
        await tester.pumpAndSettle();
        {
          harness.router.go('/search');
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), '海');
          await tester.pump(const Duration(milliseconds: 500));
          FocusManager.instance.primaryFocus?.unfocus();
          await capture('search');
          await tester.tap(find.text('歌单'));
          await capture('search-playlists');
          harness.router.push<void>('/account');
          await capture('account');
          harness.router.push<void>('/account/logs');
          await capture('logs');
          harness.auth.expire();
          await capture('login');
          if (configuration.name == 'phone') {
            final navigator = Navigator.of(
              tester.element(find.text('登录 KGMusic')),
              rootNavigator: true,
            );
            navigator.push<void>(
              MaterialPageRoute(builder: (_) => const _ComponentStates()),
            );
            await capture('components');
            navigator.pop();
            await tester.pumpAndSettle();
          }
        }
        // The reduced-motion path must leave neither a ghost full-screen player
        // nor an overlay intercepting routes once playback UI has been replaced.
        if (configuration.name == 'phone') {
          expect(find.byType(MiniPlayer), findsNothing);
          expect(find.byType(PlayerScreen), findsNothing);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await harness.dispose();
      }
    } finally {
      debugDisableShadows = disableShadows;
    }
  });
}

// Test bindings replace unspecified fonts with Ahem. Supply the review font to
// both content and component typography without changing the production theme.
ThemeData _reviewTheme() {
  final theme = buildKgTheme();
  TextStyle font(TextStyle? style) =>
      (style ?? const TextStyle()).copyWith(fontFamily: 'ReviewFont');
  ButtonStyle? button(ButtonStyle? style) => style?.copyWith(
    textStyle: WidgetStateProperty.resolveWith(
      (states) => font(style.textStyle?.resolve(states)),
    ),
  );
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: 'ReviewFont'),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'ReviewFont'),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: font(theme.appBarTheme.titleTextStyle),
      toolbarTextStyle: font(theme.appBarTheme.toolbarTextStyle),
    ),
    navigationRailTheme: theme.navigationRailTheme.copyWith(
      selectedLabelTextStyle: font(
        theme.navigationRailTheme.selectedLabelTextStyle,
      ),
      unselectedLabelTextStyle: font(
        theme.navigationRailTheme.unselectedLabelTextStyle,
      ),
    ),
    dialogTheme: theme.dialogTheme.copyWith(
      titleTextStyle: font(theme.dialogTheme.titleTextStyle),
      contentTextStyle: font(theme.dialogTheme.contentTextStyle),
    ),
    listTileTheme: theme.listTileTheme.copyWith(
      titleTextStyle: font(theme.listTileTheme.titleTextStyle),
      subtitleTextStyle: font(theme.listTileTheme.subtitleTextStyle),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: button(theme.filledButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: button(theme.outlinedButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: button(theme.textButtonTheme.style),
    ),
    snackBarTheme: theme.snackBarTheme.copyWith(
      contentTextStyle: font(theme.snackBarTheme.contentTextStyle),
    ),
  );
}

// An explicit review surface, never registered as an application route.
class _ComponentStates extends StatelessWidget {
  const _ComponentStates();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('组件状态预览')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('操作与选择'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: () {}, child: const Text('播放全部')),
              const FilledButton(onPressed: null, child: Text('暂不可用')),
              OutlinedButton(onPressed: () {}, child: const Text('重试')),
              const OutlinedButton(onPressed: null, child: KgBusyIndicator()),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: KgChoiceTabs<int>(
              options: const {0: '封面', 1: '歌词'},
              value: 0,
              pill: true,
              onChanged: (_) {},
            ),
          ),
          const SizedBox(height: 24),
          const TextField(
            decoration: InputDecoration(labelText: '歌单名称', hintText: '为歌单取个名字'),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: '歌单名称',
              errorText: '请输入歌单名称',
            ),
          ),
          const SizedBox(height: 24),
          const Text('内容加载'),
          const SizedBox(height: 8),
          const KgSongListSkeleton(rows: 2),
          const SizedBox(height: 16),
          const KgEntrance(
            child: KgEmptyView('没有找到匹配结果', icon: Icons.search_off_rounded),
          ),
        ],
      ),
    ),
  );
}
