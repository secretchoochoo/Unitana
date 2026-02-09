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
  testWidgets('Baking supports fraction input and cooking units', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'baking');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_baking')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tool_title_baking')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('tool_input_baking')),
      '1/2',
    );
    await tester.tap(find.byKey(const ValueKey('tool_run_baking')));
    await tester.pumpAndSettle(const Duration(milliseconds: 150));

    expect(find.textContaining('ml'), findsWidgets);
    expect(find.textContaining('Invalid input'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tool_unit_from_baking')));
    await tester.pumpAndSettle();

    expect(find.text('tsp'), findsWidgets);
    expect(find.text('tbsp'), findsWidgets);
  });
}
