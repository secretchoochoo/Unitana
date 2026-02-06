import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/data/open_meteo_air_quality_client.dart';
import 'package:unitana/data/open_meteo_client.dart';
import 'package:unitana/data/weather_api_client.dart';
import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/models/place.dart';

class _FailingWeatherApiClient extends WeatherApiClient {
  _FailingWeatherApiClient() : super(apiKey: 'unused', sendApiKey: false);

  @override
  Future<WeatherApiForecast> fetchTodayForecast({required String query}) async {
    throw StateError('weatherapi down');
  }
}

class _FailingOpenMeteoClient extends OpenMeteoClient {
  _FailingOpenMeteoClient() : super(host: 'example.test');

  @override
  Future<OpenMeteoTodayForecast> fetchTodayForecast({
    required double latitude,
    required double longitude,
  }) async {
    throw StateError('open-meteo down');
  }
}

class _FailingAirQualityClient extends OpenMeteoAirQualityClient {
  _FailingAirQualityClient() : super(host: 'example.test');

  @override
  Future<OpenMeteoAirQualityCurrent> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    throw StateError('air-quality down');
  }
}

class _FixedOpenMeteoClient extends OpenMeteoClient {
  _FixedOpenMeteoClient() : super(host: 'example.test');

  @override
  Future<OpenMeteoTodayForecast> fetchTodayForecast({
    required double latitude,
    required double longitude,
  }) async {
    final now = DateTime.utc(2026, 2, 6, 12);
    return OpenMeteoTodayForecast(
      temperatureC: 6,
      windKmh: 8,
      gustKmh: 14,
      weatherCode: 1,
      isDay: true,
      sunriseUtc: now.subtract(const Duration(hours: 4)),
      sunsetUtc: now.add(const Duration(hours: 4)),
    );
  }
}

class _NullPollenAirQualityClient extends OpenMeteoAirQualityClient {
  _NullPollenAirQualityClient() : super(host: 'example.test');

  @override
  Future<OpenMeteoAirQualityCurrent> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    return const OpenMeteoAirQualityCurrent(
      usAqi: 55,
      europeanAqi: 48,
      alder: null,
      birch: null,
      grass: null,
      mugwort: null,
      olive: null,
      ragweed: null,
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

  test('refreshAll seeds fallback snapshots when WeatherAPI fails', () async {
    final live = DashboardLiveDataController(
      weatherApiClient: _FailingWeatherApiClient(),
      openMeteoClient: _FailingOpenMeteoClient(),
      openMeteoAirQualityClient: _FailingAirQualityClient(),
      allowLiveRefreshInTestHarness: true,
      refreshDebounceDuration: Duration.zero,
      simulatedNetworkLatency: Duration.zero,
    );
    addTearDown(live.dispose);

    final p = place(
      id: 'porto',
      city: 'Porto',
      country: 'PT',
      tz: 'Europe/Lisbon',
    );

    await live.setWeatherBackend(WeatherBackend.weatherApi);
    await live.refreshAll(places: [p]);

    expect(live.weatherFor(p), isNotNull);
    expect(live.sunFor(p), isNotNull);
    expect(live.envFor(p), isNotNull);
  });

  test(
    'refreshAll seeds fallback snapshots when Open-Meteo has no coords',
    () async {
      final live = DashboardLiveDataController(
        openMeteoClient: _FailingOpenMeteoClient(),
        openMeteoAirQualityClient: _FailingAirQualityClient(),
        allowLiveRefreshInTestHarness: true,
        refreshDebounceDuration: Duration.zero,
        simulatedNetworkLatency: Duration.zero,
      );
      addTearDown(live.dispose);

      // Intentionally use a place that won't match the city repository so lat/lon
      // are unavailable in live path.
      final p = place(
        id: 'mystery',
        city: 'Mysteryville',
        country: 'US',
        tz: 'UTC',
      );

      await live.setWeatherBackend(WeatherBackend.openMeteo);
      await live.refreshAll(places: [p]);

      expect(live.weatherFor(p), isNotNull);
      expect(live.sunFor(p), isNotNull);
      expect(live.envFor(p), isNotNull);
    },
  );

  test(
    'refreshAll preserves non-null pollen when AQ payload has no pollen',
    () async {
      final live = DashboardLiveDataController(
        openMeteoClient: _FixedOpenMeteoClient(),
        openMeteoAirQualityClient: _NullPollenAirQualityClient(),
        allowLiveRefreshInTestHarness: true,
        refreshDebounceDuration: Duration.zero,
        simulatedNetworkLatency: Duration.zero,
      );
      addTearDown(live.dispose);

      final p = place(
        id: 'denver',
        city: 'Denver',
        country: 'US',
        tz: 'America/Denver',
      );

      await live.setWeatherBackend(WeatherBackend.openMeteo);
      await live.refreshAll(places: [p]);

      final env = live.envFor(p);
      expect(env, isNotNull);
      expect(env!.usAqi, isNotNull);
      expect(env.pollenIndex, isNotNull);
    },
  );
}
