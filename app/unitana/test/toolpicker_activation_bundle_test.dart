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
  testWidgets('world time map is enabled and opens world map modal', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'world time map');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_world_clock_delta')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_title_world_clock_delta')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_time_world_map_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_time_dual_analog_row')),
      findsNothing,
    );
  });

  testWidgets('jet lag delta is enabled and opens Time modal', (tester) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'jet lag');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_jet_lag_delta')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_title_jet_lag_delta')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_time_planner_card')),
      findsOneWidget,
    );
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

  testWidgets('paper sizes is enabled and opens lookup modal', (tester) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'paper sizes');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_paper_sizes')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_title_paper_sizes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_lookup_matrix_paper_sizes')),
      findsOneWidget,
    );
  });

  testWidgets('mattress sizes is enabled and opens lookup modal', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'mattress sizes');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_mattress_sizes')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_title_mattress_sizes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_lookup_matrix_mattress_sizes')),
      findsOneWidget,
    );
  });

  testWidgets('baking appears in picker and opens Baking modal', (
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
  });

  testWidgets(
    'timezone lookup is enabled and opens Time Zone Converter modal',
    (tester) async {
      await pumpDashboardForTest(tester);
      await _openToolPicker(tester);
      await _searchTool(tester, 'time zone');

      await tester.tap(
        find.byKey(const ValueKey('toolpicker_search_tool_timezone_lookup')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('tool_title_time_zone_converter')),
        findsOneWidget,
      );
    },
  );

  testWidgets('weather summary opens weather sheet (not converter modal)', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'weather');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_weather_summary')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('weather_summary_sheet')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tool_title_weather_summary')),
      findsNothing,
    );
  });

  testWidgets('tip helper is enabled and opens dedicated tip modal', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'tip helper');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_tip_helper')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tool_title_tip_helper')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tool_tip_result_tip_helper')),
      findsOneWidget,
    );
  });

  testWidgets('sales tax / VAT helper is enabled and opens dedicated modal', (
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
  });

  testWidgets('price compare is enabled and opens dedicated modal', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'price compare');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_unit_price_helper')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_title_unit_price_helper')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_unit_price_result_unit_price_helper')),
      findsOneWidget,
    );
  });

  testWidgets('energy is enabled and performs conversion in modal', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'energy');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_energy')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tool_title_energy')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('tool_input_energy')),
      '500',
    );
    await tester.tap(find.byKey(const ValueKey('tool_run_energy')));
    await tester.pumpAndSettle();

    final result = find.byKey(const ValueKey('tool_result_energy'));
    expect(result, findsOneWidget);
    expect(
      find.descendant(of: result, matching: find.byType(RichText)),
      findsWidgets,
    );
  });

  testWidgets('pace is enabled and performs conversion in modal', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'pace');

    await tester.tap(find.byKey(const ValueKey('toolpicker_search_tool_pace')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tool_title_pace')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('tool_input_pace')),
      '5:00',
    );
    await tester.tap(find.byKey(const ValueKey('tool_run_pace')));
    await tester.pumpAndSettle();

    final result = find.byKey(const ValueKey('tool_result_pace'));
    expect(result, findsOneWidget);
    expect(
      find.descendant(of: result, matching: find.byType(RichText)),
      findsWidgets,
    );
  });

  testWidgets('cups/grams estimates is enabled and opens lookup modal', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'grams estimates');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_cups_grams_estimates')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_title_cups_grams_estimates')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tool_lookup_result_cups_grams_estimates')),
      findsOneWidget,
    );
  });

  testWidgets('hydration is enabled and opens dedicated helper modal', (
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
  });
}
