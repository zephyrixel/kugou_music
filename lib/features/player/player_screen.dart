import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/delegated_transition_page.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/player/playback_queue.dart';
import 'package:kgmusic/features/player/player_backdrop.dart';
import 'package:kgmusic/features/player/player_control_deck.dart';
import 'package:kgmusic/features/player/player_visual_pager.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarDividerColor: Colors.transparent,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: KgColors.background,
        appBar: AppBar(
          forceMaterialTransparency: true,
          systemOverlayStyle: overlayStyle,
          leading: IconButton(
            tooltip: '收起播放器',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          ),
          titleSpacing: 0,
          title: PlayerDismissRegion(
            child: SizedBox(
              width: double.infinity,
              child: StreamBuilder<PlaybackQueueState?>(
                stream: handler.queueStateStream,
                initialData: handler.queueState,
                builder: (context, snapshot) => Text(
                  snapshot.data?.origin.displayTitle ?? '正在播放',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: KgColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: StreamBuilder<MediaItem?>(
          stream: handler.mediaItem,
          initialData: handler.mediaItem.value,
          builder: (context, snapshot) {
            final item = snapshot.data;
            if (item == null) return const Center(child: Text('暂无正在播放的歌曲'));
            final index = handler.currentIndex;
            final song = index >= 0 && index < handler.songs.length
                ? handler.songs[index]
                : null;
            return _PlayerBody(handler: handler, item: item, song: song);
          },
        ),
      ),
    );
  }
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({
    required this.handler,
    required this.item,
    required this.song,
  });
  final MusicAudioHandler handler;
  final MediaItem item;
  final Song? song;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      PlayerBackdrop(handler: handler, item: item),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x18101012), Color(0x18101012), Color(0xDB101012)],
            stops: [0, 0.45, 1],
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + kToolbarHeight,
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape =
                  constraints.maxWidth >= 600 &&
                  constraints.maxWidth > constraints.maxHeight;
              final compact = constraints.maxHeight < (landscape ? 410 : 650);
              final visual = PlayerVisualPager(
                handler: handler,
                item: item,
                song: song,
                compact: compact,
              );
              final controls = Padding(
                padding: EdgeInsets.fromLTRB(24, compact ? 8 : 16, 24, 16),
                child: RepaintBoundary(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlayerControlDeck(
                        handler: handler,
                        item: item,
                        song: song,
                        compact: compact,
                      ),
                      _PlayerMessageBanner(handler: handler),
                    ],
                  ),
                ),
              );
              if (landscape) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: visual),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: (constraints.maxWidth * 0.44).clamp(320, 480),
                        child: Center(
                          child: SingleChildScrollView(child: controls),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
              if (largeText || constraints.maxHeight < 500) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: largeText ? 320 : 240, child: visual),
                      controls,
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: visual,
                    ),
                  ),
                  controls,
                ],
              );
            },
          ),
        ),
      ),
    ],
  );
}

class _PlayerMessageBanner extends StatelessWidget {
  const _PlayerMessageBanner({required this.handler});
  final MusicAudioHandler handler;

  @override
  Widget build(BuildContext context) => StreamBuilder<String?>(
    stream: handler.messages,
    builder: (context, snapshot) {
      final message = snapshot.data;
      if (message == null || message.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: KgSpacing.xs),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color: KgColors.warning,
          ),
        ),
      );
    },
  );
}
