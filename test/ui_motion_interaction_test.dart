import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_motion.dart';
import 'package:kgmusic/core/widgets/song_favorite_button.dart';

import 'support/ui_app_harness.dart';

void main() {
  testWidgets('departing content cannot receive taps or keyboard activation', (
    tester,
  ) async {
    final next = ValueNotifier(false);
    addTearDown(next.dispose);
    var oldCalls = 0;
    var newCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildKgTheme(),
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: next,
            builder: (context, changed, _) => KgStateTransition(
              child: changed
                  ? TextButton(
                      key: const ValueKey('new'),
                      onPressed: () => newCalls++,
                      child: const Text('新操作'),
                    )
                  : SizedBox(
                      key: const ValueKey('old'),
                      height: 160,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: TextButton(
                          autofocus: true,
                          onPressed: () => oldCalls++,
                          child: const Text('旧操作'),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final oldPosition = tester.getCenter(find.text('旧操作'));
    next.value = true;
    await tester.pump();
    await tester.tapAt(oldPosition);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(oldCalls, 0);
    expect(newCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid search category switches keep the latest results usable', (
    tester,
  ) async {
    final harness = await UiAppHarness.create(
      songs: List.generate(
        40,
        (index) => Song(
          id: 'song-$index',
          title: '歌曲 $index',
          hashes: const AudioHashes(),
        ),
      ),
      playlists: const [
        Playlist(
          localId: 'list',
          name: '海边歌单',
          isPrivate: false,
          isMyFavorite: false,
          isDefaultCollect: false,
        ),
      ],
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app(reduceMotion: false));
    harness.router.go('/library');
    await tester.pumpAndSettle();
    harness.router.go('/search');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '海');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    for (final category in ['歌单', '歌曲', '歌单', '歌曲']) {
      await tester.tap(find.text(category));
      // Several switches intentionally land before the previous fade finishes.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pumpAndSettle();
    // The same playlist also exists in the retained library branch. Its hidden
    // Hero must not participate when opening the visible search result.
    await tester.tap(find.text('歌单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('海边歌单').hitTestable());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    harness.router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('歌曲'));
    await tester.pumpAndSettle();
    expect(find.text('歌曲 1').hitTestable(), findsOneWidget);
    expect(find.text('海边歌单').hitTestable(), findsNothing);
    await tester.drag(find.text('歌曲 1').hitTestable(), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pumpAndSettle();
    expect(find.text('输入歌曲、歌手或歌单名称'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'favorite feedback prevents duplicate writes and permits retry after failure',
    (tester) async {
      final repository = _PendingFavoriteRepository();
      final ids = StreamController<Set<String>>();
      addTearDown(ids.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryRepositoryProvider.overrideWithValue(repository),
            libraryReadyProvider.overrideWithValue(true),
            favoriteSongIdsProvider.overrideWith((ref) => ids.stream),
          ],
          child: MaterialApp(
            theme: buildKgTheme(),
            home: const Scaffold(
              body: SongFavoriteButton(
                song: Song(id: 'song', title: '歌曲', hashes: AudioHashes()),
              ),
            ),
          ),
        ),
      );
      ids.add({});
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('添加到我喜欢'));
      await tester.pump();
      await tester.tap(find.byTooltip('添加到我喜欢'));
      expect(repository.calls, 1);
      repository.pending.completeError(StateError('unavailable'));
      await tester.pumpAndSettle();
      repository.pending = Completer<void>();
      await tester.tap(find.byTooltip('添加到我喜欢'));
      expect(repository.calls, 2);
      ids.add({'song'});
      repository.pending.complete();
      await tester.pumpAndSettle();
      expect(find.byTooltip('取消喜欢'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

class _PendingFavoriteRepository extends Fake implements LibraryRepository {
  int calls = 0;
  Completer<void> pending = Completer<void>();

  @override
  Future<void> setFavorite(Song song, {required bool liked}) {
    calls++;
    return pending.future;
  }
}
