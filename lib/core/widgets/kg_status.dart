import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';

/// Shared full-area error + retry (home / library / search / playlists).
class KgErrorView extends StatelessWidget {
  const KgErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.compact = false,
  });

  final Object error;
  final Future<void> Function() onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          const Icon(Icons.cloud_off_rounded, size: 42),
          const SizedBox(height: 12),
        ],
        Text(error.toString(), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重试'),
        ),
      ],
    );
    if (compact) return body;
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: body),
    );
  }
}

/// Inline list-row error (account playlist list, etc.).
class KgInlineError extends StatelessWidget {
  const KgInlineError({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(error.toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: IconButton(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
    ),
  );
}

/// Empty-state text used by search / library lists.
class KgEmptyView extends StatelessWidget {
  const KgEmptyView(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(message, style: const TextStyle(color: KgColors.textMuted)),
  );
}

void showAppError(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(error.toString())));
}

void showAppMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
