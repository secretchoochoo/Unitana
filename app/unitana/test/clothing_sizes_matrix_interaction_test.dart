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
  testWidgets(
    'Clothing Sizes matrix filters by garment group and surfaces missing mappings',
    (tester) async {
      await pumpDashboardForTest(tester);
      await _openToolPicker(tester);
      await _searchTool(tester, 'clothing sizes');

      await tester.tap(
        find.byKey(const ValueKey('toolpicker_search_tool_clothing_sizes')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('tool_lookup_matrix_clothing_sizes')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('tool_lookup_disclaimer_clothing_sizes')),
        findsOneWidget,
      );
      expect(find.textContaining('Approximate reference only'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('tool_lookup_group_chip_clothing_sizes_women_tops'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('tool_lookup_group_summary_clothing_sizes')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'tool_lookup_matrix_cell_clothing_sizes_cloth_w_tops_xs_US',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'tool_lookup_matrix_row_clothing_sizes_cloth_m_tops_m',
          ),
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('tool_lookup_group_chip_clothing_sizes_men_tops'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey(
            'tool_lookup_matrix_cell_clothing_sizes_cloth_m_tops_m_US',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'tool_lookup_matrix_row_clothing_sizes_cloth_w_tops_s',
          ),
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(
          const ValueKey('tool_lookup_group_chip_clothing_sizes_outerwear'),
        ),
      );
      await tester.pumpAndSettle();

      final targetRow = find.byKey(
        const ValueKey(
          'tool_lookup_matrix_row_clothing_sizes_cloth_outer_unisex_xl',
        ),
      );
      final matrixScrollable = find.descendant(
        of: find.byKey(const ValueKey('tool_lookup_matrix_clothing_sizes')),
        matching: find.byType(Scrollable),
      );
      for (var i = 0; i < 4 && targetRow.evaluate().isEmpty; i++) {
        await tester.drag(matrixScrollable.first, const Offset(0, -180));
        await tester.pumpAndSettle(const Duration(milliseconds: 80));
      }
      expect(targetRow, findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('tool_lookup_matrix_next_clothing_sizes')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: targetRow, matching: find.text('—')),
        findsWidgets,
      );
    },
  );
}
