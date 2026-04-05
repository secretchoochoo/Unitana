import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final deadline = DateTime.now().add(duration);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('Dashboard tiles expose a visible more-actions affordance', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);

    final moreButton = find.byKey(const ValueKey('dashboard_tile_more_baking'));
    await pumpUntilFound(tester, moreButton);
    await ensureVisibleAligned(tester, moreButton);

    await tester.tap(moreButton);
    await _pumpFor(tester, const Duration(milliseconds: 250));

    expect(find.text('Replace tile'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard_edit_done')), findsNothing);
  });

  testWidgets('Dashboard long-press quick actions do not enter edit mode', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);

    final bakingTile = find.text('Baking').first;
    await ensureVisibleAligned(tester, bakingTile);
    await tester.longPress(bakingTile, warnIfMissed: false);
    await _pumpFor(tester, const Duration(milliseconds: 250));

    expect(find.text('Replace tile'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard_edit_done')), findsNothing);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dashboard_edit_done')), findsNothing);
  });

  testWidgets('Dashboard quick actions can explicitly enter edit mode', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);

    final bakingTile = find.text('Baking').first;
    await ensureVisibleAligned(tester, bakingTile);
    await tester.longPress(bakingTile, warnIfMissed: false);
    await _pumpFor(tester, const Duration(milliseconds: 250));

    await tester.tap(find.text('Edit Widgets'));
    await _pumpFor(tester, const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('dashboard_edit_done')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard_edit_cancel')), findsOneWidget);
  });
}
