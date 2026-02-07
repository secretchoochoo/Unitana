import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

Future<void> _openToolPicker(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('dashboard_tools_button')));
  await tester.pumpAndSettle();
}

Future<void> _searchTool(WidgetTester tester, String query) async {
  await tester.enterText(
    find.byKey(const ValueKey('toolpicker_search')),
    query,
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 150));
}

void main() {
  testWidgets('Unit Price Helper computes normalized values and compare text', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'unit price');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_unit_price_helper')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_title_unit_price_helper')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('tool_unit_price_price_unit_price_helper_a')),
      '4.99',
    );
    await tester.enterText(
      find.byKey(const ValueKey('tool_unit_price_qty_unit_price_helper_a')),
      '500',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    await tester.tap(
      find.byKey(const ValueKey('tool_unit_price_compare_unit_price_helper')),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    await tester.enterText(
      find.byKey(const ValueKey('tool_unit_price_price_unit_price_helper_b')),
      '6.49',
    );
    await tester.enterText(
      find.byKey(const ValueKey('tool_unit_price_qty_unit_price_helper_b')),
      '750',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    expect(
      find.byKey(const ValueKey('tool_unit_price_result_unit_price_helper')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('tool_unit_price_compare_result_unit_price_helper'),
      ),
      findsOneWidget,
    );
  });
}
