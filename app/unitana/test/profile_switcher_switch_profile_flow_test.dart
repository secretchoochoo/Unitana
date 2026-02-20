import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
    'Profiles board keeps 10 total cells and balanced add-slot count',
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

      final grid = tester.widget<GridView>(
        find.byKey(const Key('profiles_board_grid')),
      );
      final delegate = grid.childrenDelegate as SliverChildBuilderDelegate;
      expect(delegate.childCount, 10);
    },
  );

  testWidgets('Profiles board reorder works via long-press drag interaction', (
    tester,
  ) async {
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

    await tester.tap(find.byKey(const ValueKey('profiles_board_edit_mode')));
    await tester.pump(const Duration(milliseconds: 300));

    final tile1 = find.byKey(const ValueKey('profiles_board_tile_profile_1'));
    final tile2 = find.byKey(const ValueKey('profiles_board_tile_profile_2'));
    final pre1 = tester.getTopLeft(tile1);
    final pre2 = tester.getTopLeft(tile2);
    expect(pre2.dx > pre1.dx, isTrue);

    final target1 = tester.getCenter(
      find.byKey(const ValueKey('profiles_board_target_profile_1')),
    );
    final gesture = await tester.startGesture(tester.getCenter(tile2));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 120));
    await gesture.moveTo(target1);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 450));

    final post1 = tester.getTopLeft(tile1);
    final post2 = tester.getTopLeft(tile2);
    expect(post2.dx < post1.dx, isTrue);
  });

  testWidgets('Profiles board Done shows update toast for save feedback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = UnitanaAppState(UnitanaStorage());
    await state.load();

    await pumpDashboardForTest(tester, state: state);

    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    await tester.pumpAndSettle();
    final profilesTile = find.widgetWithText(ListTile, 'Profiles');
    await ensureVisibleAligned(tester, profilesTile);
    await tester.tap(profilesTile);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profiles_board_edit_mode')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('profiles_board_edit_done')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Profiles updated'), findsOneWidget);
  });
}
