import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';

void main() {
  testWidgets('status content stays reachable in a short viewport', (
    tester,
  ) async {
    var retries = 0;
    await tester.binding.setSurfaceSize(const Size(320, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildKgTheme(),
        home: const Scaffold(body: KgEmptyView('输入歌曲或歌手名称')),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildKgTheme(),
        home: Scaffold(
          body: KgErrorView(
            message: '连接失败',
            onRetry: () async {
              retries++;
            },
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('重试'));
    await tester.tap(find.text('重试'));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
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

    showAppError(context, '网络连接失败');
    await tester.pump();

    var snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    var text = tester.widget<Text>(find.text('网络连接失败'));
    expect(
      _contrast(text.style!.color!, snackBar.backgroundColor!),
      greaterThanOrEqualTo(4.5),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    showAppMessage(context, '已添加到歌单');
    await tester.pump();

    snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    text = tester.widget<Text>(find.text('已添加到歌单'));
    expect(
      _contrast(text.style!.color!, snackBar.backgroundColor!),
      greaterThanOrEqualTo(4.5),
    );
  });
}

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return ((a > b ? a : b) + 0.05) / ((a > b ? b : a) + 0.05);
}
