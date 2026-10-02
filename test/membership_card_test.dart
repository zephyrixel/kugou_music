import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/features/membership/membership_card.dart';

void main() {
  testWidgets('membership action stays beside the summary on phone screens', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [320.0, 360.0, 390.0]) {
      await tester.binding.setSurfaceSize(Size(width, 844));
      await tester.pumpWidget(_app());
      final action = tester.getRect(find.widgetWithText(TextButton, '领取权益'));
      final summary = tester.getRect(find.text('暂未开通会员'));
      expect(action.left, greaterThanOrEqualTo(summary.right));
      expect(action.top, lessThan(summary.bottom));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('membership action remains reachable with narrow large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(textScale: 2));
    await tester.ensureVisible(find.text('领取权益'));
    expect(find.text('领取权益').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({double textScale = 1}) => ProviderScope(
  child: MaterialApp(
    theme: buildKgTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [MembershipCard(vip: AsyncData(UserVip()), userId: 1)],
      ),
    ),
  ),
);
