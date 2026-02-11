import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  testWidgets('Pinned mini hero fades in without a single-frame jump', (
    tester,
  ) async {
    await pumpDashboardForTest(
      tester,
      // Use a common phone size where the pinned hero threshold is reachable.
      surfaceSize: const Size(390, 844),
    );

    final tileFinder = find.byKey(const ValueKey('dashboard_item_baking'));
    expect(tileFinder, findsOneWidget);

    final miniOpacityFinder = find.byKey(
      const ValueKey('dashboard_collapsing_header_mini_layer'),
    );
    expect(miniOpacityFinder, findsOneWidget);

    // Initially pinned mini hero is present but fully transparent.
    final miniBefore = tester.widget<Opacity>(miniOpacityFinder);
    expect(miniBefore.opacity, equals(0));

    // Scroll close to the pinned threshold but not fully over it.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -245));
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    final dyBefore = tester.getTopLeft(tileFinder).dy;

    // Cross the threshold by a small amount. Prior boolean insertion would
    // cause an abrupt ~pinnedHeight jump here.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -12));
    await tester.pump(const Duration(milliseconds: 16));

    final dyAfter = tester.getTopLeft(tileFinder).dy;
    final delta = (dyAfter - dyBefore).abs();

    // Allow some movement from the scroll + animation, but guard against the
    // full-height snap.
    expect(delta, lessThan(80));

    // Once the animation settles the pinned mini hero should be at least
    // partially visible.
    await tester.pump(const Duration(milliseconds: 220));
    final miniAfter = tester.widget<Opacity>(miniOpacityFinder);
    expect(miniAfter.opacity, greaterThan(0.05));
  });
}
