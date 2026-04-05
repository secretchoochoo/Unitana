import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

class _CountingLiveDataController extends DashboardLiveDataController {
  _CountingLiveDataController()
    : super(
        allowLiveRefreshInTestHarness: true,
        refreshDebounceDuration: Duration.zero,
        simulatedNetworkLatency: Duration.zero,
        currencyRetryBackoffDuration: Duration.zero,
      );

  int ensureSeededCalls = 0;
  int refreshAllCalls = 0;

  @override
  Future<void> loadDevSettings() async {}

  @override
  void ensureSeeded(List<Place> places) {
    ensureSeededCalls += 1;
    super.ensureSeeded(places);
  }

  @override
  Future<void> refreshAll({required List<Place> places}) async {
    refreshAllCalls += 1;
    debugSetLastRefreshedAt(DateTime.now());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UnitanaAppState buildState() {
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

  testWidgets(
    'dashboard rebuilds do not retrigger live-data maintenance from build',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final liveData = _CountingLiveDataController();
      addTearDown(liveData.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: UnitanaTheme.dark(),
          home: DashboardScreen(
            state: buildState(),
            liveDataController: liveData,
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      final initialEnsureSeededCalls = liveData.ensureSeededCalls;
      final initialRefreshAllCalls = liveData.refreshAllCalls;
      expect(initialEnsureSeededCalls, greaterThanOrEqualTo(1));
      expect(initialRefreshAllCalls, 1);

      liveData.debugSetLastRefreshedAt(DateTime.now());
      await tester.pump();

      expect(liveData.ensureSeededCalls, initialEnsureSeededCalls);
      expect(liveData.refreshAllCalls, initialRefreshAllCalls);
    },
  );
}
