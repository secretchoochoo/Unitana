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

  testWidgets(
    'PlacesHeroV2 keeps clock detail + date visible across reality swaps',
    (tester) async {
      await pumpDashboardHarness(tester);
      await pumpStable(tester);

      // Baseline invariants.
      expect(
        find.byKey(const ValueKey('places_hero_clock_detail')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('places_hero_clock_date')),
        findsOneWidget,
      );

      // Swap to Home.
      await tester.tap(find.byKey(const ValueKey('places_hero_segment_home')));
      await pumpStable(tester);

      expect(
        find.byKey(const ValueKey('places_hero_clock_detail')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('places_hero_clock_date')),
        findsOneWidget,
      );

      // Swap back to Destination.
      await tester.tap(find.byKey(const ValueKey('places_hero_segment_dest')));
      await pumpStable(tester);

      expect(
        find.byKey(const ValueKey('places_hero_clock_detail')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('places_hero_clock_date')),
        findsOneWidget,
      );
    },
  );
}
