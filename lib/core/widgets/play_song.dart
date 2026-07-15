import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

/// Play [song], optionally with a queue. Surfaces failures via SnackBar.
Future<void> playSong(
  BuildContext context,
  WidgetRef ref,
  Song song, {
  List<Song>? queue,
}) async {
  try {
    await ref.read(audioHandlerProvider).playSong(song, queueSongs: queue);
  } catch (error) {
    if (context.mounted) showAppError(context, error);
  }
}
