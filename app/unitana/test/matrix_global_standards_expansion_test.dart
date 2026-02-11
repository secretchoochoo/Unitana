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
  testWidgets('Shoes matrix includes AU column and stable row rendering', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);
    await _openToolPicker(tester);
    await _searchTool(tester, 'shoe');
    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_shoe_sizes')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_lookup_matrix_shoe_sizes')),
      findsOneWidget,
    );
    expect(find.text('US M'), findsWidgets);
    expect(find.text('US W'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey('tool_lookup_matrix_next_shoe_sizes')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('tool_lookup_matrix_next_shoe_sizes')),
    );
    await tester.pumpAndSettle();
    expect(find.text('AU'), findsWidgets);
    expect(
      find.byKey(const ValueKey('tool_lookup_matrix_row_shoe_sizes_shoe_9')),
      findsOneWidget,
    );
    final shoe17 = find.byKey(
      const ValueKey('tool_lookup_matrix_row_shoe_sizes_shoe_17'),
    );
    final matrixScrollable = find.descendant(
      of: find.byKey(const ValueKey('tool_lookup_matrix_shoe_sizes')),
      matching: find.byType(Scrollable),
    );
    for (var i = 0; i < 8 && shoe17.evaluate().isEmpty; i++) {
      await tester.drag(matrixScrollable.first, const Offset(0, -220));
      await tester.pumpAndSettle(const Duration(milliseconds: 80));
    }
    expect(shoe17, findsOneWidget);
  });

  testWidgets(
    'Paper matrix includes JIS + ANSI/ARCH standards and ARCH D row',
    (tester) async {
      await pumpDashboardForTest(tester);
      await _openToolPicker(tester);
      await _searchTool(tester, 'paper sizes');
      await tester.tap(
        find.byKey(const ValueKey('toolpicker_search_tool_paper_sizes')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('tool_lookup_matrix_paper_sizes')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('tool_lookup_matrix_next_paper_sizes')),
      );
      await tester.pumpAndSettle();
      expect(find.text('JIS'), findsWidgets);
      expect(find.text('ANSI/ARCH'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('tool_lookup_matrix_row_paper_sizes_paper_arch_d'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Mattress matrix includes UK/AU/JP columns and California King row',
    (tester) async {
      await pumpDashboardForTest(tester);
      await _openToolPicker(tester);
      await _searchTool(tester, 'mattress sizes');
      await tester.tap(
        find.byKey(const ValueKey('toolpicker_search_tool_mattress_sizes')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('tool_lookup_matrix_mattress_sizes')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('tool_lookup_matrix_next_mattress_sizes')),
      );
      await tester.pumpAndSettle();
      expect(find.text('UK'), findsWidgets);
      expect(find.text('AU'), findsWidgets);
      await tester.tap(
        find.byKey(const ValueKey('tool_lookup_matrix_next_mattress_sizes')),
      );
      await tester.pumpAndSettle();
      expect(find.text('JP'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey(
            'tool_lookup_matrix_row_mattress_sizes_matt_super_king_us',
          ),
        ),
        findsOneWidget,
      );
    },
  );
}
