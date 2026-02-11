import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unitana/app/app_state.dart';
import 'package:unitana/app/storage.dart';
import 'package:unitana/features/dashboard/models/dashboard_layout_controller.dart';
import 'package:unitana/features/dashboard/models/tool_definitions.dart';
import 'package:unitana/models/place.dart';

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
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('switchToProfile persists active profile and can be restored', () async {
    final storage = UnitanaStorage();
    final state = UnitanaAppState(storage);
    await state.load();

    // Seed profile_1 as a complete profile so round-trip persistence can
    // assert the selected active profile survives restart.
    await state.overwritePlaces(
      newPlaces: <Place>[
        _place(
          id: 'home_1',
          type: PlaceType.living,
          city: 'Porto',
          country: 'PT',
        ),
        _place(
          id: 'visit_1',
          type: PlaceType.visiting,
          city: 'Chicago',
          country: 'US',
        ),
      ],
      defaultId: 'visit_1',
    );

    const p2 = UnitanaProfile(
      id: 'profile_2',
      name: 'Trip',
      places: <Place>[],
      defaultPlaceId: null,
    );

    await state.createProfile(
      p2.copyWith(
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
            city: 'Denver',
            country: 'US',
          ),
        ],
        defaultPlaceId: 'visit_2',
      ),
    );
    expect(state.activeProfileId, 'profile_2');

    await state.switchToProfile('profile_1');
    expect(state.activeProfileId, 'profile_1');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('active_profile_id_v1'), 'profile_1');
    expect(prefs.getString('profiles_v1'), isNotNull);

    final restored = UnitanaAppState(storage);
    await restored.load();
    expect(restored.activeProfileId, 'profile_1');
    expect(restored.profiles.length, 2);
  });

  test('dashboard layout persistence is namespaced by profile id', () async {
    final tool = ToolDefinitions.registry.first;

    final homeLayout = DashboardLayoutController(prefsNamespace: 'profile_1');
    await homeLayout.load();
    await homeLayout.addTool(tool);
    expect(homeLayout.items, isNotEmpty);

    final tripLayout = DashboardLayoutController(prefsNamespace: 'profile_2');
    await tripLayout.load();
    expect(tripLayout.items, isEmpty);
  });

  test('createProfile supports insertIndex ordering', () async {
    final storage = UnitanaStorage();
    final state = UnitanaAppState(storage);
    await state.load();

    await state.createProfile(
      const UnitanaProfile(
        id: 'profile_2',
        name: 'Profile #2',
        places: <Place>[],
        defaultPlaceId: null,
      ),
    );
    await state.createProfile(
      const UnitanaProfile(
        id: 'profile_3',
        name: 'Profile #3',
        places: <Place>[],
        defaultPlaceId: null,
      ),
    );
    await state.createProfile(
      const UnitanaProfile(
        id: 'profile_inserted',
        name: 'Profile #X',
        places: <Place>[],
        defaultPlaceId: null,
      ),
      insertIndex: 1,
    );

    final ids = state.profiles.map((p) => p.id).toList(growable: false);
    expect(
      ids,
      equals(<String>[
        'profile_1',
        'profile_inserted',
        'profile_2',
        'profile_3',
      ]),
    );
  });
}
