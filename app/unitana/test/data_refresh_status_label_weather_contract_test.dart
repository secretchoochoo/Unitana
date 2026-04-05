import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/features/dashboard/widgets/data_refresh_status_label.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'refresh status label uses weather freshness when a weather backend is selected',
    (tester) async {
      final live = DashboardLiveDataController();
      addTearDown(live.dispose);

      await live.setWeatherBackend(WeatherBackend.openMeteo);
      live.debugSetLastRefreshedAt(DateTime.now());
      live.debugSetLastWeatherRefreshedAt(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DataRefreshStatusLabel(
              liveData: live,
              hideWhenUnavailable: false,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Not updated'), findsOneWidget);
      expect(find.textContaining('Updated'), findsNothing);
    },
  );
}
