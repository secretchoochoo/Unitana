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

  String readResultOutput(WidgetTester tester, String toolId) {
    final resultRoot = find.byKey(ValueKey('tool_result_$toolId'));
    expect(resultRoot, findsOneWidget);

    final line = find.descendant(
      of: resultRoot,
      matching: find.byType(RichText),
    );
    expect(line, findsAtLeastNWidgets(1));

    final rich = tester.widget<RichText>(line.first);
    final plain = (rich.text as TextSpan).toPlainText();
    final parts = plain.split('→');
    return parts.length > 1 ? parts.last.trim() : plain.trim();
  }

  testWidgets('Time modal: convert, history copy, and long-press edit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Open ToolPickerSheet via the dedicated Tools button.
    await tester.tap(find.byKey(const Key('dashboard_tools_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    // Open the Time tool using stable keys, without assuming which lens it
    // lives under. (Lenses are presentation-only and can be re-ordered.)

    Future<void> openToolFromPicker() async {
      // Prefer the search path to avoid coupling this test to:
      // - lens ordering,
      // - expanded/collapsed state,
      // - lens header keys.
      //
      // ToolIds are part of our persistence/test contract; labels may vary.
      final searchField = find.byKey(const ValueKey('toolpicker_search'));
      if (tester.any(searchField)) {
        await tester.enterText(searchField, 'time');
        await tester.pumpAndSettle(const Duration(milliseconds: 250));

        final searchRow = find.byKey(const Key('toolpicker_search_tool_time'));
        if (tester.any(searchRow)) {
          await tester.tap(searchRow);
          await tester.pumpAndSettle(const Duration(milliseconds: 300));
          return;
        }
      }

      // Fallback: locate the Time tool row directly (it may already be visible).
      final timeToolRow = find.byKey(const Key('toolpicker_tool_time'));
      if (tester.any(timeToolRow)) {
        await tester.tap(timeToolRow);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
        return;
      }

      // Final fallback: expand lenses and look for the Time tool row.
      final lensHeaders = find.byWidgetPredicate((w) {
        return w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('toolpicker_lens_');
      });

      if (!tester.any(lensHeaders)) {
        fail(
          'ToolPicker did not render lens headers or a searchable Time row. '
          'Expected either ValueKey("toolpicker_search") + Key("toolpicker_search_tool_time") '
          'or lens headers keyed with "toolpicker_lens_*".',
        );
      }

      for (final elem in lensHeaders.evaluate().toList(growable: false)) {
        final header = find.byWidget(elem.widget);
        await tester.tap(header);
        await tester.pumpAndSettle(const Duration(milliseconds: 250));

        if (tester.any(timeToolRow)) {
          await tester.tap(timeToolRow);
          await tester.pumpAndSettle(const Duration(milliseconds: 300));
          return;
        }
      }

      // If the row exists but is off-screen, scroll within the sheet.
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(timeToolRow, 300, scrollable: scrollable);
      await tester.tap(timeToolRow);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    }

    await openToolFromPicker();

    final modal = find.byType(ToolModalBottomSheet);
    expect(modal, findsOneWidget);

    // Derive the toolId from modal keys so this test survives toolId renames.
    final toolId = resolveToolIdFromModal(tester, modal);

    // Decide an input that matches the current direction label.
    final units = readUnitArrowLabel(tester, modal, toolId);
    final fromUnit = units.split('→').first.trim().toLowerCase();
    final inputValue = fromUnit.startsWith('12') ? '6:30 PM' : '18:30';

    // Run a conversion.
    final inputKey = ValueKey('tool_input_$toolId');
    await tester.enterText(find.byKey(inputKey), inputValue);
    await tester.tap(find.byKey(ValueKey('tool_run_$toolId')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final output = readResultOutput(tester, toolId);

    if (fromUnit.startsWith('12')) {
      // 12h -> 24h should yield HH:MM.
      expect(output, matches(RegExp(r'\b\d{2}:\d{2}\b')));
    } else {
      // 24h -> 12h should include AM/PM.
      expect(output.toUpperCase(), contains(RegExp(r'\b(AM|PM)\b')));
    }

    // First history line appears.
    final history0 = find.byKey(ValueKey('tool_history_${toolId}_0'));
    expect(history0, findsOneWidget);

    // Tap to copy output.
    // Avoid brittle assertions on transient notice text visibility. Instead,
    // verify the clipboard is set via the platform channel.
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            final args = call.arguments;
            if (args is Map && args['text'] is String) {
              clipboardText = args['text'] as String;
            }
            return null;
          case 'Clipboard.getData':
            return <String, dynamic>{'text': clipboardText};
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

    await tester.tap(history0);
    await tester.pumpAndSettle(const Duration(milliseconds: 220));

    expect(clipboardText, isNotNull);
    expect(
      clipboardText!.trim().replaceAll(RegExp(r'\s+'), ' '),
      output.trim().replaceAll(RegExp(r'\s+'), ' '),
    );

    // Long-press to edit should restore the original input into the field.
    await tester.longPress(history0);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final field = tester.widget<TextField>(find.byKey(inputKey));
    expect(
      field.controller?.text.replaceAll(' ', '').toUpperCase(),
      inputValue.replaceAll(' ', '').toUpperCase(),
    );
  });
}
