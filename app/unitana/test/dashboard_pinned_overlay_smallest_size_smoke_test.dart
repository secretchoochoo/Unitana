import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  Future<void> pumpStable(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets('Pinned header smoke test at small viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpDashboardHarness(tester);
    await pumpStable(tester);

    // Ensure we can scroll without exceptions and pinned header can appear.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await pumpStable(tester);

    final miniOpacityFinder = find.byKey(
      const ValueKey('dashboard_collapsing_header_mini_layer'),
    );
    expect(miniOpacityFinder, findsOneWidget);
    final after = tester.widget<Opacity>(miniOpacityFinder);
    expect(after.opacity, greaterThan(0.5));
  });
}
