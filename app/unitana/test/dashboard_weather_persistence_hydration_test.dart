import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loadDevSettings restores persisted weather backend preference',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'dev_weather_backend_v1': 'openmeteo',
      });

      final live = DashboardLiveDataController();
      addTearDown(live.dispose);

      await live.loadDevSettings();

      expect(live.weatherBackend, WeatherBackend.openMeteo);
    },
  );
}
