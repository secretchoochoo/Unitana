import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/features/dashboard/widgets/unitana_tile.dart';
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

  testWidgets('Currency tile follows the reality toggle', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Add Currency via the first available + slot.
    final addSlot = firstAddSlotFinder();
    expect(addSlot, findsWidgets);
    await ensureVisibleAligned(tester, addSlot.first);

    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // ToolPicker should expose a stable search field.
    final searchField = find.byKey(const ValueKey('toolpicker_search'));
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'currency');
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final currencyRow = currencyToolRowFinder();
    expect(currencyRow, findsOneWidget);

    await tester.tap(currencyRow);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // A confirmation toast/snackbar can briefly absorb pointer events near the
    // Places Hero. Wait it out so segment taps are deterministic.
    final addedToast = find.textContaining('Added Currency');
    for (var i = 0; i < 15 && addedToast.evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Ensure we're in a known state: Destination reality.
    final destSeg = find.byKey(
      const ValueKey('places_hero_segment_destination'),
    );
    if (destSeg.evaluate().isNotEmpty) {
      await ensureVisibleAligned(tester, destSeg);
      await tester.tap(destSeg, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    }

    expect(currencyTileFinder(), findsOneWidget);
    var tile = tester.widget<UnitanaTile>(currencyTileFinder());

    // Do not overfit to exact rate formatting; only validate directionality.
    expect(tile.primary.trim().startsWith('€'), isTrue);
    expect(tile.secondary.trim().startsWith(r'$'), isTrue);
    // Guard against template/interpolation strings leaking into UI.
    expect(tile.secondary.contains('{'), isFalse);
    expect(tile.secondary.contains('toStringAsFixed'), isFalse);

    // Switch to Home reality and ensure USD becomes primary.
    final homeSeg = find.byKey(const ValueKey('places_hero_segment_home'));
    await ensureVisibleAligned(tester, homeSeg);
    await tester.tap(homeSeg, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    tile = tester.widget<UnitanaTile>(currencyTileFinder());
    expect(tile.primary.trim().startsWith(r'$'), isTrue);
    expect(tile.secondary.trim().startsWith('€'), isTrue);
    expect(tile.secondary.contains('{'), isFalse);
    expect(tile.secondary.contains('toStringAsFixed'), isFalse);
  });
}
