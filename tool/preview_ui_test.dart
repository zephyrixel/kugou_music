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

      for (final configuration in [
        (name: 'phone', size: const Size(390, 844), scale: 1.0),
        (name: 'narrow', size: const Size(320, 568), scale: 1.0),
        (name: 'large-text', size: const Size(390, 844), scale: 2.0),
        (name: 'landscape', size: const Size(844, 390), scale: 1.0),
        (name: 'desktop', size: const Size(1280, 800), scale: 1.0),
      ]) {
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
          await tester.tap(
            find.descendant(
              of: find.byType(MiniPlayer),
              matching: find.text(songs.first.title),
            ),
          );
          await record(42);
          await tester.tap(find.byTooltip('收起播放器'));
          await record(36);
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
        if (configuration.name == 'phone') {
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
        harness.router.push<void>('/account/settings');
        await capture('settings');
        if (configuration.name == 'phone') {
          harness.router.go('/search');
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), '海');
          await tester.pump(const Duration(milliseconds: 500));
          FocusManager.instance.primaryFocus?.unfocus();
          await capture('search');
          harness.router.push<void>('/account');
          await capture('account');
          harness.auth.expire();
          await capture('login');
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
