import 'package:flutter/material.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/formatters.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/preferences/app_settings.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_settings_group.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

class PlaybackSettingsGroup extends StatelessWidget {
  const PlaybackSettingsGroup({
    super.key,
    required this.quality,
    required this.busy,
    required this.onChooseQuality,
  });

  final AudioQuality quality;
  final bool busy;
  final VoidCallback onChooseQuality;

  @override
  Widget build(BuildContext context) => KgSettingsGroup(
    children: [
      KgSettingsTile(
        enabled: !busy,
        icon: Icons.graphic_eq_rounded,
        title: '默认播放音质',
        subtitle: '${quality.label} · ${quality.detail}',
        trailing: busy
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: KgBusyIndicator(size: 18),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    quality.label,
                    style: const TextStyle(color: KgColors.textMuted),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
        onTap: onChooseQuality,
      ),
    ],
  );
}

class StorageSettingsPanel extends StatelessWidget {
  const StorageSettingsPanel({
    super.key,
    required this.usage,
    required this.loadingUsage,
    required this.limitBytes,
    required this.busy,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final AudioCacheUsage? usage;
  final bool loadingUsage;
  final int limitBytes;
  final bool busy;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final totalBytes = usage?.totalBytes;
    final progress = totalBytes == null || limitBytes <= 0
        ? null
        : (totalBytes / limitBytes).clamp(0.0, 1.0);
    return KgSurface(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '歌曲缓存',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalBytes == null
                          ? loadingUsage
                                ? '正在统计本机占用…'
                                : '暂时无法统计本机占用'
                          : '已使用 ${formatByteSize(totalBytes)}',
                      style: const TextStyle(color: KgColors.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '上限 ${formatByteSize(limitBytes)}',
                style: const TextStyle(
                  color: KgColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: Colors.white.withValues(alpha: 0.07),
          ),
          const SizedBox(height: 12),
          Slider(
            value: limitBytes / AudioCacheLimits.mebibyte,
            min: AudioCacheLimits.minBytes / AudioCacheLimits.mebibyte,
            max: AudioCacheLimits.maxBytes / AudioCacheLimits.mebibyte,
            divisions:
                (AudioCacheLimits.maxBytes - AudioCacheLimits.minBytes) ~/
                AudioCacheLimits.stepBytes,
            label: formatByteSize(limitBytes),
            onChanged: busy ? null : onChanged,
            onChangeEnd: busy ? null : onChangeEnd,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '缩小上限后会优先移除较久未播放的歌曲，当前播放不受影响。',
              style: TextStyle(color: KgColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsActionGroup extends StatelessWidget {
  const SettingsActionGroup({
    super.key,
    required this.clearingCache,
    required this.onClearCache,
    required this.onOpenLogs,
  });

  final bool clearingCache;
  final VoidCallback onClearCache;
  final VoidCallback onOpenLogs;

  @override
  Widget build(BuildContext context) => KgSettingsGroup(
    children: [
      KgSettingsTile(
        enabled: !clearingCache,
        icon: Icons.cleaning_services_outlined,
        title: '清理临时缓存',
        subtitle: '释放歌曲、图片和可重新获取的数据',
        trailing: clearingCache
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: KgBusyIndicator(size: 18),
              )
            : null,
        onTap: onClearCache,
      ),
      KgSettingsTile(
        icon: Icons.monitor_heart_outlined,
        title: '诊断与日志',
        subtitle: '查看、调整等级或导出应用日志',
        onTap: onOpenLogs,
      ),
    ],
  );
}

Future<AudioQuality?> showQualityPicker(
  BuildContext context, {
  required AudioQuality selected,
}) => showModalBottomSheet<AudioQuality>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text('默认播放音质', style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final quality in AudioQuality.values)
          ListTile(
            leading: Icon(
              quality == selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: quality == selected ? KgColors.accent : KgColors.textMuted,
            ),
            title: Text(quality.label),
            subtitle: Text(quality.detail),
            onTap: () => Navigator.pop(context, quality),
          ),
        const SizedBox(height: 8),
      ],
    ),
  ),
);
