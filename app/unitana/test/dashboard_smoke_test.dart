import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  testWidgets('Dashboard renders on a small phone without layout exceptions', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

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

    await tester.binding.setSurfaceSize(const Size(320, 568));

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: UnitanaTheme.dark(),
          darkTheme: UnitanaTheme.dark(),
          themeMode: ThemeMode.dark,
          home: DashboardScreen(state: state),
        ),
      );

      // Avoid pumpAndSettle: some widgets may schedule periodic work or
      // animations that would keep the test "unsettled".
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Drain any exceptions (including RenderFlex overflow) thrown during the
      // initial layout / paint.
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
      expect(find.text('Cody'), findsOneWidget);

      // Places Hero V2 should be present.
      expect(find.byKey(const ValueKey('places_hero_v2')), findsOneWidget);

      // Default tool tiles (Top-6 contract).
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Baking'), findsOneWidget);

      // Each tile includes the same helper text.
      expect(find.text('Convert'), findsAtLeastNWidgets(4));
    } finally {
      await tester.binding.setSurfaceSize(null);
    }
  });
}
