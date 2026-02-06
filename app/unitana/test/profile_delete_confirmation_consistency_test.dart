import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/models/place.dart';

import 'dashboard_test_helpers.dart';

Place _place({
  required String id,
  required PlaceType type,
  required String city,
  required String country,
}) {
  return Place(
    id: id,
    type: type,
    name: city,
    cityName: city,
    countryCode: country,
    timeZoneId: 'UTC',
    unitSystem: 'metric',
    use24h: true,
  );
}

void main() {
  testWidgets(
    'Profile deletion uses bottom sheet confirmation for dashboard consistency',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final state = UnitanaAppState(UnitanaStorage());
      await state.load();

      await state.createProfile(
        const UnitanaProfile(
          id: 'profile_2',
          name: 'Trip Profile',
          places: <Place>[],
          defaultPlaceId: null,
        ).copyWith(
          places: <Place>[
            _place(
              id: 'home_2',
              type: PlaceType.living,
              city: 'Lisbon',
              country: 'PT',
            ),
            _place(
              id: 'visit_2',
              type: PlaceType.visiting,
              city: 'Austin',
              country: 'US',
            ),
          ],
          defaultPlaceId: 'home_2',
        ),
      );

      await pumpDashboardForTest(tester, state: state);

      await tester.tap(find.byKey(const Key('dashboard_menu_button')));
      await tester.pumpAndSettle();
      final profilesTile = find.widgetWithText(ListTile, 'Profiles');
      await ensureVisibleAligned(tester, profilesTile);
      await tester.tap(profilesTile);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('profiles_board_edit_mode')));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(
        find.byKey(const ValueKey('profiles_board_delete_profile_2')),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Delete profile?'), findsOneWidget);

      final deleteButton = find.widgetWithText(FilledButton, 'Delete');
      final deleteWidget = tester.widget<FilledButton>(deleteButton);
      deleteWidget.onPressed?.call();
      await tester.pump(const Duration(milliseconds: 350));

      expect(state.profiles.any((p) => p.id == 'profile_2'), isFalse);
      expect(find.text('Profile deleted'), findsOneWidget);
    },
  );
}
