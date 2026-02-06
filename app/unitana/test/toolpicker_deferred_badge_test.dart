import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
  }

  testWidgets('deferred tools show Deferred badge and rationale in picker', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await openPicker(tester);

    await tester.enterText(
      find.byKey(const ValueKey('toolpicker_search')),
      'sales tax',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final taxRow = find.byKey(
      const Key('toolpicker_search_tool_tax_vat_helper'),
    );
    expect(taxRow, findsOneWidget);
    expect(
      find.descendant(of: taxRow, matching: find.text('Deferred')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: taxRow,
        matching: find.textContaining('country/region tax model'),
      ),
      findsOneWidget,
    );

    await tester.tap(taxRow, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Disabled row should not open a tool modal.
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tool_title_tax_vat_helper')),
      findsNothing,
    );
  });
}
