import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/features/dashboard/models/dashboard_session_controller.dart';
import 'package:unitana/features/dashboard/widgets/places_hero_v2.dart';
import 'package:unitana/features/dashboard/widgets/weather_summary_bottom_sheet.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const home = Place(
    id: 'home',
    type: PlaceType.living,
    name: 'Home',
    cityName: 'Denver',
    countryCode: 'US',
    timeZoneId: 'America/Denver',
    unitSystem: 'imperial',
    use24h: false,
  );

  const destination = Place(
    id: 'dest',
    type: PlaceType.visiting,
    name: 'Destination',
    cityName: 'Lisbon',
    countryCode: 'PT',
    timeZoneId: 'Europe/Lisbon',
    unitSystem: 'metric',
    use24h: true,
  );

  Future<void> pumpStable(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets(
    'weather summary alert opens details sheet and shows precip context',
    (tester) async {
      final liveData = DashboardLiveDataController();
      liveData.ensureSeeded(const [destination, home]);
      liveData.setDebugEmergencySeverityOverride(
        WeatherEmergencySeverity.warning,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: UnitanaTheme.dark(),
          darkTheme: UnitanaTheme.dark(),
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: WeatherSummaryBottomSheet(
              liveData: liveData,
              home: home,
              destination: destination,
            ),
          ),
        ),
      );

      await pumpStable(tester);

      expect(
        find.byKey(const ValueKey('weather_summary_precip_dest')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('weather_summary_alert_dest')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('weather_summary_alert_dest')),
      );
      await pumpStable(tester);

      expect(
        find.byKey(const ValueKey('weather_alert_details_sheet_dest')),
        findsOneWidget,
      );
      expect(find.textContaining('Warning'), findsWidgets);
    },
  );

  testWidgets('hero alert opens details sheet for the active place', (
    tester,
  ) async {
    final session = DashboardSessionController();
    final liveData = DashboardLiveDataController();
    liveData.ensureSeeded(const [destination, home]);
    liveData.setDebugEmergencySeverityOverride(WeatherEmergencySeverity.watch);

    await tester.pumpWidget(
      MaterialApp(
        theme: UnitanaTheme.dark(),
        darkTheme: UnitanaTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 280,
            child: PlacesHeroV2(
              home: home,
              destination: destination,
              session: session,
              liveData: liveData,
            ),
          ),
        ),
      ),
    );

    await pumpStable(tester);

    expect(find.textContaining('% precip'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('hero_marquee_slot')));
    await pumpStable(tester);

    expect(
      find.byKey(const ValueKey('weather_alert_details_sheet_dest')),
      findsOneWidget,
    );
    expect(find.textContaining('Watch'), findsWidgets);
  });
}
