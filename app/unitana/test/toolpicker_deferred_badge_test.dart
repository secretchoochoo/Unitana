import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
  }

  testWidgets('clothing sizes is enabled and opens modal from picker', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await openPicker(tester);

    await tester.enterText(
      find.byKey(const ValueKey('toolpicker_search')),
      'clothing',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final row = find.byKey(const Key('toolpicker_search_tool_clothing_sizes'));
    expect(row, findsOneWidget);

    await tester.tap(row, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Tool modal is visible and routed through clothing lookup surface.
    expect(
      find.byKey(const ValueKey('tool_title_clothing_sizes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_lookup_matrix_clothing_sizes')),
      findsOneWidget,
    );
  });
}
