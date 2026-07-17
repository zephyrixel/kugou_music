import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/logging/app_log_entry.dart';
import 'package:kgmusic/core/logging/app_log_level.dart';
import 'package:kgmusic/core/widgets/app_dialogs.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/features/logging/log_entry_tile.dart';
import 'package:kgmusic/features/logging/log_settings_panels.dart';

class LogSettingsScreen extends ConsumerStatefulWidget {
  const LogSettingsScreen({super.key});

  @override
  ConsumerState<LogSettingsScreen> createState() => _LogSettingsScreenState();
}

class _LogSettingsScreenState extends ConsumerState<LogSettingsScreen> {
  List<AppLogEntry> _entries = const [];
  bool _loading = true;
  int _totalBytes = 0;
  String _source = 'all';
  AppLogLevel _minimumLevel = AppLogLevel.trace;

  List<AppLogEntry> get _visibleEntries => _entries
      .where(
        (entry) =>
            (_source == 'all' || entry.source == _source) &&
            entry.level.priority <= _minimumLevel.priority,
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final logging = ref.watch(appLoggingControllerProvider);
    final entries = _visibleEntries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('诊断与日志'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: KgContentWidth(
                maxWidth: KgBreakpoints.readingMaxWidth,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LogLevelPanel(
                        level: logging.level,
                        nativeAvailable: logging.nativeAvailable,
                        nativeError: logging.nativeError,
                        totalBytes: _totalBytes,
                        onChanged: _changeLevel,
                      ),
                      const SizedBox(height: 12),
                      LogActionGroup(
                        onShare: () => _export(share: true),
                        onSave: () => _export(share: false),
                        onClear: _clear,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '最近日志',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LogFilters(
                        source: _source,
                        minimumLevel: _minimumLevel,
                        onSourceChanged: (value) =>
                            setState(() => _source = value),
                        onMinimumLevelChanged: (value) =>
                            setState(() => _minimumLevel = value),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '显示 ${entries.length} 条，页面最多读取最近 1000 条',
                        style: const TextStyle(color: KgColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (entries.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('暂无符合条件的日志')),
              )
            else
              SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: KgBreakpoints.readingMaxWidth,
                    ),
                    child: LogEntryTile(entry: entries[index]),
                  ),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _loading = true);
    final logging = ref.read(appLoggingControllerProvider);
    final snapshot = await logging.loadSnapshot();
    if (!mounted) return;
    setState(() {
      _entries = snapshot.entries;
      _totalBytes = snapshot.totalBytes;
      _loading = false;
    });
  }

  Future<void> _changeLevel(AppLogLevel level) async {
    if (level == AppLogLevel.trace) {
      final accepted = await confirmDialog(
        context,
        title: '启用跟踪日志？',
        content: '跟踪日志可能包含 token、Cookie 和完整网络正文，只应短时间用于排障。该等级会在应用重启后回落为“调试”。',
        confirmLabel: '本次启用',
      );
      if (accepted != true) return;
    }
    try {
      await ref.read(appLoggingControllerProvider).setLevel(level);
      if (mounted) showAppMessage(context, '日志等级已切换为${level.label}');
      await _refresh();
    } catch (error) {
      if (mounted) showAppError(context, 'Native 日志等级切换失败：$error');
    }
  }

  Future<void> _export({required bool share}) async {
    final accepted = await confirmDialog(
      context,
      title: share ? '分享诊断日志？' : '保存诊断日志？',
      content: '导出内容可能包含网络地址、设备信息；若启用了跟踪日志，还可能包含登录凭据。请仅交给可信对象。',
      confirmLabel: share ? '继续分享' : '继续保存',
    );
    if (accepted != true) return;
    try {
      final exporter = ref.read(appLoggingControllerProvider).exporter;
      if (share) {
        await exporter.share();
      } else {
        final saved = await exporter.saveAs();
        if (!saved) return;
        if (mounted) showAppMessage(context, '日志已保存');
      }
    } catch (error) {
      if (mounted) showAppError(context, '导出日志失败：$error');
    }
  }

  Future<void> _clear() async {
    final accepted = await confirmDialog(
      context,
      title: '清空诊断日志？',
      content: '这会删除 Flutter、Rust bridge 和 SDK 的现有日志，且无法恢复。',
      confirmLabel: '清空',
    );
    if (accepted != true) return;
    try {
      await ref.read(appLoggingControllerProvider).clear();
      await _refresh();
      if (mounted) showAppMessage(context, '诊断日志已清空');
    } catch (error) {
      if (mounted) showAppError(context, '清空日志失败：$error');
    }
  }
}
