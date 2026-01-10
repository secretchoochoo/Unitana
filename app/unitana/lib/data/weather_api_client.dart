import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

@immutable
class WeatherApiForecast {
  final double temperatureC;
  final double windKmh;
  final double gustKmh;

  /// WeatherAPI condition `code` (integer).
  final int conditionCode;

  /// WeatherAPI condition `text` (human label).
  final String conditionText;

  /// Sunrise and sunset expressed as UTC instants.
  final DateTime sunriseUtc;
  final DateTime sunsetUtc;

  const WeatherApiForecast({
    required this.temperatureC,
    required this.windKmh,
    required this.gustKmh,
    required this.conditionCode,
    required this.conditionText,
    required this.sunriseUtc,
    required this.sunsetUtc,
  });
}

class WeatherApiClient {
  final String apiKey;

  /// Base endpoint used for requests.
  ///
  /// Default: `https://api.weatherapi.com`.
  /// Override via `--dart-define=WEATHERAPI_BASE_URL=...` (useful for a proxy).
  final Uri baseUri;

  /// Whether to include the API key as the `key` query parameter.
  ///
  /// Default behavior:
  /// - If `baseUri.host` ends with `weatherapi.com`, the key is sent.
  /// - Otherwise, the key is NOT sent.
  ///
  /// You can override this by passing `sendApiKey` to the constructor or by
  /// setting `--dart-define=WEATHERAPI_SEND_KEY=true|false`.
  final bool sendApiKey;
  final http.Client _client;
  final Duration cacheTtl;

  final Map<String, ({DateTime fetchedAtUtc, WeatherApiForecast value})>
  _cache = <String, ({DateTime fetchedAtUtc, WeatherApiForecast value})>{};

  WeatherApiClient({
    required this.apiKey,
    Uri? baseUri,
    bool? sendApiKey,
    http.Client? client,
    this.cacheTtl = const Duration(minutes: 10),
  }) : baseUri = _normalizeBaseUri(baseUri ?? Uri.parse(_defaultBaseUrl)),
       sendApiKey =
           sendApiKey ??
           _defaultSendApiKey(
             _normalizeBaseUri(baseUri ?? Uri.parse(_defaultBaseUrl)),
           ),
       _client = client ?? http.Client();

  /// Reads `WEATHERAPI_KEY` from `--dart-define`.
  factory WeatherApiClient.fromEnvironment() {
    final rawBase = const String.fromEnvironment(
      'WEATHERAPI_BASE_URL',
      defaultValue: _defaultBaseUrl,
    );
    final parsedBase = Uri.parse(
      rawBase.trim().isEmpty ? _defaultBaseUrl : rawBase,
    );

    final sendKeyRaw = const String.fromEnvironment(
      'WEATHERAPI_SEND_KEY',
      defaultValue: '',
    ).trim();

    final normalizedBase = _normalizeBaseUri(parsedBase);

    final bool computedSendKey = sendKeyRaw.isEmpty
        ? _defaultSendApiKey(normalizedBase)
        : (sendKeyRaw.toLowerCase() == 'true' || sendKeyRaw == '1');

    return WeatherApiClient(
      apiKey: const String.fromEnvironment('WEATHERAPI_KEY'),
      baseUri: normalizedBase,
      sendApiKey: computedSendKey,
    );
  }

  static const String _defaultBaseUrl = 'https://api.weatherapi.com';

  bool get isConfigured => !sendApiKey || apiKey.trim().isNotEmpty;

  Future<WeatherApiForecast> fetchTodayForecast({required String query}) async {
    final q = query.trim();
    if (q.isEmpty) {
      throw ArgumentError.value(
        query,
        'query',
        'Weather query must not be empty',
      );
    }
    if (!isConfigured) {
      throw StateError(
        sendApiKey
            ? 'WeatherApiClient is not configured (missing WEATHERAPI_KEY)'
            : 'WeatherApiClient is not configured',
      );
    }

    final nowUtc = DateTime.now().toUtc();
    final cached = _cache[q];
    if (cached != null && nowUtc.difference(cached.fetchedAtUtc) < cacheTtl) {
      return cached.value;
    }

    final params = <String, String>{
      if (sendApiKey) 'key': apiKey,
      'q': q,
      'days': '1',
      'aqi': 'no',
      'alerts': 'no',
    };

    final uri = baseUri.replace(
      path: _joinPath(baseUri.path, '/v1/forecast.json'),
      queryParameters: params,
    );

    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw StateError(
        'WeatherAPI request failed (${resp.statusCode}): ${resp.body}',
      );
    }

    final decoded = json.decode(resp.body) as Map<String, dynamic>;

