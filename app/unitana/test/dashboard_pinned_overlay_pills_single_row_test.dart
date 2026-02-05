import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  Future<void> pumpStable(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets('Pinned header stacks toggle above mini hero readout', (
    tester,
  ) async {
    await pumpDashboardHarness(tester);
    await pumpStable(tester);

    // Scroll so the pinned header becomes visible.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
    await pumpStable(tester);

    final dest = find.byKey(const ValueKey('dashboard_pinned_segment_dest'));
    final readout = find.byKey(
      const ValueKey('dashboard_pinned_mini_hero_readout'),
    );
    expect(dest, findsOneWidget);
    expect(readout, findsOneWidget);

    final destRect = tester.getRect(dest);
    final readoutRect = tester.getRect(readout);

    // In the pinned (collapsed) header, the compact toggle stays on its own
    // row, with the mini hero readout below it for readability.
    expect(readoutRect.center.dy - destRect.center.dy, greaterThan(16));
  });
}
