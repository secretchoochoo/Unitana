import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/models/place.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  const denver = Place(
    id: 'living-1',
    type: PlaceType.living,
    name: 'Home',
    cityName: 'Denver',
    countryCode: 'US',
    timeZoneId: 'America/Denver',
    unitSystem: 'imperial',
    use24h: false,
  );

  const lisbon = Place(
    id: 'living-1',
    type: PlaceType.living,
    name: 'Home',
    cityName: 'Lisbon',
    countryCode: 'PT',
    timeZoneId: 'Europe/Lisbon',
    unitSystem: 'metric',
    use24h: true,
  );

  test(
    'latest place scope wins when overlapping refreshes reuse the same place id',
    () async {
      final live = DashboardLiveDataController(
        allowLiveRefreshInTestHarness: true,
        refreshDebounceDuration: Duration.zero,
        simulatedNetworkLatency: const Duration(milliseconds: 40),
      );
      addTearDown(live.dispose);

      final firstRefresh = live.refreshAll(places: const [denver]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final secondRefresh = live.refreshAll(places: const [lisbon]);

      await Future.wait<void>(<Future<void>>[firstRefresh, secondRefresh]);

      final snapshot = live.weatherFor(lisbon);
      expect(snapshot, isNotNull);
      expect(snapshot!.temperatureC, 20.0);
      expect(snapshot.conditionText, 'Partly cloudy');
    },
  );

  test('invalidating a new place scope clears stale snapshots immediately', () {
    final live = DashboardLiveDataController(
      allowLiveRefreshInTestHarness: true,
      refreshDebounceDuration: Duration.zero,
      simulatedNetworkLatency: Duration.zero,
    );
    addTearDown(live.dispose);

    live.ensureSeeded(const [denver]);
    expect(live.weatherFor(denver), isNotNull);

    live.invalidateForPlaces(places: const [lisbon]);

    expect(live.weatherFor(lisbon), isNull);
    expect(live.lastRefreshedAt, isNull);
  });
}
