import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    final oldOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = (FlutterErrorDetails details) {
      errors.add(details);
    };

    addTearDown(() {
      FlutterError.onError = oldOnError;
    });

    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        darkTheme: UnitanaTheme.dark(),
        themeMode: ThemeMode.dark,
        home: DashboardScreen(state: state),
      ),
    );

    await tester.pumpAndSettle();

    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
    expect(find.text('Cody'), findsOneWidget);
    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
  });
}
