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
  testWidgets('Hydration helper computes estimate with guardrail copy', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'hydration');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_hydration')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tool_title_hydration')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tool_hydration_result_hydration')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('tool_hydration_weight_hydration')),
      '70',
    );
    await tester.enterText(
      find.byKey(const ValueKey('tool_hydration_exercise_hydration')),
      '45',
    );
    await tester.tap(
      find.byKey(const ValueKey('tool_hydration_climate_hydration_warm')),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));

    final rich = find.descendant(
      of: find.byKey(const ValueKey('tool_hydration_result_hydration')),
      matching: find.byType(RichText),
    );
    expect(rich, findsWidgets);
    final text = rich
        .evaluate()
        .map((e) => (e.widget as RichText).text.toPlainText())
        .join('\n');

    expect(text, contains('Daily fluid estimate'));
    expect(text, contains('L ('));
    expect(text, contains('fl oz'));
    expect(text, contains('Non-medical estimate'));
  });
}