    final location =
        decoded['location'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final current =
        decoded['current'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    final tempC = (current['temp_c'] as num?)?.toDouble() ?? 0.0;
    final windKph = (current['wind_kph'] as num?)?.toDouble() ?? 0.0;
    final gustKph = (current['gust_kph'] as num?)?.toDouble() ?? windKph;

    final condition =
        current['condition'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final conditionCode = (condition['code'] as num?)?.toInt() ?? 1000;
    final conditionText = (condition['text'] as String?)?.trim() ?? '';

    // Compute the timezone offset for this location at the reported local time.
    //
    // WeatherAPI provides:
    // - location.localtime_epoch (seconds since epoch; an absolute instant)
    // - location.localtime (wall-clock local time in the location)
    //
    // We derive offsetSeconds by comparing:
    // - naiveLocalUtc: treating the wall-clock local components as if they were UTC
    // - actualUtc: the epoch instant (UTC)
    //
    // offsetSeconds == naiveLocalUtc - actualUtc
    final localEpoch = (location['localtime_epoch'] as num?)?.toInt();
    final localtimeStr = (location['localtime'] as String?)?.trim() ?? '';
    final localParts = _parseLocaltimeComponents(localtimeStr);
    final offsetSeconds = (localEpoch != null && localParts != null)
        ? _computeOffsetSeconds(
            localEpochSeconds: localEpoch,
            local: localParts,
          )
        : 0;

    // Pull today's sunrise/sunset from forecast astro.
    DateTime sunriseUtc = nowUtc;
    DateTime sunsetUtc = nowUtc.add(const Duration(hours: 12));

    final forecast = decoded['forecast'] as Map<String, dynamic>?;
    final days =
        (forecast?['forecastday'] as List?)?.cast<dynamic>() ??
        const <dynamic>[];
    if (days.isNotEmpty) {
      final day0 = days.first as Map<String, dynamic>;
      final astro = day0['astro'] as Map<String, dynamic>?;

      final sunriseStr = (astro?['sunrise'] as String?)?.trim() ?? '';
      final sunsetStr = (astro?['sunset'] as String?)?.trim() ?? '';

      if (localParts != null) {
        final sunrise = _parse12hClock(sunriseStr);
        final sunset = _parse12hClock(sunsetStr);

        if (sunrise != null) {
          final naive = DateTime.utc(
            localParts.year,
            localParts.month,
            localParts.day,
            sunrise.hour,
            sunrise.minute,
          );
          sunriseUtc = naive.subtract(Duration(seconds: offsetSeconds));
        }
        if (sunset != null) {
          final naive = DateTime.utc(
            localParts.year,
            localParts.month,
            localParts.day,
            sunset.hour,
            sunset.minute,
          );
          sunsetUtc = naive.subtract(Duration(seconds: offsetSeconds));
        }
      }
    }

    final result = WeatherApiForecast(
      temperatureC: tempC,
      windKmh: windKph,
      gustKmh: gustKph,
      conditionCode: conditionCode,
      conditionText: conditionText,
      sunriseUtc: sunriseUtc,
      sunsetUtc: sunsetUtc,
    );

    _cache[q] = (fetchedAtUtc: nowUtc, value: result);
    return result;
  }

  static _LocalDateParts? _parseLocaltimeComponents(String localtime) {
    // Expected: "YYYY-MM-DD HH:MM" (WeatherAPI format)
    final m = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})',
    ).firstMatch(localtime);
    if (m == null) return null;
    return _LocalDateParts(
      year: int.parse(m.group(1)!),
      month: int.parse(m.group(2)!),
      day: int.parse(m.group(3)!),
      hour: int.parse(m.group(4)!),
      minute: int.parse(m.group(5)!),
    );
  }

  static int _computeOffsetSeconds({
    required int localEpochSeconds,
    required _LocalDateParts local,
  }) {
    final actualUtc = DateTime.fromMillisecondsSinceEpoch(
      localEpochSeconds * 1000,
      isUtc: true,
    );
    final naiveLocalUtc = DateTime.utc(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
    return naiveLocalUtc.difference(actualUtc).inSeconds;
  }

  static _ClockTime? _parse12hClock(String value) {
    // Examples: "7:52 AM", "12:05 PM"
    final m = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])').firstMatch(value);
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final mer = m.group(3)!.toUpperCase();

    if (hour < 1 || hour > 12) return null;
    if (minute < 0 || minute > 59) return null;

    if (mer == 'AM') {
      if (hour == 12) hour = 0;
    } else {
      if (hour != 12) hour += 12;
    }
    return _ClockTime(hour: hour, minute: minute);
  }

  static Uri _normalizeBaseUri(Uri input) {
    // If a user passes a host-only string (e.g. "proxy.example.com"),
    // Uri.parse will treat it as a path. Normalize by forcing https.
    if (input.scheme.isEmpty && input.host.isEmpty && input.path.isNotEmpty) {
      return Uri.parse('https://${input.path}');
    }
    if (input.scheme.isEmpty && input.host.isNotEmpty) {
      return input.replace(scheme: 'https');
    }
    return input;
  }

  static bool _defaultSendApiKey(Uri? base) {
    final uri = base ?? Uri.parse(_defaultBaseUrl);
    return uri.host.toLowerCase().endsWith('weatherapi.com');
  }

  static String _joinPath(String base, String next) {
    final b = base.trim();
    final n = next.trim();
    if (b.isEmpty || b == '/') {
      return n.startsWith('/') ? n : '/$n';
    }
    final baseNoTrail = b.endsWith('/') ? b.substring(0, b.length - 1) : b;
    final nextNoLead = n.startsWith('/') ? n.substring(1) : n;
    return '$baseNoTrail/$nextNoLead';
  }
}

@immutable
class _LocalDateParts {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;

  const _LocalDateParts({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
  });
}

@immutable
class _ClockTime {
  final int hour;
  final int minute;

  const _ClockTime({required this.hour, required this.minute});
}
