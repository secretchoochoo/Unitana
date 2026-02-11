import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/features/dashboard/widgets/tool_modal_bottom_sheet.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Allow runtime font fetching in widget/golden tests so GoogleFonts can resolve
  // required font files during tests (avoids bundling font assets in-repo).
  GoogleFonts.config.allowRuntimeFetching = true;

  const arrow = '→';

  UnitanaAppState buildSeededState() {
    final storage = UnitanaStorage();
    final state = UnitanaAppState(storage);

    state.places = const [
      Place(
        id: 'home',
        type: PlaceType.living,
        name: 'Home',
        cityName: 'Denver',
        countryCode: 'US',
        timeZoneId: 'America/Denver',
        unitSystem: 'imperial',
        use24h: false,
      ),
      Place(
        id: 'dest',
        type: PlaceType.visiting,
        name: 'Destination',
        cityName: 'Lisbon',
        countryCode: 'PT',
        timeZoneId: 'Europe/Lisbon',
        unitSystem: 'metric',
        use24h: true,
      ),
    ];
    state.defaultPlaceId = 'home';

    return state;
  }

  Future<void> pumpDashboard(WidgetTester tester, UnitanaAppState state) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        home: DashboardScreen(state: state),
      ),
    );

    // The dashboard has live elements; avoid full pumpAndSettle timeouts.
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

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

  String readFromUnitLabel(
    WidgetTester tester,
    Finder modalRoot,
    String toolId,
  ) {
    final fromButton = find.descendant(
      of: modalRoot,
      matching: find.byKey(ValueKey('tool_unit_from_$toolId')),
    );
    expect(fromButton, findsOneWidget);
    final fromText = find.descendant(
      of: fromButton,
      matching: find.byType(Text),
    );
    expect(fromText, findsAtLeastNWidgets(1));
    return tester.widget<Text>(fromText.first).data?.trim() ?? '';
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

  testWidgets('Liquid Volume: convert, history copy, and long-press edit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

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

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Open ToolPickerSheet via the dedicated Tools button.
    await tester.tap(find.byKey(const Key('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Prefer ToolPicker search so the test is resilient to lens collapse/scroll
    // behavior and ordering changes.
    final searchField = find.byKey(const ValueKey('toolpicker_search'));
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Liquids');
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final toolRow = find.byKey(
      const ValueKey('toolpicker_search_tool_liquids'),
    );
    expect(toolRow, findsOneWidget);
    await tester.tap(toolRow);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final modal = find.byType(ToolModalBottomSheet);
    expect(modal, findsOneWidget);

    final toolId = resolveToolIdFromModal(tester, modal);
    final fromUnit = readFromUnitLabel(tester, modal, toolId).toLowerCase();

    // Liquids tool uses the travel preset: oz <-> ml (1 oz = 29.5735 ml).
    final fromIsOz = fromUnit.contains('oz');
    final inputValue = fromIsOz ? '12' : '355';
    final expectedUnit = fromIsOz ? 'ml' : 'oz';
    final expectedOut = fromIsOz ? 12.0 * 29.5735 : 355.0 / 29.5735;

    final inputKey = ValueKey('tool_input_$toolId');
    await tester.enterText(find.byKey(inputKey), inputValue);
    await tester.tap(find.byKey(ValueKey('tool_run_$toolId')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final resultLine = readResultLine(tester, toolId);
    expect(resultLine, contains(arrow));
    final outputPart = resultLine.split(arrow).last.trim();

    expect(outputPart.toLowerCase(), contains(expectedUnit));

    final outputNumber = parseFirstNumber(outputPart);
    expect(outputNumber, isNotNull);
    expect(outputNumber!, closeTo(expectedOut, 0.2));

    // First history line appears.
    final history0 = find.byKey(ValueKey('tool_history_${toolId}_0'));
    expect(history0, findsOneWidget);

    // Tap history item to copy output.
    await tester.tap(history0);
    await tester.pumpAndSettle(const Duration(milliseconds: 220));

    final copied = parseFirstNumber(lastClipboardText);
    expect(copied, isNotNull);
    expect(copied!, closeTo(expectedOut, 0.2));

    // Long-press to edit should restore the original numeric input.
    await tester.longPress(history0);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final field = tester.widget<TextField>(find.byKey(inputKey));
    expect(field.controller?.text, inputValue);
  });
}
