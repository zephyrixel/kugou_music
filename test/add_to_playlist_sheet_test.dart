import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/add_to_playlist_button.dart';

void main() {
  testWidgets(
    'playlist sheet opens during loading, retries and adds to the selected list',
    (tester) async {
      final updates = StreamController<List<Playlist>>.broadcast();
      addTearDown(updates.close);
      final repository = _RecordingLibrary();
      const song = Song(
        id: 'song',
        title: '晚风',
        hashes: AudioHashes(standard: 'hash'),
      );
      var subscriptions = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryReadyProvider.overrideWithValue(true),
            libraryRepositoryProvider.overrideWithValue(repository),
            libraryPlaylistsProvider.overrideWith((ref) {
              subscriptions++;
              return updates.stream;
            }),
          ],
          child: MaterialApp(
            theme: buildKgTheme(),
            home: const Scaffold(body: AddToPlaylistButton(song: song)),
          ),
        ),
      );
      await tester.tap(find.byTooltip('添加到歌单'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('正在读取歌单'), findsOneWidget);
      updates.addError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('歌单读取失败'), findsOneWidget);
      await tester.tap(find.text('重试'));
      await tester.pump();
      expect(subscriptions, 2);
      updates.add(const [
        Playlist(
          name: '晚风歌单',
          localId: 'target',
          count: 3,
          isPrivate: true,
          isMyFavorite: false,
          isDefaultCollect: false,
        ),
        Playlist(
          name: '收藏的歌单',
          localId: 'collected',
          listType: 1,
          isPrivate: false,
          isMyFavorite: false,
          isDefaultCollect: false,
        ),
        Playlist(
          name: '默认收藏',
          localId: 'default',
          isPrivate: false,
          isMyFavorite: false,
          isDefaultCollect: true,
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('晚风歌单'), findsOneWidget);
      expect(find.text('收藏的歌单'), findsNothing);
      expect(find.text('默认收藏'), findsNothing);
      await tester.tap(find.text('晚风歌单'));
      await tester.pumpAndSettle();
      expect(repository.added, ('target', song));
      expect(find.text('已添加到歌单'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _RecordingLibrary extends Fake implements LibraryRepository {
  (String, Song)? added;
  @override
  Future<void> addSong(String playlistLocalId, Song song) async {
    added = (playlistLocalId, song);
  }
}
