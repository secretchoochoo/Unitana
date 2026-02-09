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
  testWidgets('Shoes matrix includes expanded range and AU column', (
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
    expect(find.text('AU'), findsWidgets);
    expect(
      find.byKey(const ValueKey('tool_lookup_matrix_row_shoe_sizes_shoe_14')),
      findsOneWidget,
    );
  });

  testWidgets('Paper matrix includes JIS standards and ARCH D row', (
    tester,
  ) async {
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
    expect(find.text('JIS'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey('tool_lookup_matrix_row_paper_sizes_paper_arch_d'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Mattress matrix includes UK/AU columns and California King row',
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
      expect(find.text('UK'), findsWidgets);
      expect(find.text('AU'), findsWidgets);
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
