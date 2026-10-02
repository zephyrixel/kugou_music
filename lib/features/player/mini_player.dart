import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/app/player_navigation.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/artwork_backdrop.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';
import 'package:kgmusic/features/player/player_queue_sheet.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      initialData: handler.mediaItem.value,
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();
        final shape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KgRadii.hero),
          side: const BorderSide(color: KgColors.borderHighlight),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KgRadii.hero),
            boxShadow: KgShadows.floating,
          ),
          child: Material(
            color: KgColors.elevated,
            shape: shape,
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
                ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 68),
                        child: Padding(
                          // Reserve two independent 48dp buttons and the
                          // trailing inset, without splitting the tap surface.
                          padding: const EdgeInsets.fromLTRB(12, 10, 104, 10),
                          child: _MiniTrackInfo(item: item),
                        ),
                      ),
                      _MiniProgress(handler: handler),
                    ],
                  ),
                ),
                // Paint ink above artwork and progress. Buttons are siblings
                // of the opening surface, so their gestures never open it.
                Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Semantics(
                            button: true,
                            label:
                                '打开播放器，${item.title}，${item.artist ?? '未知歌手'}',
                            child: InkWell(
                              key: const ValueKey('mini-player-open'),
                              customBorder: shape,
                              onTap: () => openPlayer(GoRouter.of(context)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 2,
                          right: 4,
                          child: Row(
                            children: [
                              SizedBox.square(
                                dimension: 48,
                                child: _MiniTransport(handler: handler),
                              ),
                              SizedBox.square(
                                dimension: 48,
                                child: IconButton(
                                  tooltip: '播放队列',
                                  onPressed: () =>
                                      showPlayerQueueSheet(context, handler),
                                  icon: const Icon(
                                    Icons.queue_music_rounded,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _MiniTrackInfo extends StatelessWidget {
  const _MiniTrackInfo({required this.item});
  final MediaItem item;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Hero(
        tag: 'player-artwork:${item.id}',
        transitionOnUserGestures: true,
        createRectTween: (begin, end) =>
            MaterialRectCenterArcTween(begin: begin, end: end),
        child: AnimatedSwitcher(
          // Preserve the tight Hero flight bounds in both directions.
          layoutBuilder: (child, previous) => Stack(
            fit: StackFit.passthrough,
            alignment: Alignment.center,
            children: [...previous, ?child],
          ),
          duration: KgMotion.resolve(context, KgMotion.medium),
          child: SongArtwork(
            key: ValueKey(item.id),
            url: item.artUri?.toString(),
            cacheId: 'song:${item.id}',
            size: 44,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: AnimatedSwitcher(
          duration: KgMotion.resolve(context, KgMotion.medium),
          child: Column(
            key: ValueKey(item.id),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.artist ?? '未知歌手',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ],
  );
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
      return GestureDetector(
        // A disabled button still owns its area; taps must not fall through
        // to the full-surface opening action behind it.
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: loading ? () {} : null,
        child: IconButton(
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
