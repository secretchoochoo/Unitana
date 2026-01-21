import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  testWidgets('Weather Summary sheet can be closed via top-right X', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'dashboard_layout_v1': jsonEncode([
        {
          'id': 'weather_summary_test',
          'kind': 'tool',
          'toolId': 'weather_summary',
          'colSpan': 1,
          'rowSpan': 1,
          'anchorIndex': null,
          'userAdded': true,
        },
      ]),
    });

    final storage = UnitanaStorage();
    final seededPlaces = <Place>[
      const Place(
        id: 'home',
        type: PlaceType.living,
        name: 'Home',
        cityName: 'Denver',
        countryCode: 'US',
        timeZoneId: 'America/Denver',
        unitSystem: 'imperial',
        use24h: false,
      ),
      const Place(
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

    await storage.savePlaces(seededPlaces);
    await storage.saveDefaultPlaceId('home');
    await storage.saveProfileName('Cody');

    final state = UnitanaAppState(storage);
    await state.load();

    await tester.binding.setSurfaceSize(const Size(390, 844));

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: UnitanaTheme.dark(),
          darkTheme: UnitanaTheme.dark(),
          themeMode: ThemeMode.dark,
          home: DashboardScreen(state: state),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final tileKey = const ValueKey('dashboard_item_weather_summary_test');
      expect(find.byKey(tileKey), findsOneWidget);

      await tester.tap(find.byKey(tileKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      final sheetKey = const ValueKey('weather_summary_sheet');
      final sheetFinder = find.byKey(sheetKey);
      expect(sheetFinder, findsOneWidget);

      final closeKey = const ValueKey('weather_summary_close');
      expect(find.byKey(closeKey), findsOneWidget);

      await tester.tap(find.byKey(closeKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(sheetFinder, findsNothing);

      // Drain any exceptions thrown during close.
      final thrown = <Object>[];
      Object? exception;
      while ((exception = tester.takeException()) != null) {
        thrown.add(exception!);
      }
      expect(
        thrown,
        isEmpty,
        reason: thrown.map((e) => e.toString()).join('\n\n'),
      );
    } finally {
      await tester.binding.setSurfaceSize(null);
    }
  });
}
