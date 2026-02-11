import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

Future<void> _openToolPicker(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('dashboard_tools_button')));
  await tester.pumpAndSettle(const Duration(milliseconds: 250));
}

Future<void> _openToolBySearch(
  WidgetTester tester,
  String toolId,
  String q,
) async {
  await _openToolPicker(tester);
  await tester.enterText(find.byKey(const ValueKey('toolpicker_search')), q);
  await tester.pumpAndSettle(const Duration(milliseconds: 200));
  await tester.tap(find.byKey(ValueKey('toolpicker_search_tool_$toolId')));
  await tester.pumpAndSettle(const Duration(milliseconds: 250));
}

void main() {
  testWidgets(
    'converter units row keeps consistent typography without scaling',
    (tester) async {
      await pumpDashboardForTest(tester);

      await _openToolBySearch(tester, 'speed', 'speed');

      final speedUnits = find.byKey(const ValueKey('tool_units_speed'));
      expect(speedUnits, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('tool_units_row_speed')),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
      final speedText = tester.widget<Text>(speedUnits);
      final speedFontSize = speedText.style?.fontSize;
      expect(speedText.style?.fontWeight, FontWeight.w800);
      final speedUnitsRow = tester.widget<Row>(
        find.byKey(const ValueKey('tool_units_row_speed')),
      );
      expect(speedUnitsRow.children.length, 3);
      expect(speedUnitsRow.children[0], isA<Expanded>());
      expect(speedUnitsRow.children[1], isA<SizedBox>());
      expect(speedUnitsRow.children[2], isA<Align>());

      await tester.tap(find.byKey(const ValueKey('tool_close_speed')));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      await _openToolBySearch(tester, 'distance', 'distance');

      final distanceUnits = find.byKey(const ValueKey('tool_units_distance'));
      expect(distanceUnits, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('tool_units_row_distance')),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
      final distanceFromButton = find.byKey(
        const ValueKey('tool_unit_from_distance'),
      );
      expect(distanceFromButton, findsOneWidget);
      final distanceText = tester.widget<Text>(
        find
            .descendant(of: distanceFromButton, matching: find.byType(Text))
            .first,
      );
      expect(distanceText.style?.fontWeight, FontWeight.w800);
      expect(distanceText.style?.fontSize, isNotNull);
      expect(distanceText.style!.fontSize!, greaterThanOrEqualTo(14));
      expect(speedFontSize, isNotNull);
    },
  );
}
