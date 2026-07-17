import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/logging/app_log_entry.dart';
import 'package:kgmusic/core/logging/app_log_level.dart';
import 'package:kgmusic/core/widgets/app_dialogs.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_settings_group.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/features/logging/log_entry_tile.dart';

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
                      _LevelCard(
                        level: logging.level,
                        traceActive: logging.traceActive,
                        nativeAvailable: logging.nativeAvailable,
                        nativeError: logging.nativeError,
                        totalBytes: _totalBytes,
                        onChanged: _changeLevel,
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
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
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _source,
                              decoration: const InputDecoration(
                                labelText: '来源',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'all',
                                  child: Text('全部'),
                                ),
                                DropdownMenuItem(
                                  value: 'flutter',
                                  child: Text('Flutter'),
                                ),
                                DropdownMenuItem(
                                  value: 'native',
                                  child: Text('Native / SDK'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _source = value ?? 'all'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<AppLogLevel>(
                              initialValue: _minimumLevel,
                              decoration: const InputDecoration(
                                labelText: '最低等级',
                              ),
                              items: AppLogLevel.values
                                  .where((level) => level != AppLogLevel.off)
                                  .map(
                                    (level) => DropdownMenuItem(
                                      value: level,
                                      child: Text(level.label),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) => setState(
                                () =>
                                    _minimumLevel = value ?? AppLogLevel.trace,
                              ),
                            ),
                          ),
                        ],
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
    final values = await Future.wait([
      logging.loadRecent(),
      logging.totalBytes(),
    ]);
    if (!mounted) return;
    setState(() {
      _entries = values[0] as List<AppLogEntry>;
      _totalBytes = values[1] as int;
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.traceActive,
    required this.nativeAvailable,
    required this.nativeError,
    required this.totalBytes,
    required this.onChanged,
  });

  final AppLogLevel level;
  final bool traceActive;
  final bool nativeAvailable;
  final String? nativeError;
  final int totalBytes;
  final ValueChanged<AppLogLevel> onChanged;

  @override
  Widget build(BuildContext context) => KgSurface(
    child: Padding(
      padding: EdgeInsets.zero,
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
          if (traceActive) ...[
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
    ),
  );

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
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
      ListTile(
        leading: const Icon(Icons.share_outlined),
        title: const Text('分享日志'),
        subtitle: const Text('通过系统分享面板发送诊断文件'),
        onTap: onShare,
      ),
      ListTile(
        leading: const Icon(Icons.save_alt_rounded),
        title: const Text('另存为'),
        subtitle: const Text('选择位置保存文本日志'),
        onTap: onSave,
      ),
      ListTile(
        leading: const Icon(
          Icons.delete_outline_rounded,
          color: KgColors.warning,
        ),
        title: const Text('清空日志'),
        onTap: onClear,
      ),
    ],
  );
}
