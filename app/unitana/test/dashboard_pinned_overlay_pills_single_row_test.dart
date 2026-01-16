import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  testWidgets('Pinned cockpit pills remain single-row on smallest surface', (
    tester,
  ) async {
    // Smallest supported surface (see pinned overlay smoke test).
    await pumpDashboardForTest(tester, surfaceSize: const Size(320, 568));

    final pillTimeTemp = find.byKey(
      const ValueKey('dashboard_pinned_time_temp_pill'),
    );
    final pillCurrency = find.byKey(
      const ValueKey('dashboard_pinned_currency_pill'),
    );
    final pillDetails = find.byKey(
      const ValueKey('dashboard_pinned_details_pill'),
    );

    expect(pillTimeTemp, findsOneWidget);
    expect(pillCurrency, findsOneWidget);
    expect(pillDetails, findsOneWidget);

    // Overlay exists in the tree, but becomes interactive only after scroll.
    // Scroll until the pinned overlay is in its final laid-out state.
    final scrollable = find.byType(CustomScrollView);
    expect(scrollable, findsOneWidget);

    for (var i = 0; i < 18; i++) {
      await tester.drag(scrollable, const Offset(0, -220));
      await tester.pumpAndSettle();
      if (pillDetails.hitTestable().evaluate().isNotEmpty) {
        break;
      }
    }

    expect(pillDetails.hitTestable(), findsOneWidget);

    final dyA = tester.getTopLeft(pillTimeTemp).dy;
    final dyB = tester.getTopLeft(pillCurrency).dy;
    final dyC = tester.getTopLeft(pillDetails).dy;

    final minDy = math.min(dyA, math.min(dyB, dyC));
    final maxDy = math.max(dyA, math.max(dyB, dyC));
    final delta = maxDy - minDy;

    // Not pixel-perfect; just ensure we never regress into multi-row stacking.
    // Stacking regressions jump delta by ~pill height (tens of px).
    expect(delta, lessThan(12.0));
  });
}
