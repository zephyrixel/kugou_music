import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/playback_insets.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';

class KgBusyIndicator extends StatelessWidget {
  const KgBusyIndicator({
    super.key,
    this.size = 18,
    this.strokeWidth = 2,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(strokeWidth: strokeWidth, color: color),
  );
}

class KgLoadingView extends StatelessWidget {
  const KgLoadingView({super.key, this.label, this.compact = false});

  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(compact ? KgSpacing.md : KgSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: compact ? 22 : 30,
            child: CircularProgressIndicator(strokeWidth: compact ? 2 : 2.5),
          ),
          if (label != null) ...[
            const SizedBox(height: KgSpacing.sm),
            Text(label!, style: const TextStyle(color: KgColors.textMuted)),
          ],
        ],
      ),
    ),
  );
}

/// Static placeholders preserve geometry without adding background tickers.
class KgSkeleton extends StatelessWidget {
  const KgSkeleton({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = KgRadii.medium,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: KgColors.elevatedHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

class KgSongListSkeleton extends StatelessWidget {
  const KgSongListSkeleton({super.key, this.rows = 5});

  final int rows;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '正在加载歌曲',
    child: Column(
      children: List.generate(
        rows,
        (index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              KgSkeleton(height: 48, width: 48),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: 0.7,
                      child: KgSkeleton(height: 14, radius: 4),
                    ),
                    SizedBox(height: 10),
                    FractionallySizedBox(
                      widthFactor: 0.4,
                      child: KgSkeleton(height: 10, radius: 4),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Shared full-area error + retry (home / library / search / playlists).
class KgErrorView extends StatelessWidget {
  const KgErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  final String message;
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
        Text(message, textAlign: TextAlign.center),
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
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + PlaybackInsets.bottomOf(context),
        ),
        child: body,
      ),
    );
  }
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          28,
          24,
          28,
          24 + PlaybackInsets.bottomOf(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (constraints.maxHeight >= 200) ...[
              Icon(icon, color: KgColors.textMuted, size: 32),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: KgColors.textMuted),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    ),
  );
}

void showAppError(BuildContext context, String message) {
  if (!context.mounted) return;
  final colors = Theme.of(context).colorScheme;
  _showAppSnackBar(
    context,
    message: message,
    icon: Icons.error_outline_rounded,
    backgroundColor: colors.errorContainer,
    foregroundColor: colors.onErrorContainer,
  );
}

void showAppErrorWithMessenger(
  GlobalKey<ScaffoldMessengerState> messengerKey,
  String message,
) {
  final messenger = messengerKey.currentState;
  final context = messengerKey.currentContext;
  if (messenger == null || context == null) return;
  final colors = Theme.of(context).colorScheme;
  _showSnackBar(
    messenger,
    message: message,
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
    foregroundColor: KgColors.textPrimary,
  );
}

void _showAppSnackBar(
  BuildContext context, {
  required String message,
  required IconData icon,
  required Color backgroundColor,
  required Color foregroundColor,
}) {
  _showSnackBar(
    ScaffoldMessenger.of(context),
    message: message,
    icon: icon,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
  );
}

void _showSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required IconData icon,
  required Color backgroundColor,
  required Color foregroundColor,
}) {
  messenger.showSnackBar(
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
