import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/data/country_currency_map.dart';

void main() {
  test('country currency map covers all countries in city dataset', () {
    final rows =
        jsonDecode(File('assets/data/cities_v1.json').readAsStringSync())
            as List<dynamic>;

    final expected = <String, String>{};
    for (final raw in rows) {
      final row = raw as Map<String, dynamic>;
      final cc = (row['countryCode'] ?? '').toString().trim().toUpperCase();
      final cur = (row['currencyCode'] ?? '').toString().trim().toUpperCase();
      if (cc.isEmpty || cur.isEmpty) continue;
      expected.putIfAbsent(cc, () => cur);
    }

    for (final entry in expected.entries) {
      expect(
        kCountryToCurrencyCode[entry.key],
        entry.value,
        reason: 'country ${entry.key} expected ${entry.value}',
      );
    }
  });
}
