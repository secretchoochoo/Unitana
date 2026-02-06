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
  testWidgets('world clock delta is enabled and opens Time modal', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'world clock');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_world_clock_delta')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tool_title_time')), findsOneWidget);
  });

  testWidgets('jet lag delta is enabled and opens Time modal', (tester) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'jet lag');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_jet_lag_delta')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tool_title_time')), findsOneWidget);
  });

  testWidgets('data storage is enabled and performs conversion in modal', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'data storage');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_data_storage')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_title_data_storage')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('tool_input_data_storage')),
      '1',
    );
    await tester.tap(find.byKey(const ValueKey('tool_run_data_storage')));
    await tester.pumpAndSettle();

    final result = find.byKey(const ValueKey('tool_result_data_storage'));
    expect(result, findsOneWidget);
    expect(
      find.descendant(of: result, matching: find.byType(RichText)),
      findsWidgets,
    );
  });
}
