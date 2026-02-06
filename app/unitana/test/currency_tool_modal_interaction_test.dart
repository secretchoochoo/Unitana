import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Allow runtime font fetching in widget/golden tests so GoogleFonts can resolve
  // required font files during tests (avoids bundling font assets in-repo).
  GoogleFonts.config.allowRuntimeFetching = true;

  const arrow = '→';

  double? parseFirstNumber(String s) {
    final m = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(s);
    return m == null ? null : double.tryParse(m.group(0) ?? '');
  }

  testWidgets('Currency modal: convert, history copy, and long-press edit', (
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

    // Open ToolPickerSheet via the dedicated Tools button.
    await tester.tap(find.byKey(const ValueKey('dashboard_tools_button')));
    await tester.pumpAndSettle();

    // Search-first discovery is the stable contract.
    final searchField = find.byKey(const ValueKey('toolpicker_search'));
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'currency');
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final row = find.byKey(
      const ValueKey('toolpicker_search_tool_currency_convert'),
    );
    expect(row, findsOneWidget);
    await tester.tap(row);
    await tester.pumpAndSettle();

    // Modal should open.
    final fromBtn = find.byKey(
      const ValueKey('tool_unit_from_currency_convert'),
    );
    final toBtn = find.byKey(const ValueKey('tool_unit_to_currency_convert'));
    expect(fromBtn, findsOneWidget);
    expect(toBtn, findsOneWidget);

    String readCode(Finder button) {
      final codeText = find.descendant(
        of: button,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Text &&
              RegExp(r'^[A-Z]{3}$').hasMatch((w.data ?? '').trim()),
        ),
      );
      expect(codeText, findsOneWidget);
      return (tester.widget<Text>(codeText).data ?? '').trim();
    }

    final from = readCode(fromBtn);
    final to = readCode(toBtn);
    expect('$from$arrow$to', contains(arrow));

    // MVP currency engine uses a fixed fallback EUR↔USD rate when live rates
    // are not provided.
    const rate = 1.10;
    const inputValue = 10.0;
    final expectedOut = (from == to)
        ? inputValue
        : (from == 'EUR' && to == 'USD')
        ? inputValue * rate
        : (from == 'USD' && to == 'EUR')
        ? inputValue / rate
        : inputValue;

    // Run a conversion.
    await tester.enterText(
      find.byKey(const ValueKey('tool_input_currency_convert')),
      inputValue.toStringAsFixed(0),
    );
    await tester.tap(find.byKey(const ValueKey('tool_run_currency_convert')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final resultRoot = find.byKey(
      const ValueKey('tool_result_currency_convert'),
    );
    expect(resultRoot, findsOneWidget);

    final rich = find.descendant(
      of: resultRoot,
      matching: find.byType(RichText),
    );
    expect(rich, findsAtLeastNWidgets(1));

    final resultLine = tester.widget<RichText>(rich.first).text.toPlainText();
    expect(resultLine, contains(arrow));

    final outNumber = parseFirstNumber(resultLine.split(arrow).last);
    expect(outNumber, isNotNull);
    expect(outNumber!, closeTo(expectedOut, 0.06));

    // First history line appears.
    final history0 = find.byKey(
      const ValueKey('tool_history_currency_convert_0'),
    );
    expect(history0, findsOneWidget);

    // The modal content can scroll on smaller test surfaces.
    //
    // Note: The modal contains nested scrollables (TextField horizontal, history
    // list vertical). Rely on ensureVisible rather than assuming a single
    // Scrollable descendant.
    final scrollRoot = find.byKey(
      const ValueKey('tool_scroll_currency_convert'),
    );
    expect(scrollRoot, findsOneWidget);
    await tester.ensureVisible(history0);
    await tester.pumpAndSettle();

    // Tap history item to copy output (app copies the numeric portion).
    await tester.tap(history0.hitTestable());
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(lastClipboardText, expectedOut.toStringAsFixed(2));

    // Long-press copies the original input (no edit/restore).
    await tester.longPress(history0.hitTestable());
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text('Copied input'), findsOneWidget);
    expect(lastClipboardText, '10');

    final inputField = find.byKey(
      const ValueKey('tool_input_currency_convert'),
    );
    expect(inputField, findsOneWidget);
    expect(tester.widget<TextField>(inputField).controller?.text, '10');
  });
}
