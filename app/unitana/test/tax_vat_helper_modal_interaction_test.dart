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
  testWidgets('Tax/VAT Helper calculates add-on and inclusive modes', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'sales tax');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_tax_vat_helper')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_title_tax_vat_helper')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_tax_result_tax_vat_helper')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('tool_tax_amount_tax_vat_helper')),
      '120',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    final chips = find.byType(ChoiceChip);
    expect(chips, findsWidgets);
    await tester.tap(chips.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    await tester.tap(
      find.byKey(const ValueKey('tool_tax_mode_tax_vat_helper_inclusive')),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    final richLines = find.descendant(
      of: find.byKey(const ValueKey('tool_tax_result_tax_vat_helper')),
      matching: find.byType(RichText),
    );
    expect(richLines, findsWidgets);

    final text = richLines
        .evaluate()
        .map((e) => (e.widget as RichText).text.toPlainText())
        .join('\n');

    expect(text, contains('Subtotal'));
    expect(text, contains('Tax ('));
    expect(text, contains('Total'));
  });
}
