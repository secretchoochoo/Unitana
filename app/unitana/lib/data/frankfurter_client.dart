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

    final rates = _parseRates(resp.body);
    if (rates == null) return null;

    final usd = rates['USD'];
    if (usd is num) {
      return usd.toDouble();
    }
    if (usd is String) {
      return double.tryParse(usd);
    }

    return null;
  }

  /// Fetch latest rates quoted against [base] (e.g. EUR base gives EUR->XXX).
  ///
  /// Returns null on non-200 responses or unexpected payloads.
  Future<Map<String, double>?> fetchLatestRates({
    String base = 'EUR',
    Uri? endpointOverride,
  }) async {
    final normalizedBase = base.trim().toUpperCase();
    if (normalizedBase.isEmpty) return null;

    final uri =
        endpointOverride ??
        Uri.parse('https://api.frankfurter.app/latest?from=$normalizedBase');
    final resp = await _client.get(
      uri,
      headers: const {'accept': 'application/json'},
    );
    if (resp.statusCode != 200) {
      return null;
    }

    final parsed = _parseRates(resp.body);
    if (parsed == null) return null;

    final out = <String, double>{normalizedBase: 1.0};
    parsed.forEach((code, value) {
      final cc = code.trim().toUpperCase();
      if (cc.isEmpty) return;
      final parsedValue = switch (value) {
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
      if (parsedValue == null || !parsedValue.isFinite || parsedValue <= 0) {
        return;
      }
      out[cc] = parsedValue;
    });
    return out;
  }

  Map<String, dynamic>? _parseRates(String body) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final rates = decoded['rates'];
    if (rates is! Map<String, dynamic>) {
      return null;
    }
    return rates;
  }
}
