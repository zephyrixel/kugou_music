import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/models/song.dart';

class PlaybackProgressBar extends StatefulWidget {
  const PlaybackProgressBar({
    super.key,
    required this.durationStream,
    required this.positionStream,
    required this.onSeek,
    this.bufferedPositionStream,
    this.initialDuration,
    this.initialPosition = Duration.zero,
    this.initialBufferedPosition = Duration.zero,
    this.compact = false,
  });

  final Stream<Duration?> durationStream;
  final Stream<Duration> positionStream;
  final Future<void> Function(Duration position) onSeek;
  final Stream<Duration>? bufferedPositionStream;
  final Duration? initialDuration;
  final Duration initialPosition;
  final Duration initialBufferedPosition;
  final bool compact;

  @override
  State<PlaybackProgressBar> createState() => _PlaybackProgressBarState();
}

class _PlaybackProgressBarState extends State<PlaybackProgressBar> {
  bool _dragging = false;
  double? _dragValue;

  @override
  Widget build(BuildContext context) => StreamBuilder<Duration?>(
    stream: widget.durationStream,
    initialData: widget.initialDuration,
    builder: (context, durationSnapshot) {
      final duration = durationSnapshot.data ?? Duration.zero;
      return StreamBuilder<Duration>(
        stream: widget.positionStream,
        initialData: widget.initialPosition,
        builder: (context, positionSnapshot) {
          final position = positionSnapshot.data ?? Duration.zero;
          final max = duration.inMilliseconds
              .toDouble()
              .clamp(1, double.infinity)
              .toDouble();
          final currentValue = position.inMilliseconds.toDouble();
          final value = (_dragging ? _dragValue ?? currentValue : currentValue)
              .clamp(0, max)
              .toDouble();
          return StreamBuilder<Duration>(
            stream: widget.bufferedPositionStream,
            initialData: widget.initialBufferedPosition,
            builder: (context, bufferedSnapshot) {
              final buffered = (bufferedSnapshot.data ?? Duration.zero)
                  .inMilliseconds
                  .toDouble()
                  .clamp(0, max)
                  .toDouble();
              final visiblePosition = Duration(milliseconds: value.round());
              return Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: _dragging ? 1.0 : 0.0),
                      duration: KgMotion.resolve(context, KgMotion.press),
                      builder: (context, emphasis, child) => SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3 + emphasis,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 5 + emphasis * 3,
                          ),
                        ),
                        child: child!,
                      ),
                      child: Slider(
                        semanticFormatterCallback: (value) => formatDuration(
                          Duration(milliseconds: value.round()),
                        ),
                        value: value,
                        max: max,
                        secondaryTrackValue: buffered,
                        onChangeStart: max <= 1
                            ? null
                            : (_) => setState(() {
                                _dragging = true;
                                _dragValue = value;
                              }),
                        onChanged: max <= 1
                            ? null
                            : (next) => setState(() {
                                _dragging = true;
                                _dragValue = next;
                              }),
                        onChangeEnd: max <= 1
                            ? null
                            : (next) {
                                setState(() {
                                  _dragging = false;
                                  _dragValue = null;
                                });
                                unawaited(
                                  widget.onSeek(
                                    Duration(milliseconds: next.round()),
                                  ),
                                );
                              },
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(_dragging ? visiblePosition : position),
                        style: TextStyle(
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: _dragging
                              ? KgColors.accent
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        formatDuration(duration),
                        style: TextStyle(
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}
