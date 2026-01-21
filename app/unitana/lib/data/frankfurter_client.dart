import 'dart:convert';

import 'package:http/http.dart' as http;

/// Minimal client for Frankfurter exchange rates.
///
/// Public API: https://www.frankfurter.app/
///
/// This client is intentionally small-scope and designed for low-frequency use
/// (hours-scale TTL), not minute-by-minute streaming.
class FrankfurterClient {
  final http.Client _client;

  FrankfurterClient({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch the latest EUR→USD rate.
  ///
  /// Returns null on non-200 responses or unexpected payloads.
  Future<double?> fetchEurToUsd({Uri? endpointOverride}) async {
    final uri =
        endpointOverride ??
        Uri.parse('https://api.frankfurter.app/latest?from=EUR&to=USD');

    final resp = await _client.get(
      uri,
      headers: const {'accept': 'application/json'},
    );

    if (resp.statusCode != 200) {
      return null;
    }

    final dynamic decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final rates = decoded['rates'];
    if (rates is! Map) {
      return null;
    }

    final usd = rates['USD'];
    if (usd is num) {
      return usd.toDouble();
    }
    if (usd is String) {
      return double.tryParse(usd);
    }

    return null;
  }
}
