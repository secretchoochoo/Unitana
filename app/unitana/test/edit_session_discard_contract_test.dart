import 'package:flutter/gestures.dart';
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

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final deadline = DateTime.now().add(duration);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _enterDashboardEditMode(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('dashboard_menu_button')));
  await _pumpFor(tester, const Duration(milliseconds: 220));
  await tester.tap(find.byKey(const Key('dashboard_edit_mode')));
  await _pumpFor(tester, const Duration(milliseconds: 260));
}

void main() {
  testWidgets('Dashboard cancel prompts only when edit session is dirty', (
    tester,
  ) async {
    await pumpDashboardForTest(tester);

    await _enterDashboardEditMode(tester);

    await tester.tap(find.byKey(const Key('dashboard_edit_cancel')));
    await _pumpFor(tester, const Duration(milliseconds: 250));
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.byKey(const Key('dashboard_menu_button')), findsOneWidget);

    await _enterDashboardEditMode(tester);

    final bakingTile = find.byKey(const ValueKey('dashboard_item_baking'));
    final distanceTile = find.byKey(const ValueKey('dashboard_item_distance'));
    expect(bakingTile, findsOneWidget);
    expect(distanceTile, findsOneWidget);

    await ensureVisibleAligned(tester, bakingTile);
    await ensureVisibleAligned(tester, distanceTile);
    await _pumpFor(tester, const Duration(milliseconds: 60));

    final gesture = await tester.startGesture(tester.getCenter(bakingTile));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 120));
    await gesture.moveTo(tester.getCenter(distanceTile));
    await gesture.up();
    await _pumpFor(tester, const Duration(milliseconds: 360));

    await tester.tap(find.byKey(const Key('dashboard_edit_cancel')));
    await _pumpFor(tester, const Duration(milliseconds: 250));
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('Keep Editing'), findsOneWidget);
    expect(find.text('Discard Changes'), findsOneWidget);

    await tester.tap(find.text('Keep Editing'));
    await _pumpFor(tester, const Duration(milliseconds: 260));
    expect(find.byKey(const Key('dashboard_edit_done')), findsOneWidget);
  });

  testWidgets('Profiles cancel prompts only when edit session is dirty', (
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
    await _openProfilesBoard(tester);

    await tester.tap(find.byKey(const ValueKey('profiles_board_edit_mode')));
    await _pumpFor(tester, const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const ValueKey('profiles_board_edit_cancel')));
    await _pumpFor(tester, const Duration(milliseconds: 260));
    expect(find.text('Discard changes?'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('profiles_board_edit_mode')));
    await _pumpFor(tester, const Duration(milliseconds: 250));

    final source = find.byKey(const ValueKey('profiles_board_tile_profile_1'));
    final target = find.byKey(
      const ValueKey('profiles_board_target_profile_2'),
    );
    expect(source, findsOneWidget);
    expect(target, findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(source));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 120));
    await gesture.moveTo(tester.getCenter(target));
    await gesture.up();
    await _pumpFor(tester, const Duration(milliseconds: 360));

    await tester.tap(find.byKey(const ValueKey('profiles_board_edit_cancel')));
    await _pumpFor(tester, const Duration(milliseconds: 260));
    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.text('Keep Editing'), findsOneWidget);
  });
}
