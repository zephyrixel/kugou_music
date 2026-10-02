import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/lyric.dart';
import 'package:kgmusic/core/models/song.dart';

class LyricsPanel extends ConsumerStatefulWidget {
  const LyricsPanel({
    required this.song,
    required this.positionStream,
    required this.onSeek,
    super.key,
  });

  final Song song;
  final Stream<Duration> positionStream;
  final Future<void> Function(Duration position) onSeek;

  @override
  ConsumerState<LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends ConsumerState<LyricsPanel> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<Duration>? _positionSubscription;
  LyricDocument? _document;
  Object? _error;
  bool _loading = true;
  bool _following = true;
  int _generation = 0;
  int _positionMs = 0;
  int? _activeLine;
  int _playedWords = 0;
  double _lineExtent = 92;

  @override
  void initState() {
    super.initState();
    _listenToPosition();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant LyricsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.positionStream, widget.positionStream)) {
      _listenToPosition();
    }
    if (_songIdentity(oldWidget.song) != _songIdentity(widget.song)) {
      _following = true;
      _activeLine = null;
      _playedWords = 0;
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _listenToPosition() {
    unawaited(_positionSubscription?.cancel());
    _positionSubscription = widget.positionStream.listen(_onPosition);
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _document = null;
    });
    try {
      final document = await ref
          .read(lyricsRepositoryProvider)
          .load(widget.song, forceRefresh: forceRefresh);
      if (!mounted || generation != _generation) return;
      setState(() {
        _document = document;
        _loading = false;
      });
      _updateTimeline(_positionMs, force: true);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _onPosition(Duration position) {
    _positionMs = position.inMilliseconds;
    _updateTimeline(_positionMs);
  }

  void _updateTimeline(int positionMs, {bool force = false}) {
    final document = _document;
    if (!mounted || document == null) return;
    final line = document.lineIndexAt(positionMs);
    final words = line == null ? 0 : document.playedWordCount(line, positionMs);
    if (!force && line == _activeLine && words == _playedWords) return;
    final lineChanged = line != _activeLine;
    setState(() {
      _activeLine = line;
      _playedWords = words;
    });
    if (lineChanged && line != null && _following) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(line));
    }
  }

  void _scrollTo(int index) {
    if (!_scrollController.hasClients) return;
    // The list has half-viewport padding at both ends, so each item reaches
    // the viewport center at exactly index * itemExtent.
    final target = index * _lineExtent;
    final position = _scrollController.position;
    final offset = target.clamp(0.0, position.maxScrollExtent).toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(offset);
      return;
    }
    _scrollController.animateTo(
      offset,
      duration: KgMotion.resolve(context, KgMotion.slow),
      curve: KgMotion.standard,
    );
  }

  void _resumeFollowing() {
    setState(() => _following = true);
    final active = _activeLine;
    if (active != null) _scrollTo(active);
  }

  Future<void> _seekTo(int index) async {
    final document = _document;
    if (document == null) return;
    _following = true;
    await widget.onSeek(Duration(milliseconds: document.seekPositionMs(index)));
    if (mounted) {
      setState(() {});
      _scrollTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }
    if (_error != null) {
      return _LyricsMessage(
        icon: Icons.sync_problem_rounded,
        title: '歌词加载失败',
        actionLabel: '重试',
        onAction: () => _load(forceRefresh: true),
      );
    }
    final document = _document;
    if (document == null || document.lines.isEmpty) {
      return const _LyricsMessage(icon: Icons.lyrics_outlined, title: '暂无歌词');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        _lineExtent = 24 + scaler.scale(20) * 2.6 + scaler.scale(13) * 1.5;
        final centerPadding = ((constraints.maxHeight - _lineExtent) / 2)
            .clamp(0.0, double.infinity)
            .toDouble();
        return Stack(
          children: [
            NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction != ScrollDirection.idle &&
                    _following) {
                  setState(() => _following = false);
                }
                return false;
              },
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0, 0.1, 0.9, 1],
                ).createShader(bounds),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(vertical: centerPadding),
                  itemExtent: _lineExtent,
                  itemCount: document.lines.length,
                  itemBuilder: (context, index) => _LyricLineTile(
                    line: document.lines[index],
                    active: index == _activeLine,
                    playedWords: index == _activeLine ? _playedWords : 0,
                    onTap: () => _seekTo(index),
                  ),
                ),
              ),
            ),
            if (!_following)
              Positioned(
                right: 8,
                bottom: 8,
                child: FilledButton.tonalIcon(
                  onPressed: _resumeFollowing,
                  icon: const Icon(Icons.my_location_rounded, size: 16),
                  label: const Text('回到当前歌词'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LyricLineTile extends StatelessWidget {
  const _LyricLineTile({
    required this.line,
    required this.active,
    required this.playedWords,
    required this.onTap,
  });

  final LyricLine line;
  final bool active;
  final int playedWords;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secondary = line.secondaryText;
    return Semantics(
      selected: active,
      button: true,
      label: [line.text, ?secondary].join('，'),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PrimaryLyricText(
                line: line,
                active: active,
                playedWords: playedWords,
              ),
              if (secondary != null) ...[
                const SizedBox(height: 5),
                Text(
                  secondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white70 : KgColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryLyricText extends StatelessWidget {
  const _PrimaryLyricText({
    required this.line,
    required this.active,
    required this.playedWords,
  });

  final LyricLine line;
  final bool active;
  final int playedWords;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      color: active ? Colors.white : KgColors.textMuted,
      fontSize: 20,
      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
      height: 1.25,
    );
    if (!active || line.words.isEmpty) {
      return Text(
        line.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: active ? baseStyle.copyWith(color: KgColors.accent) : baseStyle,
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          for (var index = 0; index < line.words.length; index++)
            TextSpan(
              text: line.words[index].text,
              style: baseStyle.copyWith(
                color: index < playedWords ? KgColors.accent : Colors.white70,
              ),
            ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}

class _LyricsMessage extends StatelessWidget {
  const _LyricsMessage({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 34, color: KgColors.textMuted),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(color: KgColors.textMuted)),
        if (actionLabel != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

String _songIdentity(Song song) =>
    '${song.id}|${song.mixSongId}|${song.hashes.standard}';
