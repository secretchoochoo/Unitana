import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/features/dashboard/widgets/unitana_tile.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> dismissToolModal(WidgetTester tester) async {
    // Tool modals are presented via showModalBottomSheet. Tapping the barrier
    // finder directly can land on the sheet (center point) and miss dismissal.
    // Instead, tap a safe coordinate near the top-left which is always outside
    // the bottom sheet and therefore hits the dismissible barrier.
    // Prefer hitting the barrier itself (top-left) when present.
    final barrier = find.byType(ModalBarrier);
    final tapPoint = barrier.evaluate().isNotEmpty
        ? tester.getTopLeft(barrier.first) + const Offset(1, 1)
        : const Offset(10, 10);

    await tester.tapAt(tapPoint);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // If the sheet is still animating/visible, try once more.
    if (find.byType(ModalBarrier).evaluate().isNotEmpty) {
      await tester.tapAt(tapPoint);
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    }
  }

  UnitanaAppState buildSeededState() {
    final storage = UnitanaStorage();
    final state = UnitanaAppState(storage);

    // Invert the usual assumption (US home, EU destination) so this test
    // catches regressions where Currency modal lacks place context.
    state.places = const [
      Place(
        id: 'home',
        type: PlaceType.living,
        name: 'Home',
        cityName: 'Lisbon',
        countryCode: 'PT',
        timeZoneId: 'Europe/Lisbon',
        unitSystem: 'metric',
        use24h: true,
      ),
      Place(
        id: 'dest',
        type: PlaceType.visiting,
        name: 'Destination',
        cityName: 'Denver',
        countryCode: 'US',
        timeZoneId: 'America/Denver',
        unitSystem: 'imperial',
        use24h: false,
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

    // Let initial async loads settle.
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

  Finder currencyTileFinder() {
    return find.byWidgetPredicate((w) {
      return w is UnitanaTile && w.title == 'Currency';
    });
  }

  Finder currencyToolRowFinder() {
    // Prefer search-result key when present.
    final searchKey = find.byKey(
      const ValueKey('toolpicker_search_tool_currency_convert'),
    );
    if (searchKey.evaluate().isNotEmpty) return searchKey;

    // Fallback to non-search tool row key.
    return find.byKey(const ValueKey('toolpicker_tool_currency_convert'));
  }

  String unitsText(WidgetTester tester) {
    final units = find.byKey(const ValueKey('tool_units_currency_convert'));
    expect(units, findsOneWidget);
    final t = tester.widget<Text>(units);
    return (t.data ?? '').trim();
  }

  Future<void> addCurrencyToDashboard(WidgetTester tester) async {
    final addSlot = firstAddSlotFinder();
    expect(addSlot, findsWidgets);
    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final searchField = find.byKey(const ValueKey('toolpicker_search'));
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'currency');
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final currencyRow = currencyToolRowFinder();
    expect(currencyRow, findsOneWidget);
    await tester.tap(currencyRow);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Toast/snackbar can briefly absorb pointer events near the Places Hero.
    // Wait it out so segment taps are deterministic.
    final addedToast = find.textContaining('Added Currency');
    for (var i = 0; i < 15 && addedToast.evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
  }

  testWidgets(
    'Currency modal units reflect actual home/destination currencies (place-aware)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      GoogleFonts.config.allowRuntimeFetching = false;

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async => tester.binding.setSurfaceSize(null));

      final state = buildSeededState();
      await pumpDashboard(tester, state);
      await addCurrencyToDashboard(tester);

      // Ensure we're in Home reality (which is EUR for this seeded state).
      final homeSeg = find.byKey(const ValueKey('places_hero_segment_home'));
      if (homeSeg.evaluate().isNotEmpty) {
        await tester.ensureVisible(homeSeg);
        await tester.tap(homeSeg);
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
      }

      expect(currencyTileFinder(), findsOneWidget);
      await tester.tap(currencyTileFinder());
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      final homeUnits = unitsText(tester);
      // Home (PT) should default EUR -> USD.
      expect(homeUnits.startsWith('EUR'), isTrue);
      expect(homeUnits.contains('→ USD'), isTrue);

      await dismissToolModal(tester);

      // Switch to Destination reality (US) and ensure USD -> EUR.
      final destSeg = find.byKey(
        const ValueKey('places_hero_segment_destination'),
      );
      if (destSeg.evaluate().isNotEmpty) {
        await tester.ensureVisible(destSeg);
        await tester.tap(destSeg);
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
      }

      await tester.tap(currencyTileFinder());
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      final destUnits = unitsText(tester);
      expect(destUnits.startsWith('USD'), isTrue);
      expect(destUnits.contains('→ EUR'), isTrue);
    },
  );
}
