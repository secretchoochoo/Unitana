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

Future<void> _openProfilesBoard(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('dashboard_menu_button')));
  final profilesTile = find.widgetWithText(ListTile, 'Profiles');
  await pumpUntilFound(tester, profilesTile);
  await ensureVisibleAligned(tester, profilesTile);
  await tester.tap(profilesTile);
  await pumpUntilFound(tester, find.byKey(const Key('profiles_board_screen')));
}

void main() {
  testWidgets('Profile tile long-press opens quick actions outside edit mode', (
    tester,
  ) async {
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
    await _openProfilesBoard(tester);

    final profileTile = find.byKey(
      const ValueKey('profiles_board_tile_profile_2'),
    );
    await ensureVisibleAligned(tester, profileTile);
    await tester.longPress(profileTile, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('profiles_board_action_delete_profile_2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profiles_board_edit_done')),
      findsNothing,
    );
  });

  testWidgets('Deleting a profile preserves the vacated visible slot', (
    tester,
  ) async {
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
    await _openProfilesBoard(tester);

    final profileTile = find.byKey(
      const ValueKey('profiles_board_tile_profile_2'),
    );
    final firstAddTile = find.byKey(const Key('profiles_board_add_profile'));

    await ensureVisibleAligned(tester, profileTile);
    final deletedTileRect = tester.getRect(profileTile);
    final initialAddTileRect = tester.getRect(firstAddTile);
    expect(initialAddTileRect.topLeft == deletedTileRect.topLeft, isFalse);

    await tester.longPress(profileTile, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.byKey(const ValueKey('profiles_board_action_delete_profile_2')),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    final deleteButton = find.widgetWithText(FilledButton, 'Delete');
    expect(deleteButton, findsOneWidget);
    final deleteWidget = tester.widget<FilledButton>(deleteButton);
    deleteWidget.onPressed?.call();
    await tester.pump(const Duration(milliseconds: 400));

    expect(state.profiles.any((profile) => profile.id == 'profile_2'), isFalse);
    expect(
      find.byKey(const ValueKey('profiles_board_tile_profile_2')),
      findsNothing,
    );

    final restoredAddTile = find.byKey(const Key('profiles_board_add_profile'));
    expect(restoredAddTile, findsOneWidget);
    final restoredAddTileRect = tester.getRect(restoredAddTile);
    expect(restoredAddTileRect.top, equals(deletedTileRect.top));
    expect(restoredAddTileRect.left, closeTo(deletedTileRect.left, 16));
  });
}
