import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/data/country_currency_map.dart';
import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';

void main() {
  test('currencyRate resolves for all mapped currencies', () {
    final live = DashboardLiveDataController();
    addTearDown(live.dispose);

    final currencies =
        kCountryToCurrencyCode.values
            .map((c) => c.trim().toUpperCase())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    for (final from in currencies) {
      // Same-currency must be identity.
      final same = live.currencyRate(fromCode: from, toCode: from);
      expect(same, equals(1.0), reason: '$from->$from should be 1.0');

      // Every mapped currency should be able to convert to USD and EUR.
      final toUsd = live.currencyRate(fromCode: from, toCode: 'USD');
      final toEur = live.currencyRate(fromCode: from, toCode: 'EUR');
      expect(toUsd, isNotNull, reason: '$from->USD missing');
      expect(toEur, isNotNull, reason: '$from->EUR missing');
      expect(toUsd!, greaterThan(0), reason: '$from->USD <= 0');
      expect(toEur!, greaterThan(0), reason: '$from->EUR <= 0');
    }

    // High-variance spot checks.
    final jpyToUsd = live.currencyRate(fromCode: 'JPY', toCode: 'USD');
    final usdToJpy = live.currencyRate(fromCode: 'USD', toCode: 'JPY');
    expect(jpyToUsd, isNotNull);
    expect(usdToJpy, isNotNull);
    expect(jpyToUsd!, greaterThan(0));
    expect(usdToJpy!, greaterThan(0));
  });
}
