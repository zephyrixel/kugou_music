import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/player/music_audio_handler.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

class PlayerQualitySelector extends StatelessWidget {
  const PlayerQualitySelector({
    super.key,
    required this.handler,
    required this.song,
    required this.compact,
  });

  final MusicAudioHandler handler;
  final Song song;
  final bool compact;

  @override
  Widget build(BuildContext context) => StreamBuilder<PlaybackQualityState>(
    stream: handler.qualityStateStream,
    initialData: handler.qualityState,
    builder: (context, snapshot) {
      final state = snapshot.data ?? handler.qualityState;
      return PopupMenuButton<AudioQuality>(
        tooltip: '切换播放音质',
        enabled: !state.switching,
        onSelected: (quality) => _switchQuality(context, quality),
        itemBuilder: (context) => AudioQuality.values
            .map(
              (quality) => PopupMenuItem<AudioQuality>(
                value: quality,
                enabled: quality.isAvailableFor(song),
                child: Row(
                  children: [
                    Icon(
                      state.requested == quality
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: state.requested == quality
                          ? KgColors.accent
                          : KgColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(quality.label),
                  ],
                ),
              ),
            )
            .toList(growable: false),
        child: Container(
          height: compact ? 34 : 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.065),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.switching ? Icons.sync_rounded : Icons.graphic_eq_rounded,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                _qualityLabel(state),
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded, size: 18),
            ],
          ),
        ),
      );
    },
  );

  String _qualityLabel(PlaybackQualityState state) {
    if (state.switching) return '切换中';
    final actual = state.actual ?? state.requested;
    return state.fellBack ? '${actual.label} · 自动调整' : actual.label;
  }

  Future<void> _switchQuality(
    BuildContext context,
    AudioQuality quality,
  ) async {
    try {
      await handler.setPlaybackQuality(quality);
    } catch (_) {
      if (context.mounted) showAppError(context, '音质切换失败，请稍后重试');
    }
  }
}
