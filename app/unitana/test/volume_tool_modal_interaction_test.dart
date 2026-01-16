import 'package:flutter/material.dart';
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

  testWidgets('Volume modal: convert and history entry', (tester) async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Add Volume via the + slot.
    final addSlot = firstAddSlotFinder();
    expect(addSlot, findsWidgets);

    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final homeDiyLens = find.byKey(const ValueKey('toolpicker_lens_home_diy'));
    expect(homeDiyLens, findsOneWidget);

    final sheetScrollable = find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        )
        .first;

    await tester.scrollUntilVisible(
      homeDiyLens,
      200,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));

    await tester.tap(homeDiyLens);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final volumeTool = find.byKey(const ValueKey('toolpicker_tool_volume'));
    await tester.scrollUntilVisible(
      volumeTool,
      200,
      scrollable: sheetScrollable,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 150));

    await tester.tap(volumeTool);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    expect(find.text('Volume'), findsOneWidget);

    // Open the Volume modal.
    await tester.tap(find.text('Volume'));
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final inputField = find.byKey(const ValueKey('tool_input_volume'));
    expect(inputField, findsOneWidget);

    await tester.enterText(inputField, '10');
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const ValueKey('tool_run_volume')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final resultRichTextFinder = find
        .descendant(
          of: find.byKey(const ValueKey('tool_result_volume')),
          matching: find.byType(RichText),
        )
        .first;

    expect(resultRichTextFinder, findsOneWidget);

    final resultRichText = tester.widget<RichText>(resultRichTextFinder);
    // Some tools prefix result/history lines with a lightweight prompt marker
    // (e.g. "> ") to visually separate entries. Tests should not couple to
    // that decoration.
    final resultText = resultRichText.text.toPlainText();
    final normalizedResultText = resultText.replaceFirst(RegExp(r'^>\s*'), '');

    // Depending on the user's default place preferences, Volume may default to
    // either L -> gal or gal -> L. We just assert correctness for either.
    expect(
      normalizedResultText,
      anyOf(
        // Post multi-unit: the input unit is included (e.g. "10 L → 2.6 gal").
        contains('10 L → 2.6 gal'),
        contains('10 gal → 37.9 L'),
        // Backward-compatible acceptors (older builds).
        contains('10 → 2.6 gal'),
        contains('10 → 37.9 L'),
      ),
    );

    final historyItem = find.byKey(const ValueKey('tool_history_volume_0'));
    expect(historyItem, findsOneWidget);
  });
}
