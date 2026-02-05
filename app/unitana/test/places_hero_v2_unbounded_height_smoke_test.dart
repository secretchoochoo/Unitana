import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/features/dashboard/models/dashboard_session_controller.dart';
import 'package:unitana/features/dashboard/widgets/places_hero_v2.dart';
import 'package:unitana/models/place.dart';

import 'dashboard_test_helpers.dart';

void main() {
  testWidgets(
    'PlacesHeroV2 does not throw under unbounded height constraints',
    (tester) async {
      final session = DashboardSessionController();
      final liveData = DashboardLiveDataController();

      const home = Place(
        id: 'home',
        type: PlaceType.living,
        name: 'Home Base',
        cityName: 'Denver',
        countryCode: 'US',
        timeZoneId: 'America/Denver',
        unitSystem: 'imperial',
        use24h: false,
      );

      const dest = Place(
        id: 'dest',
        type: PlaceType.visiting,
        name: 'Destination',
        cityName: 'Lisbon',
        countryCode: 'PT',
        timeZoneId: 'Europe/Lisbon',
        unitSystem: 'metric',
        use24h: true,
      );

      // Seed demo values so the widget exercises its populated path.
      liveData.ensureSeeded(const [home, dest]);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTestTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  PlacesHeroV2(
                    session: session,
                    liveData: liveData,
                    home: home,
                    destination: dest,
                  ),
                  const SizedBox(height: 800),
                ],
              ),
            ),
          ),
        ),
      );

      // The failure we hit was a build-time layout exception.
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
