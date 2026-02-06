import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app.dart';
import 'package:unitana/models/place.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UnitanaProfile completeProfile() {
    return const UnitanaProfile(
      id: 'profile_complete',
      name: 'Complete',
      defaultPlaceId: 'visit-1',
      places: <Place>[
        Place(
          id: 'living-1',
          type: PlaceType.living,
          name: 'Home',
          cityName: 'Denver',
          countryCode: 'US',
          timeZoneId: 'America/Denver',
          unitSystem: 'imperial',
          use24h: false,
        ),
        Place(
          id: 'visit-1',
          type: PlaceType.visiting,
          name: 'Destination',
          cityName: 'Porto',
          countryCode: 'PT',
          timeZoneId: 'Europe/Lisbon',
          unitSystem: 'metric',
          use24h: true,
        ),
      ],
    );
  }

  UnitanaProfile incompleteProfile() {
    return const UnitanaProfile(
      id: 'profile_incomplete',
      name: 'Incomplete',
      defaultPlaceId: null,
      places: <Place>[],
    );
  }

  testWidgets(
    'startup recovers from incomplete active profile when a complete profile exists',
    (tester) async {
      final profiles = <UnitanaProfile>[incompleteProfile(), completeProfile()];
      SharedPreferences.setMockInitialValues({
        'profiles_v1': jsonEncode(profiles.map((p) => p.toJson()).toList()),
        'active_profile_id_v1': 'profile_incomplete',
      });

      await tester.pumpWidget(const UnitanaApp());
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboard_menu_button')), findsOneWidget);
      expect(find.byKey(const Key('first_run_step_welcome')), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('active_profile_id_v1'), 'profile_complete');
    },
  );

  testWidgets('startup still shows first-run when no complete profile exists', (
    tester,
  ) async {
    final profiles = <UnitanaProfile>[incompleteProfile()];
    SharedPreferences.setMockInitialValues({
      'profiles_v1': jsonEncode(profiles.map((p) => p.toJson()).toList()),
      'active_profile_id_v1': 'profile_incomplete',
    });

    await tester.pumpWidget(const UnitanaApp());
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first_run_step_welcome')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_menu_button')), findsNothing);
  });
}
