import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/features/player/mini_player.dart';
import 'package:kgmusic/features/player/player_screen.dart';
import 'package:kgmusic/features/playlists/playlist_scaffold.dart';

import 'support/ui_app_harness.dart';

void main() {
  testWidgets(
    'keyboard leaves search and feedback visible, then restores playback',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.resetViewInsets);
      final harness = await UiAppHarness.create();
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      harness.router.go('/search');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '海');
      await tester.pump(const Duration(milliseconds: 500));

      const keyboardHeight = 320.0;
      tester.view.viewInsets = FakeViewPadding(
        bottom: keyboardHeight * tester.view.devicePixelRatio,
      );
      await tester.pumpAndSettle();
      expect(find.byType(MiniPlayer), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(TextField).hitTestable(), findsOneWidget);
      showAppMessage(tester.element(find.byType(TextField)), '已更新');
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.byType(SnackBar)).dy,
        lessThanOrEqualTo(844 - keyboardHeight),
      );

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('海'), findsOneWidget);
      expect(
        tester.getBottomRight(find.byType(SnackBar)).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(MiniPlayer)).dy),
      );

      harness.handler.mediaItem.add(null);
      await tester.pumpAndSettle();
      expect(find.byType(MiniPlayer), findsNothing);
      expect(
        tester.getBottomRight(find.byType(SnackBar)).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy),
      );
      expect(harness.handler.playCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'content navigation retains playback and player expansion returns to its origin',
    (tester) async {
      final harness = await UiAppHarness.create();
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('播放'));
      await tester.pumpAndSettle();
      final item = harness.handler.mediaItem.value;

      for (final path in [
        '/search',
        '/library',
        '/library/history',
        '/library/favorites',
        '/playlist',
        '/account',
        '/account/settings',
        '/account/logs',
      ]) {
        harness.router.push<void>(path);
        await tester.pumpAndSettle();
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(harness.handler.mediaItem.value, same(item));
        expect(harness.handler.playbackState.value.playing, isTrue);
        expect(tester.takeException(), isNull);
      }

      // Two taps before the router commits still produce one player route.
      final title = find.descendant(
        of: find.byType(MiniPlayer),
        matching: find.text(item!.title),
      );
      await tester.tap(title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsOneWidget);
      await tester.tap(find.byTooltip('收起播放器'));
      await tester.pumpAndSettle();
      expect(harness.router.routerDelegate.state.uri.path, '/account/logs');
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(harness.handler.playCalls, 1);

      harness.auth.expire();
      await tester.pumpAndSettle();
      expect(find.byType(MiniPlayer), findsNothing);
      expect(harness.router.routerDelegate.state.uri.path, '/login');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'playlist content, feedback and modal controls remain above the floating player',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final songs = List.generate(
        18,
        (index) => Song(
          id: '$index',
          title: '歌曲 $index',
          artist: '歌手',
          hashes: AudioHashes(standard: 'hash-$index'),
        ),
      );
      final harness = await UiAppHarness.create(songs: songs);
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
      harness.router.push<void>(
        '/playlist',
        extra: const PlaylistTarget.public(
          PlaylistSearchHit(name: '歌单', globalCollectionId: 'demo'),
        ),
      );
      await tester.pumpAndSettle();

      final list = find.descendant(
        of: find.byType(PlaylistSongsView),
        matching: find.byType(CustomScrollView),
      );
      await tester.drag(list, const Offset(0, -2400));
      await tester.pumpAndSettle();
      final lastSong = find.text(songs.last.title);
      final player = find.byType(MiniPlayer);
      expect(lastSong.hitTestable(), findsOneWidget);
      expect(
        tester.getBottomRight(lastSong).dy,
        lessThan(tester.getTopLeft(player).dy),
      );

      showAppMessage(tester.element(lastSong), '已更新');
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.byType(SnackBar)).dy,
        lessThanOrEqualTo(tester.getTopLeft(player).dy),
      );
      ScaffoldMessenger.of(tester.element(lastSong)).clearSnackBars();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('播放队列'));
      await tester.pumpAndSettle();
      expect(find.text('播放队列'), findsOneWidget);
      expect(find.byTooltip('播放').hitTestable(), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byTooltip('播放').hitTestable(), findsOneWidget);
      expect(harness.router.routerDelegate.state.uri.path, '/playlist');
      expect(tester.takeException(), isNull);
    },
  );
}
