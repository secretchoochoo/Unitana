import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

Future<void> _openToolPicker(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('dashboard_tools_button')));
  await tester.pumpAndSettle(const Duration(milliseconds: 250));
}

void main() {
  testWidgets('Pace modal converts min/km to min/mi and records history', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);

    await tester.enterText(
      find.byKey(const ValueKey('toolpicker_search')),
      'pace',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('toolpicker_search_tool_pace')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    expect(find.byKey(const ValueKey('tool_title_pace')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('tool_input_pace')),
      '5:00',
    );
    await tester.tap(find.byKey(const ValueKey('tool_run_pace')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final resultRoot = find.byKey(const ValueKey('tool_result_pace'));
    expect(resultRoot, findsOneWidget);
    final resultText = tester
        .widget<RichText>(
          find
              .descendant(of: resultRoot, matching: find.byType(RichText))
              .first,
        )
        .text
        .toPlainText();
    expect(resultText, contains('5:00 min/km'));
    expect(resultText, contains('8:03 min/mi'));
    expect(
      find.byKey(const ValueKey('tool_pace_insights_card')),
      findsOneWidget,
    );
    expect(find.textContaining('5K'), findsWidgets);
    expect(find.byKey(const ValueKey('tool_pace_goal_input')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('tool_pace_goal_input')),
      '26:00',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    expect(find.textContaining('Required pace:'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('tool_history_pace_0')),
      120,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('tool_scroll_pace')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('tool_history_pace_0')), findsOneWidget);
  });
}
