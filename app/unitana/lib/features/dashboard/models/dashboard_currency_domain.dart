part of 'dashboard_live_data.dart';

class _DashboardCurrencyDomain {
  _DashboardCurrencyDomain({
    required FrankfurterClient frankfurterClient,
    required OpenErApiClient openErApiClient,
  }) : _frankfurter = frankfurterClient,
       _openErApi = openErApiClient;

  static const String _kDevCurrencyBackend = 'dev_currency_backend_v1';
  static const String _kCachedEurToUsdRate = 'currency_eur_to_usd_rate_v1';
  static const String _kCachedEurToUsdUpdatedAt =
      'currency_eur_to_usd_updated_at_v1';
  static const Duration _currencyTtl = Duration(minutes: 10);

  final FrankfurterClient _frankfurter;
  final OpenErApiClient _openErApi;

  CurrencyBackend _backend = _currencyBackendFromEnv();
  double _eurToUsd = 1.10;
  final Map<String, double> _eurBaseRates = <String, double>{'EUR': 1.0};
  DateTime? _lastRefreshedAt;
  DateTime? _lastErrorAt;
  Object? _lastError;

  CurrencyBackend get backend => _backend;
  double get eurToUsd => _eurToUsd;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;
  DateTime? get lastErrorAt => _lastErrorAt;
  Object? get lastError => _lastError;
  Duration get refreshCadence => _currencyTtl;

  static CurrencyBackend _currencyBackendFromEnv() {
    if (!DashboardLiveDataController._envCurrencyNetworkEnabled) {
      return CurrencyBackend.mock;
    }
    switch (DashboardLiveDataController._envCurrencyProvider.toLowerCase()) {
      case 'frankfurter':
        return CurrencyBackend.frankfurter;
      default:
        return CurrencyBackend.mock;
    }
  }

  static String _currencyBackendKey(CurrencyBackend backend) {
    switch (backend) {
      case CurrencyBackend.frankfurter:
        return 'frankfurter';
      case CurrencyBackend.mock:
        return 'mock';
    }
  }

  void debugSetLastRefreshedAt(DateTime? value) {
    _lastRefreshedAt = value;
  }

  bool isStale({DateTime? now}) {
    final last = _lastRefreshedAt;
    if (last == null) return true;
    return (now ?? DateTime.now()).difference(last) > _currencyTtl;
  }

  bool shouldRetryNow({
    required DateTime now,
    required bool currencyNetworkEnabled,
    required Duration retryBackoffDuration,
  }) {
    if (!currencyNetworkEnabled) return false;
    final errAt = _lastErrorAt;
    if (errAt == null) return isStale(now: now);
    return now.difference(errAt) >= retryBackoffDuration;
  }

  double? currencyRate({
    required String fromCode,
    required String toCode,
    double? debugEurToUsd,
  }) {
    final from = fromCode.trim().toUpperCase();
    final to = toCode.trim().toUpperCase();
    if (from.isEmpty || to.isEmpty) return null;
    if (from == to) return 1.0;

    final rates = _effectiveEurBaseRates(debugEurToUsd: debugEurToUsd);
    final fromRate = rates[from] ?? _mockEurRateForCode(from);
    final toRate = rates[to] ?? _mockEurRateForCode(to);
    if (fromRate <= 0 || toRate <= 0) return null;
    return toRate / fromRate;
  }

  void loadPersistedState({
    required SharedPreferences prefs,
    required bool developerToolsEnabled,
    required bool currencyNetworkAllowed,
  }) {
    final currencyRaw = prefs.getString(_kDevCurrencyBackend);
    if (developerToolsEnabled &&
        currencyRaw != null &&
        currencyRaw.trim().isNotEmpty) {
      final norm = currencyRaw.trim().toLowerCase();
      final CurrencyBackend next = norm == 'frankfurter'
          ? CurrencyBackend.frankfurter
          : CurrencyBackend.mock;

      if (!currencyNetworkAllowed && next != CurrencyBackend.mock) {
        _backend = CurrencyBackend.mock;
      } else {
        _backend = next;
      }
    }

    final cachedRate = prefs.getDouble(_kCachedEurToUsdRate);
    if (cachedRate != null && cachedRate > 0) {
      _eurToUsd = cachedRate;
      _eurBaseRates['USD'] = cachedRate;
    }

    final cachedAt = prefs.getInt(_kCachedEurToUsdUpdatedAt);
    if (cachedAt != null && cachedAt > 0) {
      _lastRefreshedAt = DateTime.fromMillisecondsSinceEpoch(cachedAt);
    }
  }

  void setBackend(CurrencyBackend backend) {
    _backend = backend;
  }

  Future<void> persistBackendPreference(SharedPreferences prefs) async {
    await prefs.setString(_kDevCurrencyBackend, _currencyBackendKey(_backend));
  }

