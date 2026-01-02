import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/features/dashboard/models/activity_lenses.dart';
import 'package:unitana/features/dashboard/models/lens_accents.dart';
import 'package:unitana/features/dashboard/widgets/unitana_tile.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  testWidgets('Dashboard tiles inherit per-tool icon + lens accent', (
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

    await tester.binding.setSurfaceSize(const Size(360, 740));

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

      final heightTile = find.widgetWithText(UnitanaTile, 'Height');
      expect(heightTile, findsOneWidget);

      final expectedAccent = LensAccents.iconTintFor(
        ActivityLensId.healthFitness,
      );

      final leadingIconFinder = find.descendant(
        of: heightTile,
        matching: find.byIcon(Icons.height),
      );
      expect(leadingIconFinder, findsOneWidget);

      final leadingIcon = tester.widget<Icon>(leadingIconFinder);
      expect(leadingIcon.color, expectedAccent);

      final dotFinder = find.descendant(
        of: heightTile,
        matching: find.byIcon(Icons.swap_horiz),
      );
      expect(dotFinder, findsOneWidget);

      final dotIcon = tester.widget<Icon>(dotFinder);
      expect(dotIcon.color, expectedAccent);
    } finally {
      await tester.binding.setSurfaceSize(null);
    }
  });
}
