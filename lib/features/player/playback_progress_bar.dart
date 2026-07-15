import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kgmusic/core/models/song.dart';

class PlaybackProgressBar extends StatefulWidget {
  const PlaybackProgressBar({
    super.key,
    required this.durationStream,
    required this.positionStream,
    required this.onSeek,
    this.bufferedPositionStream,
    this.compact = false,
  });

  final Stream<Duration?> durationStream;
  final Stream<Duration> positionStream;
  final Future<void> Function(Duration position) onSeek;
  final Stream<Duration>? bufferedPositionStream;
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
    builder: (context, durationSnapshot) {
      final duration = durationSnapshot.data ?? Duration.zero;
      return StreamBuilder<Duration>(
        stream: widget.positionStream,
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
                    height: widget.compact ? 25 : 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 16,
                          right: 16,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: max <= 1 ? 0 : buffered / max,
                              minHeight: 3,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white38,
                              ),
                            ),
                          ),
                        ),
                        Slider(
                          value: value,
                          max: max,
                          onChangeStart: max <= 1
                              ? null
                              : (_) => setState(() {
                                  _dragging = true;
                                  _dragValue = value;
                                }),
                          onChanged: max <= 1
                              ? null
                              : (next) => setState(() => _dragValue = next),
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
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(_dragging ? visiblePosition : position),
                        style: TextStyle(
                          fontSize: widget.compact ? 11 : 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        formatDuration(duration),
                        style: TextStyle(
                          fontSize: widget.compact ? 11 : 12,
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
