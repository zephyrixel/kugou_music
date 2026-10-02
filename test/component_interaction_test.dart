import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/logging/app_log_level.dart';
import 'package:kgmusic/core/widgets/kg_choice_tabs.dart';
import 'package:kgmusic/core/widgets/kg_settings_group.dart';
import 'package:kgmusic/features/logging/log_settings_panels.dart';
import 'package:kgmusic/features/player/player_screen.dart';

import 'support/ui_app_harness.dart';

void main() {
  testWidgets('choice tabs support keyboard selection with reduced motion', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildKgTheme(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (_, setState) => KgChoiceTabs<int>(
                value: selected,
                options: const {0: '封面', 1: '歌词'},
                pill: true,
                onChanged: (value) => setState(() => selected = value),
              ),
            ),
          ),
        ),
      ),
    );
    final semantics = tester.ensureSemantics();
    try {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, 1);
      expect(
        tester.getSemantics(find.text('歌词')),
        matchesSemantics(
          label: '歌词',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isFocusable: true,
          isFocused: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('disabled settings never invoke the enabled action', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildKgTheme(),
        home: Scaffold(
          body: KgSettingsGroup(
            children: [
              KgSettingsTile(
                icon: Icons.delete_outline_rounded,
                title: '清空日志',
                enabled: false,
                destructive: true,
                onTap: () => calls++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('清空日志'));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });

  testWidgets(
    'narrow large-text log filters keep their labels and can select',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var source = 'all';
      await tester.pumpWidget(
        MaterialApp(
          theme: buildKgTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (_, setState) => LogFilters(
                  source: source,
                  minimumLevel: AppLogLevel.trace,
                  onSourceChanged: (value) => setState(() => source = value),
                  onMinimumLevelChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('全部'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Native / SDK').last);
      await tester.pumpAndSettle();
      expect(source, 'native');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty add-to-playlist sheet explains the next step and dismisses',
    (tester) async {
      final harness = await UiAppHarness.create();
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app());
      harness.router.push<void>('/player');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('添加到歌单'));
      await tester.pumpAndSettle();
      expect(
        find.text('暂无可添加的歌单，请先在“我的”中新建歌单。'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .join(' / '),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
