import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unitana/features/dashboard/widgets/tool_modal_bottom_sheet.dart';

import 'dashboard_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Prevent runtime font fetching in widget tests (avoids incidental HttpClient
  // creation and keeps the suite deterministic).
  GoogleFonts.config.allowRuntimeFetching = false;

  const arrow = '→';

  String resolveToolIdFromModal(WidgetTester tester, Finder modalRoot) {
    final inputFinder = find.descendant(
      of: modalRoot,
      matching: find.byWidgetPredicate((w) {
        if (w is! TextField) return false;
        final key = w.key;
        return key is ValueKey<String> && key.value.startsWith('tool_input_');
      }),
    );
    expect(inputFinder, findsOneWidget);

    final input = tester.widget<TextField>(inputFinder);
    final key = input.key as ValueKey<String>;
    return key.value.substring('tool_input_'.length);
  }

  String readUnitArrowLabel(
    WidgetTester tester,
    Finder modalRoot,
    String toolId,
  ) {
    final label = find.descendant(
      of: modalRoot,
      matching: find.byKey(ValueKey('tool_units_$toolId')),
    );
    expect(label, findsOneWidget);
    return tester.widget<Text>(label).data ?? '';
  }

  String readResultLine(WidgetTester tester, String toolId) {
    final resultRoot = find.byKey(ValueKey('tool_result_$toolId'));
    expect(resultRoot, findsOneWidget);

    final line = find.descendant(
      of: resultRoot,
      matching: find.byType(RichText),
    );
    expect(line, findsAtLeastNWidgets(1));

    final rich = tester.widget<RichText>(line.first);
    return rich.text.toPlainText();
  }

  double? parseFirstNumber(String s) {
    final m = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(s);
    return m == null ? null : double.tryParse(m.group(0) ?? '');
  }

  testWidgets('Temperature: convert, unit swap, and long-press edit (regression)', (
    tester,
  ) async {
    await pumpDashboardForTest(tester, surfaceSize: const Size(320, 568));

    // Intercept Clipboard writes so the test can assert copy behavior without
    // relying on transient notice UI timing.
    final clipboardWrites = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = (call.arguments as Map?) ?? const {};
            final text = (args['text'] ?? '') as String;
            clipboardWrites.add(text);
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    // Open ToolPickerSheet via the dedicated Tools button.
    await tester.tap(find.byKey(const Key('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Prefer ToolPicker search so the test stays resilient to lens ordering.
    final searchField = find.byKey(const ValueKey('toolpicker_search'));
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Temperature');
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final toolRow = find.byKey(
      const ValueKey('toolpicker_search_tool_temperature'),
    );
    expect(toolRow, findsOneWidget);
    // Ensure the row is in the visible viewport before tapping.
    final scrollable = find.ancestor(
      of: toolRow,
      matching: find.byType(Scrollable),
    );
    if (scrollable.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        toolRow,
        120,
        scrollable: scrollable.first,
      );
    } else {
      await tester.ensureVisible(toolRow);
    }
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(toolRow.hitTestable());
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final modal = find.byType(ToolModalBottomSheet);
    expect(modal, findsOneWidget);

    final toolId = resolveToolIdFromModal(tester, modal);

    // Header + CTA surfaces (ensure they coexist cleanly on smallest size).
    final titleKey = ValueKey('tool_title_$toolId');
    final addWidgetKey = ValueKey('tool_add_widget_$toolId');
    expect(find.byKey(titleKey), findsOneWidget);
    expect(find.byKey(addWidgetKey), findsOneWidget);

    final titleRect = tester.getRect(find.byKey(titleKey));
    final addRect = tester.getRect(find.byKey(addWidgetKey));
    expect(addRect.top, greaterThan(titleRect.bottom));

    // Determine direction from the units label so we can assert the exact math.
    final unitsBefore = readUnitArrowLabel(tester, modal, toolId);
    expect(unitsBefore, contains(arrow));

    final fromUnit = unitsBefore.split(arrow).first.trim().toLowerCase();
    final fromIsF = fromUnit.contains('f');

    final inputValue = fromIsF ? '32' : '0';
    final expectedOut = fromIsF ? 0.0 : 32.0;
    final expectedUnit = fromIsF ? 'c' : 'f';

    final inputKey = ValueKey('tool_input_$toolId');
    await tester.enterText(find.byKey(inputKey), inputValue);

    await tester.tap(find.byKey(ValueKey('tool_run_$toolId')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final resultLine = readResultLine(tester, toolId);
    expect(resultLine, contains(arrow));

    final outputPart = resultLine.split(arrow).last.trim().toLowerCase();
    expect(outputPart, contains(expectedUnit));

    final outputNumber = parseFirstNumber(outputPart);
    expect(outputNumber, isNotNull);
    expect(outputNumber!, closeTo(expectedOut, 0.25));

    // Unit swap should update the arrow label by key.
    await tester.tap(find.byKey(ValueKey('tool_swap_$toolId')));
    await tester.pumpAndSettle(const Duration(milliseconds: 220));

    final unitsAfter = readUnitArrowLabel(tester, modal, toolId);
    expect(unitsAfter, isNot(equals(unitsBefore)));

    // Copy behaviors: tap copies the result, long-press copies the original input.
    final history0 = find.byKey(ValueKey('tool_history_${toolId}_0'));

    // The modal contains nested scrollables (TextField horizontal, history list
    // vertical). On the smallest surface, History may not be built until the
    // main ListView is scrolled. Avoid assuming a single Scrollable descendant.
    final scrollRoot = find.byKey(const ValueKey('tool_scroll_temperature'));
    expect(scrollRoot, findsOneWidget);

    // Nudge the main ListView until the first history row is in the tree.
    // (ListView builds lazily; cache extents can vary across Flutter versions.)
    for (var i = 0; i < 6 && history0.evaluate().isEmpty; i++) {
      await tester.drag(scrollRoot, const Offset(0, -240));
      await tester.pumpAndSettle(const Duration(milliseconds: 120));
    }
    expect(history0, findsOneWidget);

    await tester.ensureVisible(history0);
    await tester.pumpAndSettle();

    final clipboardCountBeforeTap = clipboardWrites.length;
    await tester.tap(history0.hitTestable());

    // Avoid pumpAndSettle here. The modal includes animated and periodic UI
    // (e.g., TextField cursor blink) plus a 2s notice auto-dismiss timer.
    // pumpAndSettle may fast-forward long enough for the notice to disappear,
    // causing a flaky false-negative.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    // Tap on a history row should copy the converted result.
    expect(clipboardWrites.length, clipboardCountBeforeTap + 1);
    expect(clipboardWrites.last, isNotEmpty);

    final clipboardCountBeforeLongPress = clipboardWrites.length;

    await tester.longPress(history0.hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));

    // Long-press on a history row should copy the original input value.
    expect(clipboardWrites.length, clipboardCountBeforeLongPress + 1);
    expect(clipboardWrites.last, isNotEmpty);

    // Long-press no longer edits the input field.
    final editable = find.descendant(
      of: find.byKey(inputKey),
      matching: find.byType(EditableText),
    );
    expect(editable, findsOneWidget);
    final state = tester.state<EditableTextState>(editable);
    expect(state.textEditingValue.text, inputValue);

    expect(tester.takeException(), isNull);
  });
}
