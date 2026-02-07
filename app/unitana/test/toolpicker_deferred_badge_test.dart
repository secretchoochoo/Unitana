import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_test_helpers.dart';

void main() {
  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
  }

  testWidgets('deferred tools show Deferred badge and rationale in picker', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await openPicker(tester);

    await tester.enterText(
      find.byKey(const ValueKey('toolpicker_search')),
      'clothing',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final row = find.byKey(const Key('toolpicker_search_tool_clothing_sizes'));
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text('Deferred')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.textContaining('High brand variance'),
      ),
      findsOneWidget,
    );

    await tester.tap(row, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Disabled row should not open a tool modal.
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tool_title_clothing_sizes')),
      findsNothing,
    );
  });
}
