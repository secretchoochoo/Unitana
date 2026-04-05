import 'dart:convert';

import 'package:http/http.dart' as http;

class MetNorwayCurrentConditions {
  const MetNorwayCurrentConditions({
    required this.sampledAtUtc,
    required this.symbolCode,
    required this.temperatureC,
    required this.windKmh,
    required this.cloudCoverPercent,
  });

  final DateTime sampledAtUtc;
  final String symbolCode;
  final double? temperatureC;
  final double? windKmh;
  final int? cloudCoverPercent;
}

class MetNorwayClient {
  MetNorwayClient({
    http.Client? client,
    this.host = 'api.met.no',
    this.cacheTtl = const Duration(minutes: 10),
  }) : _client = client;

  final String host;
  final Duration cacheTtl;
  http.Client? _client;

  final Map<String, ({DateTime fetchedAtUtc, MetNorwayCurrentConditions value})>
  _cache =
      <String, ({DateTime fetchedAtUtc, MetNorwayCurrentConditions value})>{};

  http.Client get _http => _client ??= http.Client();

  Future<MetNorwayCurrentConditions> fetchCurrentConditions({
    required double latitude,
    required double longitude,
    DateTime? referenceTimeUtc,
  }) async {
    final key =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    final nowUtc = DateTime.now().toUtc();
    final cached = _cache[key];
    if (cached != null && nowUtc.difference(cached.fetchedAtUtc) < cacheTtl) {
      return cached.value;
    }

    final uri = Uri.https(
      host,
      '/weatherapi/locationforecast/2.0/compact',
      <String, String>{
        'lat': latitude.toStringAsFixed(4),
        'lon': longitude.toStringAsFixed(4),
      },
    );

    final response = await _http.get(
      uri,
      headers: const <String, String>{
        'User-Agent': 'Unitana/0.x (https://unitana.app)',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('MET Norway request failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final properties = decoded['properties'] as Map<String, dynamic>?;
    final timeseries = (properties?['timeseries'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>();
    if (timeseries == null || timeseries.isEmpty) {
      throw Exception('MET Norway response missing timeseries');
    }

    final point = _pickClosestTimeseries(
      timeseries: timeseries,
      referenceTimeUtc: referenceTimeUtc ?? nowUtc,
    );
    final data =
        point['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final instant =
        data['instant'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final details =
        instant['details'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final next1 = data['next_1_hours'] as Map<String, dynamic>?;
    final next6 = data['next_6_hours'] as Map<String, dynamic>?;
    final next12 = data['next_12_hours'] as Map<String, dynamic>?;

    final symbolCode =
        ((next1?['summary'] as Map<String, dynamic>?)?['symbol_code']
            as String?) ??
        ((next6?['summary'] as Map<String, dynamic>?)?['symbol_code']
            as String?) ??
        ((next12?['summary'] as Map<String, dynamic>?)?['symbol_code']
            as String?) ??
        'unknown';

    final value = MetNorwayCurrentConditions(
      sampledAtUtc: DateTime.parse(point['time'] as String).toUtc(),
      symbolCode: symbolCode,
      temperatureC: (details['air_temperature'] as num?)?.toDouble(),
      windKmh: ((details['wind_speed'] as num?)?.toDouble()) == null
          ? null
          : ((details['wind_speed'] as num).toDouble() * 3.6),
      cloudCoverPercent: (details['cloud_area_fraction'] as num?)?.toInt(),
    );
    _cache[key] = (fetchedAtUtc: nowUtc, value: value);
    return value;
  }

  Map<String, dynamic> _pickClosestTimeseries({
    required List<Map<String, dynamic>> timeseries,
    required DateTime referenceTimeUtc,
  }) {
    Map<String, dynamic>? best;
    Duration? bestDelta;
    for (final point in timeseries.take(12)) {
      final time = DateTime.parse(point['time'] as String).toUtc();
      final delta = time.difference(referenceTimeUtc).abs();
      if (best == null || delta < bestDelta!) {
        best = point;
        bestDelta = delta;
      }
    }
    return best ?? timeseries.first;
  }
}
