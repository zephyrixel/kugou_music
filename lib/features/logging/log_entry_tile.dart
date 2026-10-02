import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/logging/app_log_entry.dart';
import 'package:kgmusic/core/logging/app_log_level.dart';

class LogEntryTile extends StatelessWidget {
  const LogEntryTile({super.key, required this.entry});

  final AppLogEntry entry;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    expansionAnimationStyle: AnimationStyle(
      duration: KgMotion.resolve(context, KgMotion.medium),
      curve: KgMotion.standard,
    ),
    leading: Icon(
      _icon(entry.level),
      color: _color(context, entry.level),
      size: 20,
    ),
    title: Text(
      entry.message,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
    subtitle: Text(
      '${_time(entry.timestamp)} · ${entry.source} · ${entry.target}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: KgColors.textMuted, fontSize: 12),
    ),
    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    expandedCrossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SelectableText(
        entry.details,
        style: const TextStyle(
          color: KgColors.textMuted,
          fontSize: 12,
          height: 1.45,
          fontFamily: 'monospace',
        ),
      ),
    ],
  );

  static String _time(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    String three(int number) => number.toString().padLeft(3, '0');
    return '${two(value.hour)}:${two(value.minute)}:${two(value.second)}.${three(value.millisecond)}';
  }

  static IconData _icon(AppLogLevel level) => switch (level) {
    AppLogLevel.error => Icons.error_outline_rounded,
    AppLogLevel.warn => Icons.warning_amber_rounded,
    AppLogLevel.info => Icons.info_outline_rounded,
    AppLogLevel.debug => Icons.bug_report_outlined,
    AppLogLevel.trace => Icons.route_outlined,
    AppLogLevel.off => Icons.block_rounded,
  };

  static Color _color(BuildContext context, AppLogLevel level) =>
      switch (level) {
        AppLogLevel.error => Theme.of(context).colorScheme.error,
        AppLogLevel.warn => KgColors.warning,
        AppLogLevel.info => KgColors.accent,
        AppLogLevel.debug => KgColors.textMuted,
        AppLogLevel.trace => KgColors.textMuted,
        AppLogLevel.off => KgColors.textMuted,
      };
}
