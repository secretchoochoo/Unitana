import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Allow runtime font fetching in widget/golden tests so GoogleFonts can resolve
  // required font files during tests (avoids bundling font assets in-repo).
  GoogleFonts.config.allowRuntimeFetching = true;

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
        darkTheme: UnitanaTheme.dark(),
        themeMode: ThemeMode.dark,
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

  String readTerminalLineText(WidgetTester tester, Finder root) {
    // Tool history uses a RichText “terminal line”; fall back to any Text/RichText.
    final rich = find.descendant(of: root, matching: find.byType(RichText));
    if (tester.any(rich)) {
      final w = tester.widget<RichText>(rich.first);
      return (w.text as TextSpan).toPlainText();
    }
    final text = find.descendant(of: root, matching: find.byType(Text));
    if (tester.any(text)) {
      return tester.widget<Text>(text.first).data ?? '';
    }
    return '';
  }

  testWidgets('Length/Height modal: convert, history copy, and long-press edit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    String lastClipboardText = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args =
                (methodCall.arguments as Map?) ?? const <String, dynamic>{};
            lastClipboardText = (args['text']?.toString() ?? '').trim();
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': lastClipboardText};
          }
          return null;
        });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Open ToolPickerSheet via the dedicated Tools button.
    await tester.tap(find.byKey(const Key('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    Future<void> openHeightToolFromPicker() async {
      final searchField = find.byKey(const ValueKey('toolpicker_search'));
      if (tester.any(searchField)) {
        await tester.enterText(searchField, 'height');
        await tester.pumpAndSettle(const Duration(milliseconds: 250));

        final searchRow = find.byKey(
          const ValueKey('toolpicker_search_tool_height'),
        );
        if (tester.any(searchRow)) {
          await tester.tap(searchRow);
          await tester.pumpAndSettle(const Duration(milliseconds: 300));
          return;
        }
      }

      final heightRow = find.byKey(const Key('toolpicker_tool_height'));
      if (tester.any(heightRow)) {
        await tester.tap(heightRow);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
        return;
      }

      fail(
        'Could not locate Height tool in ToolPicker. Expected either '
        'ValueKey("toolpicker_search") + ValueKey("toolpicker_search_tool_height") '
        'or Key("toolpicker_tool_height").',
      );
    }

    await openHeightToolFromPicker();

    // Modal should now be open.
    final modalRoot = find.byType(BottomSheet);
    expect(modalRoot, findsOneWidget);

    final toolId = resolveToolIdFromModal(tester, modalRoot);
    expect(toolId, anyOf(equals('height'), equals('length')));

    final unitsLabel = readUnitArrowLabel(tester, modalRoot, toolId);
    final isMetricForward = unitsLabel.trimLeft().startsWith('cm');

    final inputField = find.byKey(ValueKey('tool_input_$toolId'));
    expect(inputField, findsOneWidget);

    final input = isMetricForward ? '178' : "5' 10\"";
    await tester.enterText(inputField, input);
    await tester.pump(const Duration(milliseconds: 80));

    await tester.tap(find.byKey(ValueKey('tool_run_$toolId')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final historyItem = find.byKey(ValueKey('tool_history_${toolId}_0'));
    expect(historyItem, findsOneWidget);

    final historyText = readTerminalLineText(tester, historyItem);
    // Display may include unit suffixes, or may omit them for compactness.
    // Guard the semantics instead of a single exact string.
    if (isMetricForward) {
      expect(historyText, contains('178'));
      expect(historyText, contains('→'));
      expect(historyText, anyOf(contains("5'"), contains('ft')));
    } else {
      expect(historyText, contains("5'"));
      expect(historyText, contains('→'));
      expect(historyText, contains('cm'));
    }

    // Tap to copy output.
    await tester.tap(historyItem);
    await tester.pumpAndSettle(const Duration(milliseconds: 120));
    expect(lastClipboardText, isNotEmpty);

    // Long-press to load input back into the field for editing.
    await tester.longPress(historyItem, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    final textField = tester.widget<TextField>(inputField);
    expect(textField.controller?.text, isNotEmpty);
  });
}
