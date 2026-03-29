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
      final profilesTile = find.widgetWithText(ListTile, 'Profiles');
      await pumpUntilFound(tester, profilesTile);
      await ensureVisibleAligned(tester, profilesTile);
      await tester.tap(profilesTile);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('profiles_board_grid')),
      );

      final grid = tester.widget<GridView>(
        find.byKey(const Key('profiles_board_grid')),
      );
      final delegate = grid.childrenDelegate as SliverChildBuilderDelegate;
      expect(delegate.childCount, 10);
    },
  );

  testWidgets('Profiles board reflects persisted profile reorder', (
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
    final profilesTile = find.widgetWithText(ListTile, 'Profiles');
    await pumpUntilFound(tester, profilesTile);
    await ensureVisibleAligned(tester, profilesTile);
    await tester.tap(profilesTile);
    await pumpUntilFound(
      tester,
      find.byKey(const Key('profiles_board_screen')),
    );

    await tester.tap(find.byKey(const ValueKey('profiles_board_edit_mode')));
    await tester.pump(const Duration(milliseconds: 300));

    await state.reorderProfiles(<String>['profile_2', 'profile_1']);
    await tester.pump(const Duration(milliseconds: 300));

    expect(state.profiles.map((profile) => profile.id).toList(), <String>[
      'profile_2',
      'profile_1',
    ]);
  });

  testWidgets('Profiles board Done shows update toast for save feedback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = UnitanaAppState(UnitanaStorage());
    await state.load();

    await pumpDashboardForTest(tester, state: state);

    await tester.tap(find.byKey(const Key('dashboard_menu_button')));
    final profilesTile = find.widgetWithText(ListTile, 'Profiles');
    await pumpUntilFound(tester, profilesTile);
    await ensureVisibleAligned(tester, profilesTile);
    await tester.tap(profilesTile);
    await pumpUntilFound(
      tester,
      find.byKey(const Key('profiles_board_screen')),
    );

    await tester.tap(find.byKey(const ValueKey('profiles_board_edit_mode')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('profiles_board_edit_done')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Profiles updated'), findsOneWidget);
  });
}
