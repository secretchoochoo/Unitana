import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  testWidgets('Pinned hero overlay is present and reacts to toggles', (
    tester,
  ) async {
    await pumpDashboardForTest(tester, surfaceSize: const Size(390, 640));

    expect(find.byKey(const ValueKey('dashboard_pinned_hero')), findsOneWidget);

    final segHome = find
        .byKey(const ValueKey('dashboard_pinned_segment_home'))
        .hitTestable();
    final segDest = find
        .byKey(const ValueKey('dashboard_pinned_segment_destination'))
        .hitTestable();

    // Overlay exists in the tree but is not interactive until you scroll.
    expect(segHome, findsNothing);
    expect(segDest, findsNothing);

    final scrollable = find.byType(CustomScrollView);
    expect(scrollable, findsOneWidget);

    for (var i = 0; i < 14; i++) {
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();
      if (segHome.evaluate().isNotEmpty && segDest.evaluate().isNotEmpty) {
        break;
      }
    }

    expect(segHome, findsOneWidget);
    expect(segDest, findsOneWidget);

    await tester.tap(segHome);
    await tester.pumpAndSettle();

    await tester.tap(segDest);
    await tester.pumpAndSettle();

    // Smoke: pinned pills render (keys are stable, text is not asserted).
    expect(
      find.byKey(const ValueKey('dashboard_pinned_time_temp_pill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard_pinned_currency_pill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard_pinned_details_pill')),
      findsOneWidget,
    );
  });

  testWidgets('Pinned overlay Details pill toggles after scroll', (
    tester,
  ) async {
    await pumpDashboardForTest(tester, surfaceSize: const Size(390, 640));

    final detailsPill = find.byKey(
      const ValueKey('dashboard_pinned_details_pill'),
    );
    final sunContent = find.byKey(
      const ValueKey('dashboard_pinned_details_sun'),
    );
    final windContent = find.byKey(
      const ValueKey('dashboard_pinned_details_wind'),
    );

    // Overlay exists in the tree but is not interactive until you scroll.
    expect(detailsPill.hitTestable(), findsNothing);

    final scrollable = find.byType(CustomScrollView);
    expect(scrollable, findsOneWidget);

    for (var i = 0; i < 14; i++) {
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();
      if (detailsPill.hitTestable().evaluate().isNotEmpty) {
        break;
      }
    }

    expect(detailsPill.hitTestable(), findsOneWidget);

    // Defaults to wind.
    expect(windContent, findsOneWidget);
    expect(sunContent, findsNothing);

    await tester.tap(detailsPill.hitTestable());
    await tester.pumpAndSettle();

    expect(sunContent, findsOneWidget);
    expect(windContent, findsNothing);

    await tester.tap(detailsPill.hitTestable());
    await tester.pumpAndSettle();

    expect(windContent, findsOneWidget);
    expect(sunContent, findsNothing);
  });
}
