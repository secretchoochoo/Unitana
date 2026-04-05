import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadDevSettings restores cached currency state and backend', () async {
    final cachedAt = DateTime.utc(2026, 2, 7, 10, 30);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'dev_currency_backend_v1': 'mock',
      'currency_eur_to_usd_rate_v1': 1.31,
      'currency_eur_to_usd_updated_at_v1': cachedAt.millisecondsSinceEpoch,
    });

    final live = DashboardLiveDataController();
    addTearDown(live.dispose);

    await live.loadDevSettings();

    expect(live.currencyBackend, CurrencyBackend.mock);
    expect(live.eurToUsd, closeTo(1.31, 0.000001));
    expect(
      live.currencyRate(fromCode: 'EUR', toCode: 'USD'),
      closeTo(1.31, 0.000001),
    );
    expect(
      live.lastCurrencyRefreshedAt?.millisecondsSinceEpoch,
      cachedAt.millisecondsSinceEpoch,
    );
  });
}
