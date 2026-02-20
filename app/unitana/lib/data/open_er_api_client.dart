import 'dart:convert';

import 'package:http/http.dart' as http;

/// Minimal client for open.er-api.com exchange rates.
class OpenErApiClient {
  final http.Client _client;

  OpenErApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<double?> fetchEurToUsd({Uri? endpointOverride}) async {
    final rates = await fetchLatestRates(
      base: 'EUR',
      endpointOverride: endpointOverride,
    );
    return rates?['USD'];
  }

  Future<Map<String, double>?> fetchLatestRates({
    String base = 'EUR',
    Uri? endpointOverride,
  }) async {
    final normalizedBase = base.trim().toUpperCase();
    if (normalizedBase.isEmpty) return null;

    final uri =
        endpointOverride ??
        Uri.parse('https://open.er-api.com/v6/latest/$normalizedBase');
    final resp = await _client.get(
      uri,
      headers: const {'accept': 'application/json'},
    );
    if (resp.statusCode != 200) return null;

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) return null;

    final ratesRaw = decoded['rates'];
    if (ratesRaw is! Map) return null;

    final out = <String, double>{normalizedBase: 1.0};
    for (final entry in ratesRaw.entries) {
      final key = entry.key.toString().trim().toUpperCase();
      if (key.isEmpty) continue;
      final valueRaw = entry.value;
      final value = switch (valueRaw) {
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
      if (value == null || !value.isFinite || value <= 0) continue;
      out[key] = value;
    }
    return out;
  }
}
