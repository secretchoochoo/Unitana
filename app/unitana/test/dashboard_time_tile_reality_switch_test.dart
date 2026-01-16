import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/features/dashboard/widgets/unitana_tile.dart';
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
        cityName: 'Porto',
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

  Finder timeTileFinder() {
    return find.byWidgetPredicate((w) {
      return w is UnitanaTile && w.title == 'Time';
    });
  }

  Finder timeToolRowFinder() {
    final searchKey = find.byKey(const ValueKey('toolpicker_search_tool_time'));
    if (searchKey.evaluate().isNotEmpty) return searchKey;
    return find.byKey(const ValueKey('toolpicker_tool_time'));
  }

  bool hasAmPm(String v) =>
      RegExp(r'\b(am|pm)\b', caseSensitive: false).hasMatch(v);

  testWidgets('Time tile follows the reality toggle 12h/24h preference', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

    // Add Time via the first available + slot.
    final addSlot = firstAddSlotFinder();
    expect(addSlot, findsWidgets);
    await tester.tap(addSlot.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final searchField = find.byKey(const ValueKey('toolpicker_search'));
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'time');
    await tester.pumpAndSettle(const Duration(milliseconds: 250));

    final timeRow = timeToolRowFinder();
    expect(timeRow, findsOneWidget);

    await tester.tap(timeRow);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // A confirmation toast/snackbar can briefly absorb pointer events near the
    // Places Hero. Wait it out so segment taps are deterministic.
    final addedToast = find.textContaining('Added Time');
    for (var i = 0; i < 15 && addedToast.evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Ensure we're in a known state: Destination reality (use24h: true).
    final destSeg = find.byKey(
      const ValueKey('places_hero_segment_destination'),
    );
    if (destSeg.evaluate().isNotEmpty) {
      await tester.ensureVisible(destSeg);
      await tester.tap(destSeg);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    }

    expect(timeTileFinder(), findsOneWidget);
    var tile = tester.widget<UnitanaTile>(timeTileFinder());

    // Do not overfit to exact time strings; validate format direction only.
    expect(hasAmPm(tile.primary), isFalse);
    expect(hasAmPm(tile.secondary), isTrue);

    // Switch to Home reality (use24h: false) and ensure 12h becomes primary.
    final homeSeg = find.byKey(const ValueKey('places_hero_segment_home'));
    await tester.ensureVisible(homeSeg);
    await tester.tap(homeSeg);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    tile = tester.widget<UnitanaTile>(timeTileFinder());
    expect(hasAmPm(tile.primary), isTrue);
    expect(hasAmPm(tile.secondary), isFalse);
  });
}
