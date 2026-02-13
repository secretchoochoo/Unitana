import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    'Clothing Sizes matrix shows disclaimer, copy, and missing mappings',
    (tester) async {
      String lastClipboardText = '';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          switch (call.method) {
            case 'Clipboard.setData':
              final args =
                  (call.arguments as Map?) ?? const <String, dynamic>{};
              lastClipboardText = (args['text']?.toString() ?? '').trim();
              return null;
            case 'Clipboard.getData':
              return <String, dynamic>{'text': lastClipboardText};
            default:
              return null;
          }
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

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

      await tester.tap(
        find.byKey(
          const ValueKey(
            'tool_lookup_matrix_cell_clothing_sizes_cloth_w_tops_s_US',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));
      expect(lastClipboardText, '4-6');

      await tester.tap(
        find.byKey(const ValueKey('tool_lookup_matrix_next_clothing_sizes')),
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
      for (var i = 0; i < 8 && targetRow.evaluate().isEmpty; i++) {
        await tester.drag(matrixScrollable.first, const Offset(0, -220));
        await tester.pumpAndSettle(const Duration(milliseconds: 80));
      }
      expect(targetRow, findsOneWidget);
      expect(
        find.descendant(of: targetRow, matching: find.text('—')),
        findsWidgets,
      );
    },
  );
}
