import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

class SongFavoriteButton extends ConsumerStatefulWidget {
  const SongFavoriteButton({
    super.key,
    required this.song,
    this.compact = false,
  });
  final Song song;
  final bool compact;

  @override
  ConsumerState<SongFavoriteButton> createState() => _SongFavoriteButtonState();
}

class _SongFavoriteButtonState extends ConsumerState<SongFavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebration = AnimationController(
    vsync: this,
    duration: KgMotion.selection,
    value: 1,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.12,
      ).chain(CurveTween(curve: KgMotion.standard)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.12,
        end: 1.0,
      ).chain(CurveTween(curve: KgMotion.standard)),
      weight: 60,
    ),
  ]).animate(_celebration);
  bool _saving = false;

  @override
  void didUpdateWidget(SongFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) _celebration.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _celebration.value = 1;
  }

  @override
  void dispose() {
    _celebration.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await toggleSongFavorite(context, ref, widget.song);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(songIsFavoriteProvider(widget.song.id), (previous, next) {
      // Initial data and failed writes do not produce a success animation.
      if (previous?.value == false &&
          next.value == true &&
          !MediaQuery.disableAnimationsOf(context)) {
        _celebration.forward(from: 0);
      }
    });
    final favorite = ref.watch(songIsFavoriteProvider(widget.song.id));
    final liked = favorite.value ?? false;
    return IconButton(
      tooltip: liked ? '取消喜欢' : '添加到我喜欢',
      onPressed:
          _saving || favorite.isLoading || !ref.watch(libraryReadyProvider)
          ? null
          : _toggle,
      padding: widget.compact ? const EdgeInsets.all(8) : null,
      iconSize: widget.compact ? 20 : null,
      icon: ScaleTransition(
        scale: _scale,
        child: AnimatedSwitcher(
          duration: KgMotion.resolve(context, KgMotion.fast),
          child: Icon(
            liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(liked),
          ),
        ),
      ),
      color: liked ? KgColors.accent : null,
    );
  }
}

Future<void> toggleSongFavorite(
  BuildContext context,
  WidgetRef ref,
  Song song,
) async {
  try {
    final liked = ref.read(songIsFavoriteProvider(song.id)).value ?? false;
    await ref.read(libraryRepositoryProvider).setFavorite(song, liked: !liked);
  } catch (_) {
    if (context.mounted) showAppError(context, '未能更新“我喜欢”，请稍后重试');
  }
}