  void restoreMockDefaults() {
    _eurToUsd = 1.10;
    _eurBaseRates['USD'] = _eurToUsd;
  }

  Future<bool> maybeRefresh({
    required int refreshGeneration,
    required bool Function(int refreshGeneration) isCurrentRefresh,
    required bool currencyNetworkEnabled,
    required Duration retryBackoffDuration,
    required void Function(
      Object error,
      StackTrace stackTrace,
      String contextLabel,
    )
    recordRefreshError,
  }) async {
    if (!currencyNetworkEnabled) return false;

    final now = DateTime.now();
    if (!isStale(now: now)) return false;

    final errAt = _lastErrorAt;
    if (errAt != null && now.difference(errAt) < retryBackoffDuration) {
      return false;
    }

    try {
      double? rate;
      Map<String, double>? normalizedRates;
      switch (_backend) {
        case CurrencyBackend.frankfurter:
          final frankfurterRates = await _frankfurter.fetchLatestRates(
            base: 'EUR',
          );
          if (!isCurrentRefresh(refreshGeneration)) {
            return false;
          }
          if (frankfurterRates != null && frankfurterRates.isNotEmpty) {
            normalizedRates = _normalizeEurBaseRates(frankfurterRates);
          } else {
            final openErRates = await _openErApi.fetchLatestRates(base: 'EUR');
            if (!isCurrentRefresh(refreshGeneration)) {
              return false;
            }
            if (openErRates != null && openErRates.isNotEmpty) {
              normalizedRates = _normalizeEurBaseRates(openErRates);
            }
          }

          rate = normalizedRates?['USD'];
          if (rate == null || rate <= 0) {
            rate = await _frankfurter.fetchEurToUsd();
            if (!isCurrentRefresh(refreshGeneration)) {
              return false;
            }
            if (rate == null || rate <= 0) {
              rate = await _openErApi.fetchEurToUsd();
              if (!isCurrentRefresh(refreshGeneration)) {
                return false;
              }
            }
            if (rate != null && rate > 0) {
              normalizedRates ??= <String, double>{'EUR': 1.0};
              normalizedRates['USD'] = rate;
            }
          }
          break;
        case CurrencyBackend.mock:
          rate = null;
          break;
      }

      if (!isCurrentRefresh(refreshGeneration)) {
        return false;
      }

      if (normalizedRates != null && normalizedRates.isNotEmpty) {
        _eurBaseRates.addAll(normalizedRates);
      }
      if (rate == null || rate <= 0) {
        _lastError = StateError('Currency payload missing EUR->USD rate');
        _lastErrorAt = now;
        return false;
      }

      _eurToUsd = rate;
      _eurBaseRates['USD'] = rate;
      _lastRefreshedAt = now;
      _lastError = null;
      _lastErrorAt = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kCachedEurToUsdRate, rate);
      await prefs.setInt(_kCachedEurToUsdUpdatedAt, now.millisecondsSinceEpoch);
      return true;
    } catch (error, stackTrace) {
      if (!isCurrentRefresh(refreshGeneration)) {
        return false;
      }
      recordRefreshError(error, stackTrace, 'while refreshing currency rates');
      _lastError = error;
      _lastErrorAt = now;
      return false;
    }
  }

  static Map<String, double> _normalizeEurBaseRates(Map<String, double> raw) {
    final out = <String, double>{'EUR': 1.0};
    raw.forEach((code, value) {
      final cc = code.trim().toUpperCase();
      if (cc.isEmpty || !value.isFinite || value <= 0) return;
      out[cc] = value;
    });
    return out;
  }

  Map<String, double> _effectiveEurBaseRates({double? debugEurToUsd}) {
    final rates = <String, double>{..._eurBaseRates};
    if (debugEurToUsd != null && debugEurToUsd > 0) {
      rates['USD'] = debugEurToUsd;
    }
    rates['EUR'] = 1.0;
    return rates;
  }

  double _mockEurRateForCode(String code) {
    switch (code) {
      case 'USD':
        return 1.10;
      case 'JPY':
        return 160.0;
      case 'GBP':
        return 0.86;
      case 'CHF':
        return 0.95;
      case 'CAD':
        return 1.48;
      case 'AUD':
        return 1.66;
      case 'NZD':
        return 1.80;
      case 'CNY':
        return 7.90;
      case 'INR':
        return 90.0;
      case 'KRW':
        return 1450.0;
      case 'VND':
        return 27000.0;
      case 'IDR':
        return 17000.0;
      case 'BRL':
        return 5.90;
      case 'MXN':
        return 19.0;
      case 'RUB':
        return 100.0;
      case 'TRY':
        return 37.0;
      case 'ZAR':
        return 21.0;
      default:
        final hash = code.codeUnits.fold<int>(
          0,
          (sum, u) => ((sum * 131) + u) & 0x7fffffff,
        );
        final scaled = 0.35 + ((hash % 9650) / 1000.0);
        return scaled;
    }
  }
}
