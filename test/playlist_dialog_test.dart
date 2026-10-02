import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/widgets/app_dialogs.dart';

void main() {
  testWidgets(
    'blank names stay open, keyboard submission returns trimmed input',
    (tester) async {
      ({String name, bool private})? result;
      await tester.pumpWidget(
        _launcher((context) async {
          result = await promptPlaylistName(context, title: '新建歌单');
        }),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(find.text('请输入歌单名称'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(result, isNull);

      await tester.enterText(find.byType(TextFormField), '  晚风  ');
      await tester.tap(find.byType(SwitchListTile));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(result, (name: '晚风', private: true));
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);

      // Returning from the modal includes the full reverse animation; reopening
      // must not reuse a disposed controller or retain the previous validation.
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(find.text('请输入歌单名称'), findsNothing);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editing keeps metadata and remains usable above a large keyboard',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.resetViewInsets);
      ({String name, String intro, String tags, bool private})? result;
      await tester.pumpWidget(
        _launcher((context) async {
          result = await promptPlaylistEdit(
            context,
            name: '夜晚',
            intro: '沿途的风景',
            tags: '轻音乐,夜晚',
            private: true,
          );
        }, textScale: 2),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding(
        bottom: 200 * tester.view.devicePixelRatio,
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '   ');
      await tester.ensureVisible(find.text('保存'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('请输入歌单名称'), findsOneWidget);
      expect(result, isNull);
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, '  晚风  ');
      await tester.ensureVisible(find.text('保存'));
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(result, (
        name: '晚风',
        intro: '沿途的风景',
        tags: '轻音乐,夜晚',
        private: true,
      ));
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _launcher(
  Future<void> Function(BuildContext) open, {
  double textScale = 1,
}) => MaterialApp(
  theme: buildKgTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) =>
          TextButton(onPressed: () => open(context), child: const Text('打开')),
    ),
  ),
);
