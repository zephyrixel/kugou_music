import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

void main() {
  test('SnackBar 主题为深色背景提供清晰前景色', () {
    final snackBarTheme = buildKgTheme().snackBarTheme;

    expect(snackBarTheme.backgroundColor, KgColors.elevatedHigh);
    expect(snackBarTheme.contentTextStyle?.color, Colors.white);
    expect(snackBarTheme.actionTextColor, KgColors.accent);
    expect(snackBarTheme.closeIconColor, Colors.white);
  });

  testWidgets('错误和普通提示使用与背景匹配的文字颜色', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildKgTheme(),
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    showAppError(
      context,
      '网络连接失败',
      cause: StateError('HTTP 503 upstream unavailable'),
    );
    await tester.pump();

    var snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    var text = tester.widget<Text>(find.text('网络连接失败'));
    final colors = Theme.of(context).colorScheme;
    expect(snackBar.backgroundColor, colors.errorContainer);
    expect(text.style?.color, colors.onErrorContainer);
    expect(find.textContaining('HTTP 503'), findsNothing);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    showAppMessage(context, '已添加到歌单');
    await tester.pump();

    snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    text = tester.widget<Text>(find.text('已添加到歌单'));
    expect(snackBar.backgroundColor, KgColors.elevatedHigh);
    expect(text.style?.color, Colors.white);
  });
}
