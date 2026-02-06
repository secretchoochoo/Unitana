import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unitana/data/frankfurter_client.dart';
import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';

class _FakeFrankfurterClient extends FrankfurterClient {
  int latestRatesCalls = 0;
  int failLatestRatesCount = 0;
  Map<String, double>? latestRatesResult;

  @override
  Future<Map<String, double>?> fetchLatestRates({
    String base = 'EUR',
    Uri? endpointOverride,
  }) async {
    latestRatesCalls += 1;
    if (failLatestRatesCount > 0) {
      failLatestRatesCount -= 1;
      throw StateError('frankfurter outage');
    }
    return latestRatesResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  test('currency refresh caches rate and respects stale TTL', () async {
    final fake = _FakeFrankfurterClient()
      ..latestRatesResult = <String, double>{'EUR': 1.0, 'USD': 1.23};

    final live = DashboardLiveDataController(
      frankfurterClient: fake,
      allowLiveRefreshInTestHarness: true,
      refreshDebounceDuration: Duration.zero,
      simulatedNetworkLatency: Duration.zero,
      currencyRetryBackoffDuration: Duration.zero,
    );
    addTearDown(live.dispose);

    await live.setCurrencyBackend(CurrencyBackend.frankfurter);
    await live.refreshAll(places: const []);

    expect(fake.latestRatesCalls, 1);
    expect(live.lastCurrencyRefreshedAt, isNotNull);
    expect(live.lastCurrencyError, isNull);
    expect(live.isCurrencyStale, isFalse);
    expect(
      live.currencyRate(fromCode: 'EUR', toCode: 'USD'),
      closeTo(1.23, 0.000001),
    );

    // Fresh rates should not refetch inside TTL.
    fake.latestRatesResult = <String, double>{'EUR': 1.0, 'USD': 1.30};
    await live.refreshAll(places: const []);
    expect(fake.latestRatesCalls, 1);
  });

  test(
    'currency refresh backoff suppresses immediate retry after failure',
    () async {
      final fake = _FakeFrankfurterClient()
        ..latestRatesResult = <String, double>{'EUR': 1.0, 'USD': 1.15}
        ..failLatestRatesCount = 1;

      final live = DashboardLiveDataController(
        frankfurterClient: fake,
        allowLiveRefreshInTestHarness: true,
        refreshDebounceDuration: Duration.zero,
        simulatedNetworkLatency: Duration.zero,
        currencyRetryBackoffDuration: const Duration(hours: 1),
      );
      addTearDown(live.dispose);

      await live.setCurrencyBackend(CurrencyBackend.frankfurter);
      await live.refreshAll(places: const []);

      expect(fake.latestRatesCalls, 1);
      expect(live.lastCurrencyError, isNotNull);
      expect(live.lastCurrencyErrorAt, isNotNull);
      expect(live.shouldRetryCurrencyNow, isFalse);

      await live.refreshAll(places: const []);
      expect(fake.latestRatesCalls, 1);
    },
  );

  test('currency refresh retries immediately when backoff is zero', () async {
    final fake = _FakeFrankfurterClient()
      ..latestRatesResult = <String, double>{'EUR': 1.0, 'USD': 1.41}
      ..failLatestRatesCount = 1;

    final live = DashboardLiveDataController(
      frankfurterClient: fake,
      allowLiveRefreshInTestHarness: true,
      refreshDebounceDuration: Duration.zero,
      simulatedNetworkLatency: Duration.zero,
      currencyRetryBackoffDuration: Duration.zero,
    );
    addTearDown(live.dispose);

    await live.setCurrencyBackend(CurrencyBackend.frankfurter);
    await live.refreshAll(places: const []);
    expect(fake.latestRatesCalls, 1);
    expect(live.lastCurrencyError, isNotNull);

    await live.refreshAll(places: const []);
    expect(fake.latestRatesCalls, 2);
    expect(live.lastCurrencyError, isNull);
    expect(live.lastCurrencyRefreshedAt, isNotNull);
    expect(
      live.currencyRate(fromCode: 'EUR', toCode: 'USD'),
      closeTo(1.41, 0.000001),
    );
  });
}
