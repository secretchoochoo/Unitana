import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/data/open_meteo_air_quality_client.dart';
import 'package:unitana/data/open_meteo_client.dart';
import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/models/place.dart';

class _FixedOpenMeteoClient extends OpenMeteoClient {
  _FixedOpenMeteoClient() : super(host: 'example.test');

  @override
  Future<OpenMeteoTodayForecast> fetchTodayForecast({
    required double latitude,
    required double longitude,
  }) async {
    final now = DateTime.utc(2026, 2, 6, 12);
    return OpenMeteoTodayForecast(
      temperatureC: 11,
      windKmh: 12,
      gustKmh: 19,
      weatherCode: 1,
      isDay: true,
      sunriseUtc: now.subtract(const Duration(hours: 4)),
      sunsetUtc: now.add(const Duration(hours: 4)),
    );
  }
}

class _FixedAirQualityClient extends OpenMeteoAirQualityClient {
  _FixedAirQualityClient() : super(host: 'example.test');

  @override
  Future<OpenMeteoAirQualityCurrent> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    return const OpenMeteoAirQualityCurrent(
      usAqi: 72,
      europeanAqi: 66,
      alder: 12,
      grass: 80,
      birch: 20,
      mugwort: 8,
      olive: 5,
      ragweed: 10,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  Place place({
    required String id,
    required String city,
    required String country,
    required String tz,
  }) {
    return Place(
      id: id,
      type: PlaceType.living,
      name: city,
      cityName: city,
      countryCode: country,
      timeZoneId: tz,
      unitSystem: 'metric',
      use24h: true,
    );
  }

  test(
    'open-meteo refresh resolves weather/time/AQI/pollen across representative global cities',
    () async {
      final live = DashboardLiveDataController(
        openMeteoClient: _FixedOpenMeteoClient(),
        openMeteoAirQualityClient: _FixedAirQualityClient(),
        allowLiveRefreshInTestHarness: true,
        refreshDebounceDuration: Duration.zero,
        simulatedNetworkLatency: Duration.zero,
      );
      addTearDown(live.dispose);

      final places = <Place>[
        place(id: 'tokyo', city: 'Tokyo', country: 'JP', tz: 'Asia/Tokyo'),
        place(id: 'cairo', city: 'Cairo', country: 'EG', tz: 'Africa/Cairo'),
        place(
          id: 'saopaulo',
          city: 'Sao Paulo',
          country: 'BR',
          tz: 'America/Sao_Paulo',
        ),
        place(
          id: 'sydney',
          city: 'Sydney',
          country: 'AU',
          tz: 'Australia/Sydney',
        ),
        place(
          id: 'nairobi',
          city: 'Nairobi',
          country: 'KE',
          tz: 'Africa/Nairobi',
        ),
        place(
          id: 'reykjavik',
          city: 'Reykjavik',
          country: 'IS',
          tz: 'Atlantic/Reykjavik',
        ),
      ];

      await live.setWeatherBackend(WeatherBackend.openMeteo);
      await live.refreshAll(places: places);

      for (final p in places) {
        final weather = live.weatherFor(p);
        final sun = live.sunFor(p);
        final env = live.envFor(p);

        expect(weather, isNotNull, reason: '${p.cityName}: weather missing');
        expect(sun, isNotNull, reason: '${p.cityName}: sun missing');
        expect(env, isNotNull, reason: '${p.cityName}: env missing');
        expect(weather!.conditionText.trim(), isNotEmpty);
        expect(weather.conditionCode, equals(1));
        expect(env!.usAqi, equals(72));
        expect(env.pollenIndex, isNotNull);
      }
    },
  );
}
