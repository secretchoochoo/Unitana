import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app.dart';
import 'package:unitana/features/dashboard/dashboard_screen.dart';
import 'package:unitana/features/first_run/first_run_screen.dart';

void main() {
  testWidgets('App routes to FirstRun when setup incomplete', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const UnitanaApp());

    // Allow async bootstrap to complete.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.byType(FirstRunScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });

  testWidgets('App routes to Dashboard when setup complete', (
    WidgetTester tester,
  ) async {
    final places = [
      {
        'id': 'living-1',
        'type': 'living',
        'name': 'Home',
        'cityName': 'Denver',
        'countryCode': 'US',
        'timeZoneId': 'America/Denver',
        'unitSystem': 'imperial',
        'use24h': false,
      },
      {
        'id': 'visit-1',
        'type': 'visiting',
        'name': 'Destination',
        'cityName': 'Lisbon',
        'countryCode': 'PT',
        'timeZoneId': 'Europe/Lisbon',
        'unitSystem': 'metric',
        'use24h': true,
      },
    ];

    SharedPreferences.setMockInitialValues({
      'places_v1': jsonEncode(places),
      'default_place_id_v1': 'visit-1',
      'profile_name_v1': 'Lisbon',
    });

    await tester.pumpWidget(const UnitanaApp());

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(FirstRunScreen), findsNothing);
  });
}
