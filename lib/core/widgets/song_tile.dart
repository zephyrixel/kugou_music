import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

enum SongTileVariant { artwork, indexed, compact }

enum SongTilePlayback { none, paused, playing }

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.index,
    this.trailing,
    this.variant,
    this.playback = SongTilePlayback.none,
  });

  final Song song;
  final VoidCallback onTap;
  final int? index;
  final Widget? trailing;
  final SongTileVariant? variant;
  final SongTilePlayback playback;

  @override
  Widget build(BuildContext context) {
    final style =
        variant ??
        (index == null ? SongTileVariant.artwork : SongTileVariant.indexed);
    assert(style != SongTileVariant.indexed || index != null);
    final current = playback != SongTilePlayback.none;
    return Semantics(
      selected: current,
      value: current
          ? (playback == SongTilePlayback.playing ? '正在播放' : '已暂停')
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KgSpacing.xs),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(KgRadii.medium),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: current ? KgGradients.selected : null,
            ),
            child: ListTile(
              minTileHeight: style == SongTileVariant.compact ? 64 : 72,
              selected: current,
              selectedColor: KgColors.accent,
              selectedTileColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: KgSpacing.sm,
                vertical: 6,
              ),
              horizontalTitleGap: KgSpacing.sm,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KgRadii.medium),
              ),
              hoverColor: KgColors.hover,
              splashColor: KgColors.pressed,
              onTap: onTap,
              leading: switch (style) {
                SongTileVariant.artwork => SongArtwork(
                  url: song.artworkUrl,
                  cacheId: 'song:${song.id}',
                ),
                SongTileVariant.indexed => SizedBox(
                  width: 32,
                  child: current
                      ? Icon(
                          playback == SongTilePlayback.playing
                              ? Icons.graphic_eq_rounded
                              : Icons.pause_rounded,
                          size: 20,
                          color: KgColors.accent,
                        )
                      : Text(
                          index.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: KgColors.textMuted,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                ),
                SongTileVariant.compact => null,
              },
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: current ? KgColors.accent : KgColors.textPrimary,
                ),
              ),
              subtitle: Text(
                '${song.artistLabel}${song.album == null ? '' : ' · ${song.album}'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: KgColors.textMuted,
                ),
              ),
              trailing:
                  trailing ??
                  (song.durationSecs == null
                      ? null
                      : Text(
                          formatDuration(Duration(seconds: song.durationSecs!)),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        )),
            ),
          ),
        ),
      ),
    );
  }
}
