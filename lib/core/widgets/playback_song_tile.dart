import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/song_tile.dart';

final _currentSongIdProvider = StreamProvider.autoDispose<String?>((
  ref,
) async* {
  final handler = ref.watch(audioHandlerProvider);
  yield handler.mediaItem.value?.id;
  yield* handler.mediaItem.map((item) => item?.id).distinct();
});

final _playingProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final handler = ref.watch(audioHandlerProvider);
  yield handler.playbackState.value.playing;
  yield* handler.playbackState.map((state) => state.playing).distinct();
});

/// Binds only the active-song state. Position ticks never rebuild song rows.
/// Queue rows supply their own index-based state directly to [SongTile].
class PlaybackSongTile extends ConsumerWidget {
  const PlaybackSongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.index,
    this.trailing,
    this.variant,
  });

  final Song song;
  final VoidCallback onTap;
  final int? index;
  final Widget? trailing;
  final SongTileVariant? variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(
      _currentSongIdProvider.select((value) => value.value == song.id),
    );
    final playing = current && (ref.watch(_playingProvider).value ?? false);
    return SongTile(
      song: song,
      onTap: onTap,
      index: index,
      trailing: trailing,
      variant: variant,
      playback: !current
          ? SongTilePlayback.none
          : playing
          ? SongTilePlayback.playing
          : SongTilePlayback.paused,
    );
  }
}
