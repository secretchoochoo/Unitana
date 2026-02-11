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

  Finder currencyTileFinder() {
    return find.byWidgetPredicate((w) {
      return w is UnitanaTile && w.title == 'Currency';
    });
  }

  testWidgets('Currency tile follows the reality toggle', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();
    await pumpDashboard(tester, state);

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
    var tileBefore = tester.widget<UnitanaTile>(currencyTileFinder());

    // Do not overfit to exact rate formatting; only validate directionality.
    expect(tileBefore.primary.trim().startsWith('€'), isTrue);
    expect(tileBefore.secondary.trim().startsWith(r'$'), isTrue);
    // Guard against template/interpolation strings leaking into UI.
    expect(tileBefore.secondary.contains('{'), isFalse);
    expect(tileBefore.secondary.contains('toStringAsFixed'), isFalse);

    // Switch to Home reality and ensure USD becomes primary.
    final homeSeg = find.byKey(const ValueKey('places_hero_segment_home'));
    await ensureVisibleAligned(tester, homeSeg);
    for (var i = 0; i < 3; i++) {
      await tester.tap(homeSeg, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      final next = tester.widget<UnitanaTile>(currencyTileFinder());
      if (next.primary != tileBefore.primary ||
          next.secondary != tileBefore.secondary) {
        tileBefore = next;
        break;
      }
    }

    expect(tileBefore.primary.trim().startsWith(r'$'), isTrue);
    expect(tileBefore.secondary.trim().startsWith('€'), isTrue);
    expect(tileBefore.secondary.contains('{'), isFalse);
    expect(tileBefore.secondary.contains('toStringAsFixed'), isFalse);
  });
}
