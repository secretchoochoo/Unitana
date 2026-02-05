import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/features/dashboard/models/dashboard_session_controller.dart';
import 'package:unitana/features/dashboard/widgets/places_hero_v2.dart';
import 'package:unitana/models/place.dart';

import '../dashboard_test_helpers.dart';

void main() {
  // Goldens are opt-in by default. When running `--update-goldens`, Flutter sets
  // `autoUpdateGoldenFiles=true`, and we should allow the suite to execute even
  // if UNITANA_GOLDENS is not set.
  final shouldRunGoldens =
      Platform.environment['UNITANA_GOLDENS'] == '1' || autoUpdateGoldenFiles;

  setUpAll(() {
    if (!shouldRunGoldens) {
      // ignore: avoid_print
      print(
        'Goldens disabled. To generate/update baselines, run: '
        'flutter test --update-goldens test/goldens/places_hero_v2_goldens_test.dart',
      );
    }
  });

  Future<void> pumpHero(
    WidgetTester tester, {
    required DashboardSessionController session,
    required DashboardLiveDataController liveData,
    required Place home,
    required Place dest,
  }) async {
    tester.view.physicalSize = const Size(390, 320);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTestTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              height: 282,
              child: PlacesHeroV2(
                session: session,
                liveData: liveData,
                home: home,
                destination: dest,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

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

  testWidgets(
    'Golden: PlacesHeroV2 populated (destination selected)',
    (tester) async {
      final session = DashboardSessionController();
      final liveData = DashboardLiveDataController();
      liveData.ensureSeeded(const [home, dest]);

      await pumpHero(
        tester,
        session: session,
        liveData: liveData,
        home: home,
        dest: dest,
      );

      await expectLater(
        find.byType(PlacesHeroV2),
        matchesGoldenFile('goldens/places_hero_v2_populated_dest.png'),
      );
    },
    skip: !shouldRunGoldens,
  );

  testWidgets('Golden: PlacesHeroV2 populated (home selected)', (tester) async {
    final session = DashboardSessionController();
    final liveData = DashboardLiveDataController();
    liveData.ensureSeeded(const [home, dest]);

    await pumpHero(
      tester,
      session: session,
      liveData: liveData,
      home: home,
      dest: dest,
    );

    await tester.tap(find.byKey(const ValueKey('places_hero_segment_home')));
    await tester.pump(const Duration(milliseconds: 200));

    await expectLater(
      find.byType(PlacesHeroV2),
      matchesGoldenFile('goldens/places_hero_v2_populated_home.png'),
    );
  }, skip: !shouldRunGoldens);

  testWidgets(
    'Golden: PlacesHeroV2 missing live data (placeholders)',
    (tester) async {
      final session = DashboardSessionController();
      final liveData = DashboardLiveDataController();
      // Intentionally do NOT call ensureSeeded().

      await pumpHero(
        tester,
        session: session,
        liveData: liveData,
        home: home,
        dest: dest,
      );

      await expectLater(
        find.byType(PlacesHeroV2),
        matchesGoldenFile('goldens/places_hero_v2_missing_data.png'),
      );
    },
    skip: !shouldRunGoldens,
  );
}
