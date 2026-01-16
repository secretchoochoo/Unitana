import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/models/place.dart';
import 'package:unitana/theme/app_theme.dart';

/// Shared helpers for dashboard widget tests.
///
/// Keep these helpers minimal and deterministic. Tests should not depend on
/// ToolPicker ordering or locale-sensitive labels.
UnitanaAppState buildSeededDashboardState() {
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
      cityName: 'Porto',
      countryCode: 'PT',
      timeZoneId: 'Europe/Lisbon',
      unitSystem: 'metric',
      use24h: true,
    ),
  ];
  state.defaultPlaceId = 'home';

  return state;
}

Future<void> pumpDashboardForTest(
  WidgetTester tester, {
  UnitanaAppState? state,
  Size surfaceSize = const Size(390, 844),
}) async {
  // Ensure deterministic storage.
  SharedPreferences.setMockInitialValues({});

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() async => tester.binding.setSurfaceSize(null));

  final seeded = state ?? buildSeededDashboardState();

  await tester.pumpWidget(
    MaterialApp(
      theme: UnitanaTheme.dark(),
      home: DashboardScreen(state: seeded),
    ),
  );

  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}
