import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/artwork_backdrop.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/features/player/player_queue_sheet.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  bool _opening = false;

  Future<void> _open() async {
    final router = GoRouter.of(context);
    if (_opening || router.routerDelegate.state.uri.path == '/player') return;
    _opening = true;
    try {
      await router.push<void>('/player');
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      initialData: handler.mediaItem.value,
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KgRadii.hero),
            boxShadow: const [
              BoxShadow(
                color: Color(0x50000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: KgColors.elevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KgRadii.hero),
              side: const BorderSide(color: Color(0x20FFFFFF)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: ArtworkBackdrop(
                      url: item.artUri?.toString(),
                      cacheId: 'song:${item.id}',
                      opacity: 0.32,
                      scrim: 0.72,
                      blurSigma: 20,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 66),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                button: true,
                                label: '打开播放器',
                                child: InkWell(
                                  onTap: _open,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      10,
                                      4,
                                      10,
                                    ),
                                    child: Row(
                                      children: [
                                        Hero(
                                          tag: 'player-artwork:${item.id}',
                                          transitionOnUserGestures: true,
                                          createRectTween: (begin, end) =>
                                              MaterialRectCenterArcTween(
                                                begin: begin,
                                                end: end,
                                              ),
                                          child: AnimatedSwitcher(
                                            // Preserve the Hero's tight flight
                                            // bounds instead of snapping to
                                            // the destination thumbnail size.
                                            layoutBuilder: (child, previous) =>
                                                Stack(
                                                  fit: StackFit.passthrough,
                                                  alignment: Alignment.center,
                                                  children: [
                                                    ...previous,
                                                    ?child,
                                                  ],
                                                ),
                                            duration: KgMotion.resolve(
                                              context,
                                              KgMotion.medium,
                                            ),
                                            child: SongArtwork(
                                              key: ValueKey(item.id),
                                              url: item.artUri?.toString(),
                                              cacheId: 'song:${item.id}',
                                              size: 44,
                                              radius: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: AnimatedSwitcher(
                                            duration: KgMotion.resolve(
                                              context,
                                              KgMotion.medium,
                                            ),
                                            child: Column(
                                              key: ValueKey(item.id),
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    item.title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.artist ?? '未知歌手',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _MiniTransport(handler: handler),
                            IconButton(
                              tooltip: '播放队列',
                              onPressed: () =>
                                  showPlayerQueueSheet(context, handler),
                              icon: const Icon(
                                Icons.queue_music_rounded,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                      _MiniProgress(handler: handler),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MiniTransport extends StatelessWidget {
  const _MiniTransport({required this.handler});
  final MusicAudioHandler handler;

  @override
  Widget build(BuildContext context) => StreamBuilder<PlaybackState>(
    stream: handler.playbackState,
    initialData: handler.playbackState.value,
    builder: (context, snapshot) {
      final state = snapshot.data;
      final playing = state?.playing ?? false;
      final loading =
          state?.processingState == AudioProcessingState.loading ||
          state?.processingState == AudioProcessingState.buffering;
      return IconButton(
        tooltip: loading
            ? '正在加载'
            : playing
            ? '暂停'
            : '播放',
        onPressed: loading
            ? null
            : playing
            ? handler.pause
            : handler.play,
        icon: loading
            ? const KgBusyIndicator(size: 20)
            : AnimatedSwitcher(
                duration: KgMotion.resolve(context, KgMotion.fast),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(playing),
                  size: 28,
                ),
              ),
      );
    },
  );
}

/// The floating player survives navigation between content screens, and
/// `positionStream` ticks up to 62 Hz on short previews. A 2px bar cannot show
/// more than whole percent steps, so collapse to that before rebuilding.
class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.handler});

  final MusicAudioHandler handler;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: StreamBuilder<Duration?>(
      stream: handler.durationStream,
      initialData: handler.mediaItem.value?.duration,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data?.inMilliseconds ?? 0;
        if (duration <= 0) {
          return const _MiniProgressBars(value: 0, buffered: 0);
        }
        return StreamBuilder<int>(
          stream: handler.playbackState
              .map((state) => _percent(state.bufferedPosition, duration))
              .distinct(),
          builder: (context, bufferedSnapshot) => StreamBuilder<int>(
            initialData: _percent(handler.position, duration),
            stream: handler.positionStream
                .map((position) => _percent(position, duration))
                .distinct(),
            builder: (context, positionSnapshot) => _MiniProgressBars(
              value: (positionSnapshot.data ?? 0) / 100,
              buffered: (bufferedSnapshot.data ?? 0) / 100,
            ),
          ),
        );
      },
    ),
  );

  static int _percent(Duration position, int durationMs) =>
      (position.inMilliseconds * 100 / durationMs).clamp(0, 100).round();
}

class _MiniProgressBars extends StatelessWidget {
  const _MiniProgressBars({required this.value, required this.buffered});

  final double value;
  final double buffered;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      LinearProgressIndicator(
        value: buffered,
        minHeight: 2,
        backgroundColor: KgColors.divider,
        color: Colors.white30,
      ),
      LinearProgressIndicator(
        value: value,
        minHeight: 2,
        backgroundColor: Colors.transparent,
        color: KgColors.accent,
      ),
    ],
  );
}
