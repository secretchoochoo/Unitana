import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  Future<void> pumpStable(WidgetTester tester) async {
    // Avoid pumpAndSettle; dashboard has live elements.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets('Pinned mini-hero readout fades in after scroll', (tester) async {
    await pumpDashboardHarness(tester);
    await pumpStable(tester);

    final readoutFinder = find.byKey(
      const ValueKey('dashboard_pinned_mini_hero_readout'),
    );
    expect(readoutFinder, findsOneWidget);

    final miniOpacityFinder = find.byKey(
      const ValueKey('dashboard_collapsing_header_mini_layer'),
    );
    expect(miniOpacityFinder, findsOneWidget);

    final before = tester.widget<Opacity>(miniOpacityFinder);
    expect(before.opacity, equals(0));

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await pumpStable(tester);

    final after = tester.widget<Opacity>(miniOpacityFinder);
    expect(after.opacity, greaterThan(0.5));
  });
}
