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

    // Let the initial async loads settle.
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  Finder firstAddSlotFinder() {
    return find.byWidgetPredicate((w) {
      final key = w.key;
      if (key is! ValueKey) return false;
      final v = key.value.toString();
      return v.startsWith('dashboard_add_slot_');
    });
  }

  testWidgets('Distance modal: convert, history copy, and long-press edit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    GoogleFonts.config.allowRuntimeFetching = false;
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

    // Add Distance via the + slot.
    final addSlot = firstAddSlotFinder();
    expect(addSlot, findsWidgets);

    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final travelLens = find.byKey(
      const ValueKey('toolpicker_lens_travel_essentials'),
    );
    expect(travelLens, findsOneWidget);

    final sheetScrollable = find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.scrollUntilVisible(
      travelLens,
      200,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));

    await tester.tap(travelLens);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final distanceTool = find.byKey(const ValueKey('toolpicker_tool_distance'));
    await tester.scrollUntilVisible(
      distanceTool,
      200,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));
    await tester.tap(distanceTool);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    expect(find.text('Distance'), findsOneWidget);

    // Open the Distance modal.
    await tester.tap(find.text('Distance'));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final inputField = find.byKey(const ValueKey('tool_input_distance'));
    expect(inputField, findsOneWidget);

    await tester.enterText(inputField, '10');
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const ValueKey('tool_run_distance')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Direction can vary based on the active reality (home vs destination).
    // Validate the rendered result line rather than assuming mi→km.
    final resultRichTextFinder = find
        .descendant(
          of: find.byKey(const ValueKey('tool_result_distance')),
          matching: find.byType(RichText),
        )
        .first;

    expect(resultRichTextFinder, findsOneWidget);

    final resultRichText = tester.widget<RichText>(resultRichTextFinder);
    final resultText = resultRichText.text.toPlainText();

    expect(
      resultText,
      anyOf(contains('10 mi → 16.1 km'), contains('10 km → 6.2 mi')),
    );

    final expectedCopiedNumber = resultText.contains('16.1 km')
        ? '16.1'
        : '6.2';

    final historyItem = find.byKey(const ValueKey('tool_history_distance_0'));
    expect(historyItem, findsOneWidget);

    // Tap history item to copy output and show notice.
    await tester.tap(historyItem);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(lastClipboardText, expectedCopiedNumber);

    // Long-press history item to load its input back into the field for editing.
    await tester.longPress(historyItem, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final textField = tester.widget<TextField>(inputField);
    expect(textField.controller?.text, '10');
  });
}
