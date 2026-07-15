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
  const KgInlineError({super.key, required this.error, required this.onRetry});

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
  const KgEmptyView(
    this.message, {
    super.key,
    this.icon = Icons.music_note_rounded,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: KgColors.elevated,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: KgColors.textMuted, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: KgColors.textMuted),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}

void showAppError(BuildContext context, Object error) {
  if (!context.mounted) return;
  final colors = Theme.of(context).colorScheme;
  _showAppSnackBar(
    context,
    message: error.toString(),
    icon: Icons.error_outline_rounded,
    backgroundColor: colors.errorContainer,
    foregroundColor: colors.onErrorContainer,
  );
}

void showAppMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  _showAppSnackBar(
    context,
    message: message,
    icon: Icons.info_outline_rounded,
    backgroundColor: KgColors.elevatedHigh,
    foregroundColor: Colors.white,
  );
}

void _showAppSnackBar(
  BuildContext context, {
  required String message,
  required IconData icon,
  required Color backgroundColor,
  required Color foregroundColor,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: backgroundColor,
      content: Row(
        children: [
          Icon(icon, color: foregroundColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: foregroundColor)),
          ),
        ],
      ),
    ),
  );
}
