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

  // Prevent runtime font fetching in widget tests (avoids incidental HttpClient
  // creation and keeps the suite deterministic).
  GoogleFonts.config.allowRuntimeFetching = false;

  // Use a const string literal so the test compiles under const rules.
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

  String fmt(double v) {
    if ((v - v.roundToDouble()).abs() < 0.0001) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  double? parseFirstNumber(String s) {
    final m = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(s);
    return m == null ? null : double.tryParse(m.group(0) ?? '');
  }

  testWidgets('Speed modal: convert, history copy, and long-press edit', (
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

    // Expand the Travel Essentials lens and open Speed via stable keys.
    final travelLens = find.byKey(
      const ValueKey('toolpicker_lens_travel_essentials'),
    );
    expect(travelLens, findsOneWidget);
    await tester.tap(travelLens);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final speedToolRow = find.byKey(const ValueKey('toolpicker_tool_speed'));
    expect(speedToolRow, findsOneWidget);
    await tester.tap(speedToolRow);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final modal = find.byType(ToolModalBottomSheet);
    expect(modal, findsOneWidget);

    final toolId = resolveToolIdFromModal(tester, modal);

    // Choose an input that matches the current direction label.
    final units = readUnitArrowLabel(tester, modal, toolId);
    final fromUnit = units.split(arrow).first.trim().toLowerCase();
    final fromKmh = fromUnit.contains('km/h');

    final inputValue = fromKmh ? '100' : '60';
    final expectedUnit = fromKmh ? 'mph' : 'km/h';

    const mphPerKmh = 0.621371;
    final expectedOut = fromKmh ? 100.0 * mphPerKmh : 60.0 / mphPerKmh;
    final expectedOutLabel = fmt(expectedOut);

    // Run a conversion.
    final inputKey = ValueKey('tool_input_$toolId');
    await tester.enterText(find.byKey(inputKey), inputValue);
    await tester.tap(find.byKey(ValueKey('tool_run_$toolId')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final resultLine = readResultLine(tester, toolId);
    expect(resultLine, contains(arrow));

    final parts = resultLine.split(arrow);
    expect(parts.length, greaterThanOrEqualTo(2));
    final outputPart = parts.last.trim();

    expect(outputPart.toLowerCase(), contains(expectedUnit));

    final outputNumber = parseFirstNumber(outputPart);
    expect(outputNumber, isNotNull);
    expect(outputNumber!, closeTo(expectedOut, 0.06));

    // First history line appears.
    final history0 = find.byKey(ValueKey('tool_history_${toolId}_0'));
    expect(history0, findsOneWidget);

    // Tap history item to copy output. Speed output labels include a unit suffix,
    // but the app copies the numeric portion only.
    await tester.tap(history0);
    await tester.pumpAndSettle(const Duration(milliseconds: 220));

    expect(lastClipboardText, expectedOutLabel);

    // Long-press to edit should restore the original numeric input.
    await tester.longPress(history0);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final field = tester.widget<TextField>(find.byKey(inputKey));
    expect(field.controller?.text, inputValue);
  });
}
