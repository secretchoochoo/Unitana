import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/features/dashboard/models/profile_auto_selector.dart';
import 'package:unitana/models/place.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UnitanaProfile profile({
    required String id,
    required String name,
    required String homeCity,
    required String homeCountry,
    required String destCity,
    required String destCountry,
  }) {
    return UnitanaProfile(
      id: id,
      name: name,
      defaultPlaceId: 'home',
      places: <Place>[
        Place(
          id: 'home',
          type: PlaceType.living,
          name: 'Home',
          cityName: homeCity,
          countryCode: homeCountry,
          timeZoneId: 'UTC',
          unitSystem: 'metric',
          use24h: true,
        ),
        Place(
          id: 'dest',
          type: PlaceType.visiting,
          name: 'Destination',
          cityName: destCity,
          countryCode: destCountry,
          timeZoneId: 'UTC',
          unitSystem: 'metric',
          use24h: true,
        ),
      ],
    );
  }

  test('returns no suggestion when signal is unavailable', () async {
    final result = await ProfileAutoSelector.evaluate(
      profiles: <UnitanaProfile>[
        profile(
          id: 'a',
          name: 'A',
          homeCity: 'Denver',
          homeCountry: 'US',
          destCity: 'Lisbon',
          destCountry: 'PT',
        ),
      ],
      activeProfileId: 'a',
      lastActivatedEpochByProfileId: const <String, int>{},
      signal: null,
    );

    expect(result.hasSuggestion, isFalse);
    expect(result.profileId, isNull);
  });

  test('suggests nearest profile city deterministically', () async {
    final now = DateTime.utc(2026, 2, 8, 12, 0);
    final result = await ProfileAutoSelector.evaluate(
      profiles: <UnitanaProfile>[
        profile(
          id: 'denver_profile',
          name: 'US Home',
          homeCity: 'Denver',
          homeCountry: 'US',
          destCity: 'Chicago',
          destCountry: 'US',
        ),
        profile(
          id: 'lisbon_profile',
          name: 'PT Home',
          homeCity: 'Lisbon',
          homeCountry: 'PT',
          destCity: 'Porto',
          destCountry: 'PT',
        ),
      ],
      activeProfileId: 'denver_profile',
      lastActivatedEpochByProfileId: <String, int>{
        'denver_profile': now
            .subtract(const Duration(days: 20))
            .millisecondsSinceEpoch,
        'lisbon_profile': now
            .subtract(const Duration(hours: 8))
            .millisecondsSinceEpoch,
      },
      signal: ProfileLocationSignal(
        latitude: 38.7223,
        longitude: -9.1393,
        sampledAt: now,
      ),
    );

    expect(result.hasSuggestion, isTrue);
    expect(result.profileId, 'lisbon_profile');
    expect(result.reason.toLowerCase(), contains('lisbon'));
  });

  test('returns no suggestion when confidence is too low', () async {
    final now = DateTime.utc(2026, 2, 8, 12, 0);
    final result = await ProfileAutoSelector.evaluate(
      profiles: <UnitanaProfile>[
        profile(
          id: 'denver_profile',
          name: 'US Home',
          homeCity: 'Denver',
          homeCountry: 'US',
          destCity: 'Chicago',
          destCountry: 'US',
        ),
      ],
      activeProfileId: 'denver_profile',
      lastActivatedEpochByProfileId: const <String, int>{},
      signal: ProfileLocationSignal(
        latitude: 0.0,
        longitude: -140.0,
        sampledAt: now,
      ),
    );

    expect(result.hasSuggestion, isFalse);
    expect(result.profileId, isNull);
    expect(result.reason, contains('too far'));
  });

  test(
    'breaks fully tied candidates deterministically by profile id',
    () async {
      final now = DateTime.utc(2026, 2, 8, 12, 0);
      final result = await ProfileAutoSelector.evaluate(
        profiles: <UnitanaProfile>[
          profile(
            id: 'z_profile',
            name: 'Z',
            homeCity: 'Denver',
            homeCountry: 'US',
            destCity: 'Chicago',
            destCountry: 'US',
          ),
          profile(
            id: 'a_profile',
            name: 'A',
            homeCity: 'Denver',
            homeCountry: 'US',
            destCity: 'Chicago',
            destCountry: 'US',
          ),
        ],
        activeProfileId: 'z_profile',
        lastActivatedEpochByProfileId: const <String, int>{},
        signal: ProfileLocationSignal(
          latitude: 39.7392,
          longitude: -104.9903,
          sampledAt: now,
        ),
      );

      expect(result.hasSuggestion, isTrue);
      expect(result.profileId, 'a_profile');
    },
  );
}
