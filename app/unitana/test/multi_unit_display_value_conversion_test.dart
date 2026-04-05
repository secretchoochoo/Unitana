import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

Future<void> _openTool(WidgetTester tester, String query, String toolId) async {
  await tester.tap(find.byKey(const ValueKey('dashboard_tools_button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('toolpicker_search')),
    query,
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 150));
  await tester.tap(find.byKey(ValueKey('toolpicker_search_tool_$toolId')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Hydration converts displayed value when switching units', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openTool(tester, 'hydration', 'hydration');

    final field = find.byKey(const ValueKey('tool_hydration_weight_hydration'));
    await tester.enterText(field, '70');
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('tool_hydration_unit_hydration_lb')),
    );
    await tester.pumpAndSettle();

    var textField = tester.widget<TextField>(field);
    expect(textField.controller?.text, '154.3');

    await tester.tap(
      find.byKey(const ValueKey('tool_hydration_unit_hydration_kg')),
    );
    await tester.pumpAndSettle();

    textField = tester.widget<TextField>(field);
    expect(textField.controller?.text, '70');
  });

  testWidgets('Energy converts displayed value when switching units', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openTool(tester, 'energy', 'energy');

    final field = find.byKey(const ValueKey('tool_energy_weight_input'));
    await tester.enterText(field, '70');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tool_energy_weight_unit_lb')));
    await tester.pumpAndSettle();

    var textField = tester.widget<TextField>(field);
    expect(textField.controller?.text, '154.3');

    await tester.tap(find.byKey(const ValueKey('tool_energy_weight_unit_kg')));
    await tester.pumpAndSettle();

    textField = tester.widget<TextField>(field);
    expect(textField.controller?.text, '70');
  });
}
