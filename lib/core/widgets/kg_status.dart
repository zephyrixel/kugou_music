import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/logging/app_log.dart';

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
    child: Padding(
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

class KgSkeleton extends StatefulWidget {
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
  State<KgSkeleton> createState() => _KgSkeletonState();
}

class _KgSkeletonState extends State<KgSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return _box(0.72);
    }
    return FadeTransition(
      opacity: Tween(
        begin: 0.48,
        end: 0.86,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: _box(1),
    );
  }

  Widget _box(double opacity) => Container(
    width: widget.width,
    height: widget.height,
    decoration: BoxDecoration(
      color: KgColors.elevatedHigh.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(widget.radius),
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
      child: Padding(padding: const EdgeInsets.all(24), child: body),
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

void showAppError(
  BuildContext context,
  String message, {
  Object? cause,
  StackTrace? stackTrace,
}) {
  if (cause != null) {
    AppLog.warn(
      '用户操作未完成：$message',
      target: 'ui.feedback',
      error: cause,
      stackTrace: stackTrace,
    );
  }
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
