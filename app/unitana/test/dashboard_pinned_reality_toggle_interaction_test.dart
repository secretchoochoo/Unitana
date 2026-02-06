import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  Future<void> pumpStable(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets(
    'Pinned reality toggle order matches hero and tap switches reality while visible',
    (tester) async {
      await pumpDashboardHarness(tester);
      await pumpStable(tester);

      Text primaryTempText() =>
          tester.widget<Text>(find.byKey(const ValueKey('hero_primary_temp')));

      final homeHeroSegment = find.byKey(
        const ValueKey('places_hero_segment_home'),
      );
      await ensureVisibleAligned(tester, homeHeroSegment);
      await tester.tap(homeHeroSegment);
      await pumpStable(tester);

      expect(primaryTempText().data ?? '', contains('°F'));

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
      await pumpStable(tester);

      final miniOpacity = tester.widget<Opacity>(
        find.byKey(const ValueKey('dashboard_collapsing_header_mini_layer')),
      );
      expect(miniOpacity.opacity, greaterThan(0));

      final destSegment = find.byKey(
        const ValueKey('dashboard_pinned_segment_dest'),
      );
      final homeSegment = find.byKey(
        const ValueKey('dashboard_pinned_segment_home'),
      );
      expect(destSegment, findsOneWidget);
      expect(homeSegment, findsOneWidget);

      final destX = tester.getCenter(destSegment).dx;
      final homeX = tester.getCenter(homeSegment).dx;
      expect(destX, lessThan(homeX));

      await ensureVisibleAligned(tester, destSegment);
      await tester.tap(destSegment, warnIfMissed: false);
      await pumpStable(tester);

      expect(primaryTempText().data ?? '', contains('°C'));
    },
  );
}
