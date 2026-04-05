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
  testWidgets('Tax/VAT tool uses plain-language modes and calculates totals', (
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
    expect(find.text('Add tax to price'), findsOneWidget);
    expect(find.text('Find tax in total'), findsOneWidget);
    expect(find.textContaining('Enter the exact local rate'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Rate'), findsOneWidget);

    final rateField = find.byKey(
      const ValueKey('tool_tax_rate_tax_vat_helper'),
    );
    expect(rateField, findsOneWidget);
    expect(find.text('23'), findsWidgets);

    final inclusiveChip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('tool_tax_mode_tax_vat_helper_inclusive')),
    );
    expect(inclusiveChip.selected, isTrue);

    await tester.enterText(
      find.byKey(const ValueKey('tool_tax_amount_tax_vat_helper')),
      '120',
    );
    await tester.enterText(rateField, '23');
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
    expect(text, contains('Tax (23%)'));
    expect(text, contains('Total'));
    expect(
      find.text('Use this when tax or VAT is already included in the total.'),
      findsOneWidget,
    );
  });
}
