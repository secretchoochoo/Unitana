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
  Finder addProfileTiles() {
    return find.byWidgetPredicate((w) {
      final key = w.key;
      if (key is Key) {
        final raw = key.toString();
        return raw.contains("profiles_board_add_profile");
      }
      return false;
    });
  }

  testWidgets('Profile switcher changes active profile in dashboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = UnitanaAppState(UnitanaStorage());
    await state.load();

    await state.setProfileName('Home Profile');
    await state.overwritePlaces(
      newPlaces: <Place>[
        _place(
          id: 'home_1',
          type: PlaceType.living,
          city: 'Denver',
          country: 'US',
        ),
        _place(
          id: 'visit_1',
          type: PlaceType.visiting,
          city: 'Porto',
          country: 'PT',
        ),
      ],
      defaultId: 'home_1',
    );

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
    await state.switchToProfile('profile_1');

    await pumpDashboardForTest(tester, state: state);
    expect(find.text('Home Profile'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await tester.pumpAndSettle();

    final profilesTile = find.widgetWithText(ListTile, 'Profiles');
    await ensureVisibleAligned(tester, profilesTile);
    await tester.tap(profilesTile);
    await tester.pumpAndSettle();

    final tripProfile = find.byKey(
      const ValueKey('profiles_board_tile_profile_2'),
    );
    await ensureVisibleAligned(tester, tripProfile);
    await tester.tap(tripProfile);
    await tester.pumpAndSettle();

    expect(find.text('Trip Profile'), findsOneWidget);
    expect(state.activeProfileId, 'profile_2');
  });

  testWidgets(
    'Profiles board keeps add-slot tile count balanced for 2-column grid',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final state = UnitanaAppState(UnitanaStorage());
      await state.load();

      await state.createProfile(
        const UnitanaProfile(
          id: 'profile_2',
          name: 'Second',
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

      expect(addProfileTiles(), findsNWidgets(4));
    },
  );
}
