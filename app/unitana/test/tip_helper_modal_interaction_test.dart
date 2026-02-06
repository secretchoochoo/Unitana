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
  testWidgets('Tip Helper calculates tip, split, and rounding output', (
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

    await tester.enterText(
      find.byKey(const ValueKey('tool_tip_amount_tip_helper')),
      '120',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    final chips = find.byType(ChoiceChip);
    expect(chips, findsWidgets);
    await tester.tap(chips.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    await tester.tap(
      find.byKey(const ValueKey('tool_tip_split_plus_tip_helper')),
    );
    await tester.tap(
      find.byKey(const ValueKey('tool_tip_split_plus_tip_helper')),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    await tester.tap(
      find.byKey(const ValueKey('tool_tip_round_tip_helper_up')),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    final richLines = find.descendant(
      of: find.byKey(const ValueKey('tool_tip_result_tip_helper')),
      matching: find.byType(RichText),
    );
    expect(richLines, findsWidgets);

    final text = richLines
        .evaluate()
        .map((e) => (e.widget as RichText).text.toPlainText())
        .join('\n');

    expect(text, contains('Tip ('));
    expect(text, contains('Total'));
    expect(text, contains('Per person (3)'));
  });
}
