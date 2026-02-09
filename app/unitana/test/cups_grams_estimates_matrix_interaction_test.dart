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
  testWidgets('Cups/grams estimates matrix supports copy + row reselection', (
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
    await _searchTool(tester, 'grams estimates');

    await tester.tap(
      find.byKey(const ValueKey('toolpicker_search_tool_cups_grams_estimates')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tool_lookup_matrix_cups_grams_estimates')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'tool_lookup_matrix_cell_cups_grams_estimates_cupsgrams_flour_to',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(lastClipboardText, contains('120 g'));

    await tester.tap(
      find.byKey(
        const ValueKey(
          'tool_lookup_matrix_size_cups_grams_estimates_cupsgrams_sugar',
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 120));

    final resultRichTextFinder = find
        .descendant(
          of: find.byKey(
            const ValueKey('tool_lookup_result_cups_grams_estimates'),
          ),
          matching: find.byType(RichText),
        )
        .first;
    expect(resultRichTextFinder, findsOneWidget);
    final resultRichText = tester.widget<RichText>(resultRichTextFinder);
    final resultText = resultRichText.text.toPlainText();

    expect(resultText, contains('Cup: 1 cup'));
    expect(resultText, contains('Weight: 200 g'));
  });
}
