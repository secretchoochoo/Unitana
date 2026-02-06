import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:unitana/data/frankfurter_client.dart';

void main() {
  test('FrankfurterClient parses EUR→USD rate', () async {
    final mock = MockClient((request) async {
      return http.Response(
        '{"amount":1.0,"base":"EUR","date":"2026-01-17","rates":{"USD":1.2345}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = FrankfurterClient(client: mock);
    final rate = await api.fetchEurToUsd(
      endpointOverride: Uri.parse('https://example.test/latest'),
    );

    expect(rate, closeTo(1.2345, 1e-9));
  });

  test('FrankfurterClient returns null on missing rate', () async {
    final mock = MockClient((request) async {
      return http.Response('{"rates":{}}', 200);
    });

    final api = FrankfurterClient(client: mock);
    final rate = await api.fetchEurToUsd(
      endpointOverride: Uri.parse('https://example.test/latest'),
    );

    expect(rate, isNull);
  });

  test('FrankfurterClient returns null on non-200 response', () async {
    final mock = MockClient((request) async {
      return http.Response('oops', 503);
    });

    final api = FrankfurterClient(client: mock);
    final rate = await api.fetchEurToUsd(
      endpointOverride: Uri.parse('https://example.test/latest'),
    );

    expect(rate, isNull);
  });

  test(
    'FrankfurterClient fetchLatestRates includes base and parsed codes',
    () async {
      final mock = MockClient((request) async {
        return http.Response(
          '{"amount":1.0,"base":"EUR","date":"2026-01-17","rates":{"USD":1.2,"JPY":160.0}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = FrankfurterClient(client: mock);
      final rates = await api.fetchLatestRates(
        base: 'EUR',
        endpointOverride: Uri.parse('https://example.test/latest'),
      );

      expect(rates, isNotNull);
      expect(rates!['EUR'], closeTo(1.0, 1e-9));
      expect(rates['USD'], closeTo(1.2, 1e-9));
      expect(rates['JPY'], closeTo(160.0, 1e-9));
    },
  );
}
