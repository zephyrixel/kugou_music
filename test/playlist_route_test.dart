import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/features/playlists/playlist_detail_screen.dart';

void main() {
  test('playlist targets reject missing identifiers and unknown objects', () {
    expect(PlaylistTarget.parse(Object()), isNull);
    expect(
      PlaylistTarget.parse(
        const PlaylistTarget.public(PlaylistSearchHit(name: 'Missing')),
      ),
      isNull,
    );
    final target = PlaylistTarget.public(
      const PlaylistSearchHit(name: 'Ready', globalCollectionId: 'gid'),
    );
    expect(PlaylistTarget.parse(target), same(target));
  });

  testWidgets(
    'invalid playlist navigation displays recovery instead of a blank screen',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PlaylistDetailScreen(source: null)),
      );
      expect(find.text('返回音乐库'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
