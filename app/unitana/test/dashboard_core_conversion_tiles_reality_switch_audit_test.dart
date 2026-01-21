import 'dart:convert';

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

    // Intentionally invert unit systems so toggling reality exercises
    // metric-first vs imperial-first tile ordering.
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

  Finder tileByTitle(String title) {
    return find.byWidgetPredicate((w) => w is UnitanaTile && w.title == title);
  }

  String primaryText(WidgetTester tester, String title) {
    final tile = tester.widget<UnitanaTile>(tileByTitle(title));
    return tile.primary.trim();
  }

  String secondaryText(WidgetTester tester, String title) {
    final tile = tester.widget<UnitanaTile>(tileByTitle(title));
    return tile.secondary.trim();
  }

  bool containsUnit(String text, String unitLower) {
    return text.toLowerCase().contains(unitLower.toLowerCase());
  }

  testWidgets('Core conversion tiles follow the Places Hero reality toggle', (
    tester,
  ) async {
    // Seed a deterministic layout with a handful of core converters.
    final layoutItems = [
      {
        'id': 'audit_length',
        'kind': 'tool',
        'toolId': 'length',
        'colSpan': 1,
        'rowSpan': 1,
        'anchorIndex': 0,
        'userAdded': true,
      },
      {
        'id': 'audit_volume',
        'kind': 'tool',
        'toolId': 'volume',
        'colSpan': 1,
        'rowSpan': 1,
        'anchorIndex': 1,
        'userAdded': true,
      },
      {
        'id': 'audit_pressure',
        'kind': 'tool',
        'toolId': 'pressure',
        'colSpan': 1,
        'rowSpan': 1,
        'anchorIndex': 2,
        'userAdded': true,
      },
      {
        'id': 'audit_weight',
        'kind': 'tool',
        'toolId': 'weight',
        'colSpan': 1,
        'rowSpan': 1,
        'anchorIndex': 3,
        'userAdded': true,
      },
      {
        'id': 'audit_temp',
        'kind': 'tool',
        'toolId': 'temperature',
        'colSpan': 1,
        'rowSpan': 1,
        'anchorIndex': 4,
        'userAdded': true,
      },
    ];

    SharedPreferences.setMockInitialValues({
      'dashboard_layout_v1': jsonEncode(layoutItems),
    });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    final state = buildSeededState();

    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        darkTheme: UnitanaTheme.dark(),
        themeMode: ThemeMode.dark,
        home: DashboardScreen(state: state),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Ensure we start on Destination (metric) so expectations are stable.
    final destSeg = find.byKey(
      const ValueKey('places_hero_segment_destination'),
    );
    if (destSeg.evaluate().isNotEmpty) {
      await tester.ensureVisible(destSeg);
      await tester.tap(destSeg);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    }

    expect(tileByTitle('Length'), findsOneWidget);
    expect(tileByTitle('Volume'), findsOneWidget);
    expect(tileByTitle('Pressure'), findsOneWidget);
    expect(tileByTitle('Weight'), findsOneWidget);
    expect(tileByTitle('Temp'), findsOneWidget);

    // Destination is metric.
    expect(containsUnit(primaryText(tester, 'Length'), 'cm'), isTrue);
    expect(primaryText(tester, 'Length').contains("'"), isFalse);

    expect(containsUnit(primaryText(tester, 'Volume'), 'l'), isTrue);
    expect(containsUnit(secondaryText(tester, 'Volume'), 'gal'), isTrue);

    expect(containsUnit(primaryText(tester, 'Pressure'), 'kpa'), isTrue);
    expect(containsUnit(secondaryText(tester, 'Pressure'), 'psi'), isTrue);

    expect(containsUnit(primaryText(tester, 'Weight'), 'kg'), isTrue);
    expect(containsUnit(secondaryText(tester, 'Weight'), 'lb'), isTrue);

    expect(primaryText(tester, 'Temp').toLowerCase().contains('c'), isTrue);
    expect(secondaryText(tester, 'Temp').toLowerCase().contains('f'), isTrue);

    // Switch to Home (imperial) and ensure tiles swap.
    final homeSeg = find.byKey(const ValueKey('places_hero_segment_home'));
    await tester.ensureVisible(homeSeg);
    // In constrained test surfaces, the segment may be briefly obscured by
    // transient overlays; assertions below still validate the behavioral switch.
    await tester.tap(homeSeg, warnIfMissed: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(primaryText(tester, 'Length').contains("'"), isTrue);
    expect(containsUnit(secondaryText(tester, 'Length'), 'cm'), isTrue);

    expect(containsUnit(primaryText(tester, 'Volume'), 'gal'), isTrue);
    expect(containsUnit(secondaryText(tester, 'Volume'), 'l'), isTrue);

    expect(containsUnit(primaryText(tester, 'Pressure'), 'psi'), isTrue);
    expect(containsUnit(secondaryText(tester, 'Pressure'), 'kpa'), isTrue);

    expect(containsUnit(primaryText(tester, 'Weight'), 'lb'), isTrue);
    expect(containsUnit(secondaryText(tester, 'Weight'), 'kg'), isTrue);

    expect(primaryText(tester, 'Temp').toLowerCase().contains('f'), isTrue);
    expect(secondaryText(tester, 'Temp').toLowerCase().contains('c'), isTrue);
  });
}
