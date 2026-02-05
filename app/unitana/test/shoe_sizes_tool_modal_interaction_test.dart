import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

import 'dashboard_test_helpers.dart';

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

  testWidgets('Shoe Sizes modal: convert US M to EU (stable result)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = true;

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Add Shoe Sizes via the + slot.
    final addSlot = firstAddSlotFinder();
    expect(addSlot, findsWidgets);

    await ensureVisibleAligned(tester, addSlot.first);

    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    // Use search to find the tool (lens ordering can vary).
    final searchField = find.byKey(const ValueKey('toolpicker_search'));
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'shoe');
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final shoeTool = find.byKey(
      const ValueKey('toolpicker_search_tool_shoe_sizes'),
    );
    expect(shoeTool, findsOneWidget);

    await tester.tap(shoeTool);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    expect(find.text('Shoe Sizes'), findsOneWidget);

    // Open the Shoe Sizes modal.
    final shoeSizesTile = find.text('Shoe Sizes');
    await ensureVisibleAligned(tester, shoeSizesTile);
    await tester.tap(shoeSizesTile, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final inputField = find.byKey(const ValueKey('tool_input_shoe_sizes'));
    expect(inputField, findsOneWidget);

    await tester.enterText(inputField, '9');
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const ValueKey('tool_run_shoe_sizes')));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final resultRichTextFinder = find
        .descendant(
          of: find.byKey(const ValueKey('tool_result_shoe_sizes')),
          matching: find.byType(RichText),
        )
        .first;

    expect(resultRichTextFinder, findsOneWidget);

    final resultRichText = tester.widget<RichText>(resultRichTextFinder);
    final resultText = resultRichText.text.toPlainText();

    // Value-first output. Unit is carried by the output side, so no redundant labels.
    expect(resultText, contains('9 → 42 EU'));
  });
}
