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
class OpenMeteoTodayForecast {
  final double temperatureC;
  final double windKmh;
  final double gustKmh;
  final int weatherCode;
  final bool isDay;
  final DateTime sunriseUtc;
  final DateTime sunsetUtc;

  const OpenMeteoTodayForecast({
    required this.temperatureC,
    required this.windKmh,
    required this.gustKmh,
    required this.weatherCode,
    required this.isDay,
    required this.sunriseUtc,
    required this.sunsetUtc,
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
    // - daily: sunrise + sunset
    // - timezone=UTC + timeformat=unixtime to avoid ambiguous local parsing
    final uri = Uri.https(host, '/v1/forecast', <String, String>{
      'latitude': latitude.toStringAsFixed(6),
      'longitude': longitude.toStringAsFixed(6),
      'current':
          'temperature_2m,wind_speed_10m,wind_gusts_10m,weather_code,is_day',
      'daily': 'sunrise,sunset',
      'forecast_days': '1',
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
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
