import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/logging/app_log_level.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_settings_group.dart';

class LogLevelPanel extends StatelessWidget {
  const LogLevelPanel({
    super.key,
    required this.level,
    required this.nativeAvailable,
    required this.nativeError,
    required this.totalBytes,
    required this.onChanged,
  });

  final AppLogLevel level;
  final bool nativeAvailable;
  final String? nativeError;
  final int totalBytes;
  final ValueChanged<AppLogLevel> onChanged;

  @override
  Widget build(BuildContext context) => KgSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.monitor_heart_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '日志记录',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(_formatBytes(totalBytes)),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AppLogLevel>(
          key: ValueKey(level),
          initialValue: level,
          decoration: const InputDecoration(labelText: '记录等级'),
          items: AppLogLevel.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null && value != level) onChanged(value);
          },
        ),
        if (level == AppLogLevel.trace) ...[
          const SizedBox(height: 10),
          const Text(
            '跟踪日志已临时启用，重启应用后将回落为调试等级。',
            style: TextStyle(color: KgColors.warning),
          ),
        ],
        if (!nativeAvailable) ...[
          const SizedBox(height: 10),
          Text(
            nativeError == null
                ? 'Native 日志当前不可用'
                : 'Native 日志不可用：$nativeError',
            style: const TextStyle(color: KgColors.warning),
          ),
        ],
      ],
    ),
  );

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
  }
}

class LogActionGroup extends StatelessWidget {
  const LogActionGroup({
    super.key,
    required this.onShare,
    required this.onSave,
    required this.onClear,
  });

  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => KgSettingsGroup(
    children: [
      KgSettingsTile(
        icon: Icons.share_outlined,
        title: '分享日志',
        subtitle: '通过系统分享面板发送诊断文件',
        onTap: onShare,
      ),
      KgSettingsTile(
        icon: Icons.save_alt_rounded,
        title: '另存为',
        subtitle: '选择位置保存文本日志',
        onTap: onSave,
      ),
      KgSettingsTile(
        icon: Icons.delete_outline_rounded,
        title: '清空日志',
        destructive: true,
        onTap: onClear,
      ),
    ],
  );
}

class LogFilters extends StatelessWidget {
  const LogFilters({
    super.key,
    required this.source,
    required this.minimumLevel,
    required this.onSourceChanged,
    required this.onMinimumLevelChanged,
  });

  final String source;
  final AppLogLevel minimumLevel;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<AppLogLevel> onMinimumLevelChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: DropdownButtonFormField<String>(
          key: ValueKey(source),
          initialValue: source,
          decoration: const InputDecoration(labelText: '来源'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('全部')),
            DropdownMenuItem(value: 'flutter', child: Text('Flutter')),
            DropdownMenuItem(value: 'native', child: Text('Native / SDK')),
          ],
          onChanged: (value) => onSourceChanged(value ?? 'all'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: DropdownButtonFormField<AppLogLevel>(
          key: ValueKey(minimumLevel),
          initialValue: minimumLevel,
          decoration: const InputDecoration(labelText: '最低等级'),
          items: AppLogLevel.values
              .where((level) => level != AppLogLevel.off)
              .map(
                (level) =>
                    DropdownMenuItem(value: level, child: Text(level.label)),
              )
              .toList(growable: false),
          onChanged: (value) =>
              onMinimumLevelChanged(value ?? AppLogLevel.trace),
        ),
      ),
    ],
  );
}
