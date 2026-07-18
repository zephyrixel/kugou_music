import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/preferences/app_settings.dart';
import 'package:kgmusic/core/widgets/app_dialogs.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/features/settings/settings_sections.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AudioCacheUsage? _usage;
  int? _draftLimitBytes;
  bool _changingQuality = false;
  bool _updatingLimit = false;
  bool _clearingCache = false;
  bool _loadingUsage = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshUsage());
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appSettingsControllerProvider);
    final settings = controller.settings;
    final limitBytes = _draftLimitBytes ?? settings.audioCacheMaxBytes;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: KgContentWidth(
        maxWidth: KgBreakpoints.readingMaxWidth,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            KgSpacing.lg,
            KgSpacing.sm,
            KgSpacing.lg,
            KgSpacing.xxl,
          ),
          children: [
            const KgSectionHeader(title: '播放'),
            const SizedBox(height: KgSpacing.sm),
            PlaybackSettingsGroup(
              quality: settings.defaultPlaybackQuality,
              busy: _changingQuality,
              onChooseQuality: () =>
                  _chooseQuality(settings.defaultPlaybackQuality),
            ),
            const SizedBox(height: KgSpacing.section),
            const KgSectionHeader(title: '存储'),
            const SizedBox(height: KgSpacing.sm),
            StorageSettingsPanel(
              usage: _usage,
              loadingUsage: _loadingUsage,
              limitBytes: limitBytes,
              busy: _updatingLimit,
              onChanged: (value) =>
                  setState(() => _draftLimitBytes = _bytesFromSlider(value)),
              onChangeEnd: _saveLimit,
            ),
            const SizedBox(height: KgSpacing.section),
            const KgSectionHeader(title: '维护与诊断'),
            const SizedBox(height: KgSpacing.sm),
            SettingsActionGroup(
              clearingCache: _clearingCache,
              onClearCache: _clearCaches,
              onOpenLogs: () => context.push('/account/logs'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseQuality(AudioQuality current) async {
    final selected = await showQualityPicker(context, selected: current);
    if (selected == null || selected == current || !mounted) return;
    setState(() => _changingQuality = true);
    try {
      await ref.read(audioHandlerProvider).setPlaybackQuality(selected);
    } catch (_) {
      if (mounted) showAppError(context, '默认播放音质设置失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _changingQuality = false);
    }
  }

  Future<void> _saveLimit(double value) async {
    final bytes = _bytesFromSlider(value);
    setState(() {
      _draftLimitBytes = bytes;
      _updatingLimit = true;
    });
    var saved = false;
    try {
      await ref
          .read(appSettingsControllerProvider)
          .setAudioCacheMaxBytes(bytes);
      saved = true;
      await ref.read(audioCacheProvider).setMaxBytes(bytes);
      await _refreshUsage(showLoading: false);
    } catch (_) {
      if (mounted) {
        showAppError(
          context,
          saved ? '缓存上限已保存，现有缓存将在稍后自动整理' : '缓存上限保存失败，请稍后重试',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _draftLimitBytes = null;
          _updatingLimit = false;
        });
      }
    }
  }

  Future<void> _clearCaches() async {
    final accepted = await confirmDialog(
      context,
      title: '清理临时缓存？',
      content: '将清理可重新获取的歌曲、图片和临时数据，账号与音乐库不会受到影响。',
      confirmLabel: '清理',
    );
    if (accepted != true || !mounted) return;
    setState(() => _clearingCache = true);
    try {
      await ref.read(cacheCoordinatorProvider).clearTransientCaches();
      await _refreshUsage(showLoading: false);
      if (mounted) showAppMessage(context, '临时缓存已清理');
    } catch (_) {
      if (mounted) showAppError(context, '临时缓存清理失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _clearingCache = false);
    }
  }

  Future<void> _refreshUsage({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _usage = null;
        _loadingUsage = true;
      });
    }
    try {
      final usage = await ref.read(audioCacheProvider).usage();
      if (mounted) {
        setState(() {
          _usage = usage;
          _loadingUsage = false;
        });
      }
    } catch (_) {
      // Capacity statistics are informative and should not block settings.
      if (mounted) setState(() => _loadingUsage = false);
    }
  }

  int _bytesFromSlider(double value) =>
      AudioCacheLimits.normalize((value * AudioCacheLimits.mebibyte).round());
}
