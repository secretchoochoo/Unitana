import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Minimal Open-Meteo forecast payload for Unitana.
///
/// Notes:
/// - Open-Meteo does not require an API key for non-commercial usage.
/// - For commercial usage, Open-Meteo uses a customer-prefixed host and an
///   apikey parameter.
/// - We intentionally keep this client small; mapping into SceneKey and UI
///   concerns stay in the model layer.
@immutable
class OpenMeteoHourlyForecastPoint {
  final DateTime timeUtc;
  final double temperatureC;

  const OpenMeteoHourlyForecastPoint({
    required this.timeUtc,
    required this.temperatureC,
  });
}

@immutable
class OpenMeteoDailyForecastPoint {
  final DateTime dayUtc;
  final double maxTemperatureC;
  final double minTemperatureC;

  const OpenMeteoDailyForecastPoint({
    required this.dayUtc,
    required this.maxTemperatureC,
    required this.minTemperatureC,
  });
}

@immutable
class OpenMeteoTodayForecast {
  final double temperatureC;
  final double windKmh;
  final double gustKmh;
  final int weatherCode;
  final bool isDay;
  final DateTime sunriseUtc;
  final DateTime sunsetUtc;
  final List<OpenMeteoHourlyForecastPoint> hourly;
  final List<OpenMeteoDailyForecastPoint> daily;

  const OpenMeteoTodayForecast({
    required this.temperatureC,
    required this.windKmh,
    required this.gustKmh,
    required this.weatherCode,
    required this.isDay,
    required this.sunriseUtc,
    required this.sunsetUtc,
    required this.hourly,
    required this.daily,
  });
}

class OpenMeteoClient {
  http.Client? _client;

  /// Host should be `api.open-meteo.com` for free/non-commercial.
  /// For commercial customers, Open-Meteo uses a `customer-` prefixed host.
  final String host;

  OpenMeteoClient({http.Client? client, this.host = 'api.open-meteo.com'})
    : _client = client;

  // Keep tests hermetic: only allocate a real HTTP client when a fetch is
  // actually invoked.
  http.Client get _http => _client ??= http.Client();

  Future<OpenMeteoTodayForecast> fetchTodayForecast({
    required double latitude,
    required double longitude,
  }) async {
    // We request:
    // - current: temperature, wind speed/gusts, weather_code, is_day
    // - hourly: time + temperature
    // - daily: sunrise/sunset and temp min/max
    // - timezone=UTC + timeformat=unixtime to avoid ambiguous local parsing
    final uri = Uri.https(host, '/v1/forecast', <String, String>{
      'latitude': latitude.toStringAsFixed(6),
      'longitude': longitude.toStringAsFixed(6),
      'current':
          'temperature_2m,wind_speed_10m,wind_gusts_10m,weather_code,is_day',
      'hourly': 'temperature_2m',
      'daily': 'sunrise,sunset,temperature_2m_max,temperature_2m_min',
      'forecast_days': '7',
      'timezone': 'UTC',
      'timeformat': 'unixtime',
      'wind_speed_unit': 'kmh',
    });

    final resp = await _http.get(
      uri,
      headers: const {
        // Open-Meteo asks clients to include a descriptive UA.
        'User-Agent': 'Unitana/0.x (https://unitana.app)',
      },
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Open-Meteo request failed (${resp.statusCode})');
    }

    final Map<String, dynamic> json =
        jsonDecode(resp.body) as Map<String, dynamic>;

    final current = json['current'] as Map<String, dynamic>?;
    if (current == null) {
      throw Exception('Open-Meteo response missing current');
    }

    final daily = json['daily'] as Map<String, dynamic>?;
    if (daily == null) {
      throw Exception('Open-Meteo response missing daily');
    }
    final hourly = json['hourly'] as Map<String, dynamic>?;
    if (hourly == null) {
      throw Exception('Open-Meteo response missing hourly');
    }

    final sunrise = (daily['sunrise'] as List?)?.cast<num?>().firstOrNull;
    final sunset = (daily['sunset'] as List?)?.cast<num?>().firstOrNull;

    if (sunrise == null || sunset == null) {
      throw Exception('Open-Meteo response missing sunrise/sunset');
    }

    final temperatureC = (current['temperature_2m'] as num?)?.toDouble();
    final windKmh = (current['wind_speed_10m'] as num?)?.toDouble();
    final gustKmh = (current['wind_gusts_10m'] as num?)?.toDouble();
    final weatherCode = (current['weather_code'] as num?)?.toInt();
    final isDay = ((current['is_day'] as num?)?.toInt() ?? 0) == 1;

    if (temperatureC == null ||
        windKmh == null ||
        gustKmh == null ||
        weatherCode == null) {
      throw Exception('Open-Meteo response missing current values');
    }

    final hourlyTimes = ((hourly['time'] as List?) ?? const <dynamic>[])
        .cast<num?>();
    final hourlyTemps =
        ((hourly['temperature_2m'] as List?) ?? const <dynamic>[]).cast<num?>();
    final hourlyPoints = <OpenMeteoHourlyForecastPoint>[];
    for (var i = 0; i < hourlyTimes.length && i < hourlyTemps.length; i += 1) {
      final ts = hourlyTimes[i];
      final t = hourlyTemps[i];
      if (ts == null || t == null) continue;
      hourlyPoints.add(
        OpenMeteoHourlyForecastPoint(
          timeUtc: DateTime.fromMillisecondsSinceEpoch(
            ts.toInt() * 1000,
            isUtc: true,
          ),
          temperatureC: t.toDouble(),
        ),
      );
    }

    final dailyTimes = ((daily['time'] as List?) ?? const <dynamic>[])
        .cast<num?>();
    final dailyMax =
        ((daily['temperature_2m_max'] as List?) ?? const <dynamic>[])
            .cast<num?>();
    final dailyMin =
        ((daily['temperature_2m_min'] as List?) ?? const <dynamic>[])
            .cast<num?>();
    final dailyPoints = <OpenMeteoDailyForecastPoint>[];
    for (var i = 0; i < dailyTimes.length; i += 1) {
      final dayTs = dailyTimes[i];
      final max = i < dailyMax.length ? dailyMax[i] : null;
      final min = i < dailyMin.length ? dailyMin[i] : null;
      if (dayTs == null || max == null || min == null) continue;
      dailyPoints.add(
        OpenMeteoDailyForecastPoint(
          dayUtc: DateTime.fromMillisecondsSinceEpoch(
            dayTs.toInt() * 1000,
            isUtc: true,
          ),
          maxTemperatureC: max.toDouble(),
          minTemperatureC: min.toDouble(),
        ),
      );
    }

    return OpenMeteoTodayForecast(
      temperatureC: temperatureC,
      windKmh: windKmh,
      gustKmh: gustKmh,
      weatherCode: weatherCode,
      isDay: isDay,
      sunriseUtc: DateTime.fromMillisecondsSinceEpoch(
        sunrise.toInt() * 1000,
        isUtc: true,
      ),
      sunsetUtc: DateTime.fromMillisecondsSinceEpoch(
        sunset.toInt() * 1000,
        isUtc: true,
      ),
      hourly: hourlyPoints,
      daily: dailyPoints,
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
