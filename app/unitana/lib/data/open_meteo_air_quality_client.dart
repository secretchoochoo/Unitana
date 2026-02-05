import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

@immutable
class OpenMeteoAirQualityCurrent {
  final int? usAqi;
  final int? europeanAqi;

  // Pollen grains/m³ for common allergens.
  final double? alder;
  final double? birch;
  final double? grass;
  final double? mugwort;
  final double? olive;
  final double? ragweed;

  const OpenMeteoAirQualityCurrent({
    required this.usAqi,
    required this.europeanAqi,
    required this.alder,
    required this.birch,
    required this.grass,
    required this.mugwort,
    required this.olive,
    required this.ragweed,
  });

  double? maxPollenGrains() {
    final values = <double?>[
      alder,
      birch,
      grass,
      mugwort,
      olive,
      ragweed,
    ].whereType<double>().toList(growable: false);
    if (values.isEmpty) return null;
    values.sort();
    return values.last;
  }
}

class OpenMeteoAirQualityClient {
  http.Client? _client;

  /// Host should be `air-quality-api.open-meteo.com` for free/non-commercial.
  /// For commercial customers, Open-Meteo may use a customer-prefixed host.
  final String host;

  OpenMeteoAirQualityClient({
    http.Client? client,
    this.host = 'air-quality-api.open-meteo.com',
  }) : _client = client;

  // Keep tests hermetic: only allocate a real HTTP client when a fetch is
  // actually invoked.
  http.Client get _http => _client ??= http.Client();

  Future<OpenMeteoAirQualityCurrent> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    // We request:
    // - current: AQI + common pollen values
    // - timezone=UTC + timeformat=unixtime to avoid ambiguous local parsing
    final uri = Uri.https(host, '/v1/air-quality', <String, String>{
      'latitude': latitude.toStringAsFixed(6),
      'longitude': longitude.toStringAsFixed(6),
      'current':
          'us_aqi,european_aqi,alder_pollen,birch_pollen,grass_pollen,mugwort_pollen,olive_pollen,ragweed_pollen',
      'timezone': 'UTC',
      'timeformat': 'unixtime',
    });

    final resp = await _http.get(
      uri,
      headers: const {'User-Agent': 'Unitana/0.x (https://unitana.app)'},
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        'Open-Meteo air quality request failed (${resp.statusCode})',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(resp.body) as Map<String, dynamic>;

    final current = json['current'] as Map<String, dynamic>?;
    if (current == null) {
      throw Exception('Open-Meteo air quality response missing current');
    }

    double? d(String k) => (current[k] as num?)?.toDouble();
    int? i(String k) => (current[k] as num?)?.toInt();

    return OpenMeteoAirQualityCurrent(
      usAqi: i('us_aqi'),
      europeanAqi: i('european_aqi'),
      alder: d('alder_pollen'),
      birch: d('birch_pollen'),
      grass: d('grass_pollen'),
      mugwort: d('mugwort_pollen'),
      olive: d('olive_pollen'),
      ragweed: d('ragweed_pollen'),
    );
  }
}
