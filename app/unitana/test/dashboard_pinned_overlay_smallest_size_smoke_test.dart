import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  testWidgets('Pinned overlay has no layout overflows on smallest surface', (
    tester,
  ) async {
    await pumpDashboardForTest(tester, surfaceSize: const Size(320, 568));

    // Overlay exists in the tree, but becomes interactive only after scroll.
    final detailsPill = find.byKey(
      const ValueKey('dashboard_pinned_details_pill'),
    );
    expect(detailsPill.hitTestable(), findsNothing);

    final scrollable = find.byType(CustomScrollView);
    expect(scrollable, findsOneWidget);

    for (var i = 0; i < 18; i++) {
      await tester.drag(scrollable, const Offset(0, -220));
      await tester.pumpAndSettle();
      if (detailsPill.hitTestable().evaluate().isNotEmpty) {
        break;
      }
    }

    expect(detailsPill.hitTestable(), findsOneWidget);

    // Smoke: key surfaces remain present on smallest supported size.
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

    // Tap the details pill to ensure mode swap doesn't trigger overflows.
    await tester.tap(detailsPill.hitTestable());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
