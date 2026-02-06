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
  testWidgets('Mattress Sizes shows matrix table with copy + row reselection', (
    tester,
  ) async {
    String lastClipboardText = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            final args = (call.arguments as Map?) ?? const <String, dynamic>{};
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
    await _searchTool(tester, 'mattress sizes');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_mattress_sizes')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_lookup_matrix_mattress_sizes')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('tool_lookup_matrix_row_mattress_sizes_matt_queen'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'tool_lookup_matrix_cell_mattress_sizes_matt_queen_from',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
    expect(lastClipboardText, contains('Queen (60 x 80 in)'));

    await tester.tap(
      find.byKey(
        const ValueKey('tool_lookup_matrix_size_mattress_sizes_matt_full'),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    final resultRichTextFinder = find
        .descendant(
          of: find.byKey(const ValueKey('tool_lookup_result_mattress_sizes')),
          matching: find.byType(RichText),
        )
        .first;
    expect(resultRichTextFinder, findsOneWidget);
    final resultRichText = tester.widget<RichText>(resultRichTextFinder);
    final resultText = resultRichText.text.toPlainText();

    expect(resultText, contains('Full (54 x 75 in)'));
    expect(resultText, contains('Double (140 x 200 cm)'));
  });
}
