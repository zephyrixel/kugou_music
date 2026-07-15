import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

/// Play [song], optionally with a queue. Surfaces failures via SnackBar.
Future<void> playSong(
  BuildContext context,
  WidgetRef ref,
  Song song, {
  List<Song>? queue,
  PlaybackQueueRequest? queueRequest,
}) async {
  try {
    await ref
        .read(audioHandlerProvider)
        .playSong(song, queueSongs: queue, queueRequest: queueRequest);
  } catch (error) {
    if (context.mounted) showAppError(context, error);
  }
}
