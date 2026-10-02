import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/kg_animated_size.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/song_artwork.dart';

class PlaylistHeader extends StatelessWidget {
  const PlaylistHeader({
    super.key,
    required this.title,
    required this.artwork,
    required this.cacheId,
    required this.count,
    this.subtitle,
    this.description,
  });

  final String title;
  final String? subtitle;
  final String? description;
  final String? artwork;
  final String cacheId;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked = MediaQuery.textScalerOf(context).scale(14) > 21;
        final cover = Hero(
          tag: 'playlist-artwork:$cacheId',
          child: SongArtwork(
            url: artwork,
            cacheId: cacheId,
            size: constraints.maxWidth < 340 ? 108 : 152,
            radius: KgRadii.large,
          ),
        );
        final details = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: KgColors.textMuted, fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Text('$count 首歌曲', style: Theme.of(context).textTheme.bodySmall),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stacked) ...[
              cover,
              const SizedBox(height: 16),
              details,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  cover,
                  const SizedBox(width: 20),
                  Expanded(child: details),
                ],
              ),
            if (description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _PlaylistDescription(description!),
            ],
          ],
        );
      },
    ),
  );
}

class _PlaylistDescription extends StatefulWidget {
  const _PlaylistDescription(this.text);
  final String text;

  @override
  State<_PlaylistDescription> createState() => _PlaylistDescriptionState();
}

class _PlaylistDescriptionState extends State<_PlaylistDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const style = TextStyle(
        fontSize: 13,
        color: KgColors.textMuted,
        height: 1.6,
      );
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 2,
      )..layout(maxWidth: constraints.maxWidth);
      final overflows = painter.didExceedMaxLines;
      painter.dispose();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KgAnimatedSize(
            duration: KgMotion.resolve(context, KgMotion.medium),
            alignment: Alignment.topLeft,
            child: Text(
              widget.text,
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: style,
            ),
          ),
          if (overflows)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: KgColors.textMuted,
              ),
              child: Text(_expanded ? '收起简介' : '展开简介'),
            ),
        ],
      );
    },
  );
}
