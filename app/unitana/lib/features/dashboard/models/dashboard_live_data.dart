import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:flutter/scheduler.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/city_repository.dart';
import '../../../data/weather_api_client.dart';
import '../../../data/open_meteo_client.dart';
import '../../../data/open_meteo_air_quality_client.dart';
import '../../../data/frankfurter_client.dart';
import '../../../models/place.dart';
import '../../../utils/timezone_utils.dart';

enum WeatherBackend {
  /// No network; deterministic demo drift.
  mock,

  /// Live weather from Open-Meteo (no API key required).
  openMeteo,

  /// Live weather from WeatherAPI (requires WEATHERAPI_KEY).
  weatherApi,
}

enum CurrencyBackend {
  /// No network; uses a stable demo rate.
  mock,

  /// Live FX from Frankfurter (ECB-based).
  frankfurter,
}

enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  overcast,
  drizzle,
  rain,
  thunderstorm,
  snow,
  sleet,
  hail,
  fog,
  mist,
  haze,
  smoke,
  dust,
  sand,
  ash,
  squall,
  tornado,
  windy,
}

/// Provider-agnostic stable identifier for hero marquee scenes.
///
/// These keys are defined in docs/ai/reference/SCENEKEY_CATALOG.md and are
/// intended to remain stable even as weather providers change.
enum SceneKey {
  clear,
  partlyCloudy,
  cloudy,
  overcast,
  mist,
  fog,
  drizzle,
  freezingDrizzle,
  rainLight,
  rainModerate,
  rainHeavy,
  freezingRain,
  sleet,
  snowLight,
  snowModerate,
  snowHeavy,
  blowingSnow,
  blizzard,
  icePellets,
  thunderRain,
  thunderSnow,
  hazeDust,
  smokeWildfire,
  ashfall,
  windy,
  tornado,
  squall,
}

/// Maps WeatherAPI `condition.code` values into Unitana's stable [SceneKey] catalog.
///
/// Derived from docs/ai/reference/SCENEKEY_CATALOG.md (WeatherAPI MVP section).
/// Provider mapping lives here (model layer), not in the UI.
class WeatherApiSceneKeyMapper {
  const WeatherApiSceneKeyMapper._();

  static SceneKey fromWeatherApi({required int code, required String text}) {
    switch (code) {
      case 1000:
        return SceneKey.clear;
      case 1003:
        return SceneKey.partlyCloudy;
      case 1006:
        return SceneKey.cloudy;
      case 1009:
        return SceneKey.overcast;

      case 1030:
        return SceneKey.mist;
      case 1135:
      case 1147:
        return SceneKey.fog;

      case 1150:
      case 1153:
        return SceneKey.drizzle;
      case 1168:
      case 1171:
        return SceneKey.freezingDrizzle;

      case 1063:
      case 1180:
      case 1183:
      case 1240:
        return SceneKey.rainLight;
      case 1186:
      case 1189:
      case 1243:
        return SceneKey.rainModerate;
      case 1192:
      case 1195:
      case 1246:
        return SceneKey.rainHeavy;
      case 1198:
      case 1201:
        return SceneKey.freezingRain;

      case 1069:
      case 1204:
      case 1207:
      case 1249:
      case 1252:
        return SceneKey.sleet;

      case 1066:
      case 1210:
      case 1213:
      case 1255:
        return SceneKey.snowLight;
      case 1216:
      case 1219:
      case 1258:
        return SceneKey.snowModerate;
      case 1222:
      case 1225:
        return SceneKey.snowHeavy;

      case 1114:
        return SceneKey.blowingSnow;
      case 1117:
        return SceneKey.blizzard;

      case 1237:
      case 1261:
      case 1264:
        return SceneKey.icePellets;

      case 1087:
      case 1273:
      case 1276:
        return SceneKey.thunderRain;
      case 1279:
      case 1282:
        return SceneKey.thunderSnow;
    }

    // Fallback heuristics (text is provider-managed, but useful for "unknown code").
    final t = text.toLowerCase();
    if (t.contains('thunder')) {
      return SceneKey.thunderRain;
    }
    if (t.contains('blizzard')) {
      return SceneKey.blizzard;
    }
    if (t.contains('blowing snow')) {
      return SceneKey.blowingSnow;
    }
    if (t.contains('snow')) {
      return SceneKey.snowModerate;
    }
    if (t.contains('sleet')) {
      return SceneKey.sleet;
    }
    if (t.contains('freezing drizzle')) {
      return SceneKey.freezingDrizzle;
    }
    if (t.contains('freezing rain')) {
      return SceneKey.freezingRain;
    }
    if (t.contains('ice pellets') ||
        t.contains('pellets') ||
        t.contains('hail')) {
      return SceneKey.icePellets;
    }
    if (t.contains('drizzle')) {
      return SceneKey.drizzle;
    }
    if (t.contains('heavy rain')) {
      return SceneKey.rainHeavy;
    }
    if (t.contains('rain') || t.contains('shower')) {
      return SceneKey.rainModerate;
    }
    if (t.contains('fog')) {
      return SceneKey.fog;
    }
    if (t.contains('mist')) {
      return SceneKey.mist;
    }
    if (t.contains('overcast')) {
      return SceneKey.overcast;
    }
    if (t.contains('cloud')) {
      return SceneKey.cloudy;
    }
    if (t.contains('sunny') || t.contains('clear')) {
      return SceneKey.clear;
    }

    return SceneKey.partlyCloudy;
  }
}

/// Maps coarse internal dev override selections into a stable [SceneKey].

sealed class WeatherDebugOverride {
  const WeatherDebugOverride();
}

class WeatherDebugOverrideCoarse extends WeatherDebugOverride {
  const WeatherDebugOverrideCoarse(this.condition, {this.isNightOverride});

  final WeatherCondition condition;

  /// When null, hero uses sunrise/sunset (or time heuristic) to decide night.
  /// When set, this forces the hero into day (false) or night (true) visuals.
  final bool? isNightOverride;
}

class WeatherDebugOverrideWeatherApi extends WeatherDebugOverride {
  const WeatherDebugOverrideWeatherApi({
    required this.code,
    required this.isNight,
    required this.text,
  });

  final int code;
  final bool isNight;
  final String text;
}

/// Maps Open-Meteo `weather_code` (WMO) values into Unitana's stable [SceneKey] catalog.
///
/// Open-Meteo uses WMO weather interpretation codes. We map them into the same
/// scene taxonomy used for WeatherAPI so the UI remains provider-agnostic.
class OpenMeteoSceneKeyMapper {
  const OpenMeteoSceneKeyMapper._();

  static SceneKey fromWmoCode(int code) {
    switch (code) {
      case 0:
        return SceneKey.clear;
      case 1:
      case 2:
        return SceneKey.partlyCloudy;
      case 3:
        return SceneKey.overcast;

      case 45:
      case 48:
        return SceneKey.fog;

      case 51:
      case 53:
      case 55:
        return SceneKey.drizzle;
      case 56:
      case 57:
        return SceneKey.freezingDrizzle;

      case 61:
        return SceneKey.rainLight;
      case 63:
        return SceneKey.rainModerate;
      case 65:
        return SceneKey.rainHeavy;

      case 66:
      case 67:
        return SceneKey.freezingRain;

      case 71:
      case 77:
        return SceneKey.snowLight;
      case 73:
        return SceneKey.snowModerate;
      case 75:
        return SceneKey.snowHeavy;

      case 80:
        return SceneKey.rainLight;
      case 81:
        return SceneKey.rainModerate;
      case 82:
        return SceneKey.rainHeavy;

      case 85:
      case 86:
        return SceneKey.snowModerate;

      case 95:
      case 96:
      case 99:
        return SceneKey.thunderRain;

      default:
        // Unknown or unsupported codes fall back to overcast.
        return SceneKey.overcast;
    }
  }

  static String labelFor(int code) {
    switch (code) {
      case 0:
        return 'Clear';
      case 1:
        return 'Mostly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing drizzle';
      case 61:
        return 'Light rain';
      case 63:
        return 'Rain';
      case 65:
        return 'Heavy rain';
      case 66:
      case 67:
        return 'Freezing rain';
      case 71:
        return 'Light snow';
      case 73:
        return 'Snow';
      case 75:
        return 'Heavy snow';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Weather';
    }
  }
}

class WeatherConditionSceneKeyMapper {
  const WeatherConditionSceneKeyMapper._();

  static SceneKey fromWeatherCondition(WeatherCondition c) {
    switch (c) {
      case WeatherCondition.clear:
        return SceneKey.clear;
      case WeatherCondition.partlyCloudy:
        return SceneKey.partlyCloudy;
      case WeatherCondition.cloudy:
        return SceneKey.cloudy;
      case WeatherCondition.overcast:
        return SceneKey.overcast;
      case WeatherCondition.mist:
        return SceneKey.mist;
      case WeatherCondition.fog:
        return SceneKey.fog;
      case WeatherCondition.drizzle:
        return SceneKey.drizzle;
      case WeatherCondition.rain:
        return SceneKey.rainModerate;
      case WeatherCondition.thunderstorm:
        return SceneKey.thunderRain;
      case WeatherCondition.snow:
        return SceneKey.snowModerate;
      case WeatherCondition.sleet:
        return SceneKey.sleet;
      case WeatherCondition.hail:
        return SceneKey.icePellets;
      case WeatherCondition.haze:
      case WeatherCondition.dust:
      case WeatherCondition.sand:
        return SceneKey.hazeDust;
      case WeatherCondition.smoke:
        return SceneKey.smokeWildfire;
      case WeatherCondition.ash:
        return SceneKey.ashfall;
      case WeatherCondition.windy:
        return SceneKey.windy;
      case WeatherCondition.tornado:
        return SceneKey.tornado;
      case WeatherCondition.squall:
        return SceneKey.squall;
    }
  }
}

@immutable
class WeatherSnapshot {
  final double temperatureC;
  final double windKmh;
  final double gustKmh;
  final SceneKey sceneKey;

  /// Provider-supplied condition text (e.g., "Light rain").
  ///
  /// Used for explicit user-facing labels in the hero marquee.
  final String conditionText;

  /// Provider code when available (WeatherAPI condition.code). Optional.
  final int? conditionCode;

  const WeatherSnapshot({
    required this.temperatureC,
    required this.windKmh,
    required this.gustKmh,
    required this.sceneKey,
    required this.conditionText,
    this.conditionCode,
  });
}

@immutable
class SunTimesSnapshot {
  final DateTime sunriseUtc;
  final DateTime sunsetUtc;

  const SunTimesSnapshot({required this.sunriseUtc, required this.sunsetUtc});
}

@immutable
class EnvSnapshot {
  /// US AQI scale (0-500). Null when unavailable.
  final int? usAqi;

  /// A simple 0-5 pollen index derived from provider grains/m³.
  ///
  /// This is a lightweight UX affordance, not a medical claim.
  final double? pollenIndex;

  const EnvSnapshot({required this.usAqi, required this.pollenIndex});
}

/// Small live-data controller for the dashboard hero.
///
/// This slice wires refresh behavior and stabilizes UI state. Real network
/// implementations can replace the internal generators later.
class DashboardLiveDataController extends ChangeNotifier {
  bool _isDisposed = false;

  void _notify() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  final Map<String, WeatherSnapshot> _weatherByPlaceId = {};
  final Map<String, SunTimesSnapshot> _sunByPlaceId = {};
  final Map<String, EnvSnapshot> _envByPlaceId = {};
  WeatherDebugOverride? _debugWeatherOverride;
  Duration? _debugClockOffset;

  double? _debugEurToUsd;

  double _eurToUsd = 1.10;
  final Map<String, double> _eurBaseRates = <String, double>{
    'EUR': 1.0,
    'USD': 1.10,
  };
  bool _isRefreshing = false;
  Object? _lastError;
  DateTime? _lastRefreshedAt;

  Timer? _debounce;

  final CityRepository _cityRepository;
  final WeatherApiClient _weatherApi;
  final OpenMeteoClient _openMeteo;
  final OpenMeteoAirQualityClient _openMeteoAirQuality;
  final FrankfurterClient _frankfurter;
  final bool allowLiveRefreshInTestHarness;
  final Duration refreshDebounceDuration;
  final Duration simulatedNetworkLatency;
  final Duration currencyRetryBackoffDuration;

  DashboardLiveDataController({
    CityRepository? cityRepository,
    WeatherApiClient? weatherApiClient,
    OpenMeteoClient? openMeteoClient,
    OpenMeteoAirQualityClient? openMeteoAirQualityClient,
    FrankfurterClient? frankfurterClient,
    this.allowLiveRefreshInTestHarness = false,
    this.refreshDebounceDuration = const Duration(milliseconds: 250),
    this.simulatedNetworkLatency = const Duration(milliseconds: 350),
    this.currencyRetryBackoffDuration = const Duration(minutes: 2),
  }) : _cityRepository = cityRepository ?? CityRepository.instance,
       _weatherApi = weatherApiClient ?? WeatherApiClient.fromEnvironment(),
       _openMeteo = openMeteoClient ?? OpenMeteoClient(),
       _openMeteoAirQuality =
           openMeteoAirQualityClient ?? OpenMeteoAirQualityClient(),
       _frankfurter = frankfurterClient ?? FrankfurterClient();

  bool get isRefreshing => _isRefreshing;
  Object? get lastError => _lastError;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;

  /// Test hook for deterministic stale/fresh rendering contracts.
  ///
  /// Production code should not call this.
  @visibleForTesting
  void debugSetLastRefreshedAt(DateTime? value) {
    _lastRefreshedAt = value;
    _notify();
  }

  /// True when the live data age exceeds the dashboard's default stale threshold.
  ///
  /// Used by compact UI elements that want to adjust styling without
  /// re-implementing the age math. Threshold matches DataRefreshStatusLabel's default.
  bool get isStale {
    final last = _lastRefreshedAt;
    if (last == null) return true;
    return DateTime.now().difference(last) > const Duration(minutes: 10);
  }

  double get eurToUsd => _debugEurToUsd ?? _eurToUsd;

  /// Returns the conversion rate for [fromCode] -> [toCode].
  ///
  /// Contract:
  /// - Always returns 1.0 for same-currency conversions.
  /// - Uses live EUR-base rates when available.
  /// - Falls back to deterministic mock rates so currency UI never blanks.
  double? currencyRate({required String fromCode, required String toCode}) {
    final from = fromCode.trim().toUpperCase();
    final to = toCode.trim().toUpperCase();
    if (from.isEmpty || to.isEmpty) return null;
    if (from == to) return 1.0;

    final rates = _effectiveEurBaseRates();
    final fromRate = rates[from] ?? _mockEurRateForCode(from);
    final toRate = rates[to] ?? _mockEurRateForCode(to);
    if (fromRate <= 0 || toRate <= 0) return null;
    return toRate / fromRate;
  }

  /// Effective UTC "now" used by the dashboard.
  ///
  /// Contract: the device clock remains the source of truth. The optional
  /// debug offset is only applied when developer tools enable it.
  DateTime get nowUtc {
    final utc = DateTime.now().toUtc();
    final offset = _debugClockOffset;
    if (offset == null) return utc;
    return utc.add(offset);
  }

  /// Weather backend selection.
  ///
  /// Contract: network weather is OFF by default so tests and demo builds stay hermetic.
  ///
  /// Historically this was compile-time only (dart-define). We still honor that as a
  /// default, but Developer Tools can now toggle live weather at runtime (persisted).
  ///
  /// Compile-time defaults (optional):
  /// - --dart-define=WEATHER_NETWORK_ENABLED=true
  /// - --dart-define=WEATHER_PROVIDER=openmeteo|weatherapi
  ///
  /// Compile-time hard-disable (optional):
  /// - --dart-define=WEATHER_NETWORK_ALLOWED=false
  static const bool _envWeatherNetworkEnabled = bool.fromEnvironment(
    'WEATHER_NETWORK_ENABLED',
    defaultValue: false,
  );
  static const String _envWeatherProvider = String.fromEnvironment(
    'WEATHER_PROVIDER',
    defaultValue: 'mock',
  );
  static const bool _weatherNetworkAllowed = bool.fromEnvironment(
    'WEATHER_NETWORK_ALLOWED',
    defaultValue: true,
  );

  static const String _kDevWeatherBackend = 'dev_weather_backend_v1';
  // Currency backend selection.
  //
  // Contract: currency network is OFF by default so tests and demo builds stay hermetic.
  //
  // Compile-time defaults (optional):
  // - --dart-define=CURRENCY_NETWORK_ENABLED=true
  // - --dart-define=CURRENCY_PROVIDER=frankfurter
  //
  // Compile-time hard-disable (optional):
  // - --dart-define=CURRENCY_NETWORK_ALLOWED=false
  static const bool _envCurrencyNetworkEnabled = bool.fromEnvironment(
    'CURRENCY_NETWORK_ENABLED',
    defaultValue: false,
  );
  static const String _envCurrencyProvider = String.fromEnvironment(
    'CURRENCY_PROVIDER',
    defaultValue: 'mock',
  );
  static const bool _currencyNetworkAllowed = bool.fromEnvironment(
    'CURRENCY_NETWORK_ALLOWED',
    defaultValue: true,
  );

  static const String _kDevCurrencyBackend = 'dev_currency_backend_v1';
  static const String _kCachedEurToUsdRate = 'currency_eur_to_usd_rate_v1';
  static const String _kCachedEurToUsdUpdatedAt =
      'currency_eur_to_usd_updated_at_v1';

  static const Duration _currencyTtl = Duration(hours: 12);
  static WeatherBackend _backendFromEnv() {
    if (!_envWeatherNetworkEnabled) return WeatherBackend.mock;
    switch (_envWeatherProvider.toLowerCase()) {
      case 'openmeteo':
        return WeatherBackend.openMeteo;
      case 'weatherapi':
        return WeatherBackend.weatherApi;
      default:
        return WeatherBackend.mock;
    }
  }

  static String _backendKey(WeatherBackend b) {
    switch (b) {
      case WeatherBackend.openMeteo:
        return 'openmeteo';
      case WeatherBackend.weatherApi:
        return 'weatherapi';
      case WeatherBackend.mock:
        return 'mock';
    }
  }

  static CurrencyBackend _currencyBackendFromEnv() {
    if (!_envCurrencyNetworkEnabled) return CurrencyBackend.mock;
    switch (_envCurrencyProvider.toLowerCase()) {
      case 'frankfurter':
        return CurrencyBackend.frankfurter;
      default:
        return CurrencyBackend.mock;
    }
  }

  static String _currencyBackendKey(CurrencyBackend b) {
    switch (b) {
      case CurrencyBackend.frankfurter:
        return 'frankfurter';
      case CurrencyBackend.mock:
        return 'mock';
    }
  }

  WeatherBackend _weatherBackend = _backendFromEnv();
  CurrencyBackend _currencyBackend = _currencyBackendFromEnv();
  DateTime? _lastCurrencyRefreshedAt;
  DateTime? _lastCurrencyErrorAt;
  Object? _lastCurrencyError;
  bool _devSettingsLoaded = false;
  WeatherBackend get weatherBackend => _weatherBackend;

  CurrencyBackend get currencyBackend => _currencyBackend;

  /// Whether live network currency is enabled (and allowed) for this build.
  bool get currencyNetworkEnabled =>
      _currencyNetworkAllowed && _currencyBackend != CurrencyBackend.mock;

  bool get currencyNetworkAllowed => _currencyNetworkAllowed;

  DateTime? get lastCurrencyRefreshedAt => _lastCurrencyRefreshedAt;
  DateTime? get lastCurrencyErrorAt => _lastCurrencyErrorAt;
  Object? get lastCurrencyError => _lastCurrencyError;

  bool get isCurrencyStale {
    final last = _lastCurrencyRefreshedAt;
    if (last == null) return true;
    return DateTime.now().difference(last) > _currencyTtl;
  }

  bool get shouldRetryCurrencyNow {
    if (!currencyNetworkEnabled) return false;
    final errAt = _lastCurrencyErrorAt;
    if (errAt == null) return isCurrencyStale;
    return DateTime.now().difference(errAt) >= currencyRetryBackoffDuration;
  }

  /// Whether live network weather is enabled (and allowed) for this build.
  bool get weatherNetworkEnabled =>
      _weatherNetworkAllowed && _weatherBackend != WeatherBackend.mock;

  bool get weatherNetworkAllowed => _weatherNetworkAllowed;

  bool get canUseWeatherApi => _weatherApi.isConfigured;

  bool get _useWeatherApi =>
      weatherNetworkEnabled &&
      _weatherBackend == WeatherBackend.weatherApi &&
      _weatherApi.isConfigured;

  bool get _useOpenMeteo =>
      weatherNetworkEnabled && _weatherBackend == WeatherBackend.openMeteo;
  Future<void> loadDevSettings() async {
    if (_devSettingsLoaded) return;
    _devSettingsLoaded = true;

    final prefs = await SharedPreferences.getInstance();

    final weatherRaw = prefs.getString(_kDevWeatherBackend);
    if (weatherRaw != null && weatherRaw.trim().isNotEmpty) {
      final norm = weatherRaw.trim().toLowerCase();
      final WeatherBackend next;
      if (norm == 'openmeteo' ||
          norm == 'open_meteo' ||
          norm == 'open-meteo' ||
          norm == 'openmeto') {
        next = WeatherBackend.openMeteo;
      } else if (norm == 'weatherapi' ||
          norm == 'weather_api' ||
          norm == 'weather-api') {
        next = WeatherBackend.weatherApi;
      } else {
        next = WeatherBackend.mock;
      }

      // If the dev setting asks for WeatherAPI but the build isn't configured,
      // silently fall back to Open-Meteo (or mock if network is disallowed).
      if (next == WeatherBackend.weatherApi && !_weatherApi.isConfigured) {
        _weatherBackend = WeatherBackend.openMeteo;
      } else {
        _weatherBackend = next;
      }
    }

    final currencyRaw = prefs.getString(_kDevCurrencyBackend);
    if (currencyRaw != null && currencyRaw.trim().isNotEmpty) {
      final norm = currencyRaw.trim().toLowerCase();
      final CurrencyBackend next;
      if (norm == 'frankfurter') {
        next = CurrencyBackend.frankfurter;
      } else {
        next = CurrencyBackend.mock;
      }

      if (!_currencyNetworkAllowed && next != CurrencyBackend.mock) {
        _currencyBackend = CurrencyBackend.mock;
      } else {
        _currencyBackend = next;
      }
    }

    final cachedRate = prefs.getDouble(_kCachedEurToUsdRate);
    if (cachedRate != null && cachedRate > 0) {
      _eurToUsd = cachedRate;
      _eurBaseRates['USD'] = cachedRate;
    }
    final cachedAt = prefs.getInt(_kCachedEurToUsdUpdatedAt);
    if (cachedAt != null && cachedAt > 0) {
      _lastCurrencyRefreshedAt = DateTime.fromMillisecondsSinceEpoch(cachedAt);
    }
    _notify();
  }

  Future<void> setWeatherBackend(WeatherBackend backend) async {
    if (!_weatherNetworkAllowed && backend != WeatherBackend.mock) {
      _lastError = StateError('Network weather is disallowed for this build');
      _notify();
      return;
    }

    if (backend == WeatherBackend.weatherApi && !_weatherApi.isConfigured) {
      _lastError = StateError(
        'WeatherAPI is not configured (missing WEATHERAPI_KEY)',
      );
      _notify();
      return;
    }

    if (_weatherBackend == backend) return;
    _weatherBackend = backend;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDevWeatherBackend, _backendKey(backend));

    _notify();
  }

  Future<void> setCurrencyBackend(CurrencyBackend backend) async {
    if (!_currencyNetworkAllowed && backend != CurrencyBackend.mock) {
      _lastError = StateError('Network currency is disallowed for this build');
      _notify();
      return;
    }

    if (_currencyBackend == backend) return;
    _currencyBackend = backend;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDevCurrencyBackend, _currencyBackendKey(backend));

    _notify();
  }

  /// Developer-only override for the EUR→USD rate used by the hero currency line.
  ///
  /// When null, the hero follows live/demo rates.
  double? get debugEurToUsdOverride => _debugEurToUsd;

  void setDebugEurToUsdOverride(double? value) {
    final prev = _debugEurToUsd;
    if (prev == null && value == null) return;
    if (prev != null && value != null && (prev - value).abs() < 0.0001) return;

    _debugEurToUsd = value;
    _notify();
  }

  /// Developer-only override for weather condition visuals.
  ///
  /// When set, the dashboard will continue to use live temperature/wind values,
  /// but will display the selected condition for hero scenes and any condition-
  /// driven UI.
  WeatherDebugOverride? get debugWeatherOverride => _debugWeatherOverride;

  /// Developer-only clock override.
  ///
  /// Contract: the device clock remains the source of truth.
  ///
  /// When non-null, dashboard time-of-day logic uses `DateTime.now().toUtc()`
  /// plus this offset. This is intentionally a lightweight offset for simulator
  /// testing and screenshots. It is not NTP, not a backend sync, and not a
  /// timezone reconfiguration.
  Duration? get debugClockOffset => _debugClockOffset;

  void setDebugClockOffset(Duration? value) {
    final prev = _debugClockOffset;
    if (prev == null && value == null) return;
    if (prev != null && value != null && prev == value) return;
    _debugClockOffset = value;
    _notify();
  }

  /// Set/clear the weather override used for hero scene debugging.
  void setDebugWeatherOverride(WeatherDebugOverride? value) {
    final next = value;

    final prev = _debugWeatherOverride;
    if (prev == null && next == null) return;
    if (prev is WeatherDebugOverrideCoarse &&
        next is WeatherDebugOverrideCoarse &&
        prev.condition == next.condition &&
        prev.isNightOverride == next.isNightOverride) {
      return;
    }

    _debugWeatherOverride = next;
    _notify();
  }

  /// Set the WeatherAPI debug override.
  ///
  /// This bypasses provider mapping and is highest precedence for scene choice.
  void setDebugWeatherApiOverride({
    required int code,
    required bool isNight,
    required String text,
  }) {
    final next = WeatherDebugOverrideWeatherApi(
      code: code,
      isNight: isNight,
      text: text,
    );

    final prev = _debugWeatherOverride;
    if (prev is WeatherDebugOverrideWeatherApi &&
        prev.code == code &&
        prev.isNight == isNight &&
        prev.text == text) {
      return;
    }

    _debugWeatherOverride = next;
    _notify();
  }

  WeatherSnapshot? weatherFor(Place? place) {
    if (place == null) {
      return null;
    }

    final snap = _weatherByPlaceId[place.id];
    if (snap == null) {
      return null;
    }

    final override = _debugWeatherOverride;
    if (override == null) {
      return snap;
    }

    if (override is WeatherDebugOverrideCoarse) {
      return WeatherSnapshot(
        temperatureC: snap.temperatureC,
        windKmh: snap.windKmh,
        gustKmh: snap.gustKmh,
        sceneKey: WeatherConditionSceneKeyMapper.fromWeatherCondition(
          override.condition,
        ),
        conditionText: _coarseLabelFor(override.condition),
        conditionCode: snap.conditionCode,
      );
    }

    final api = override as WeatherDebugOverrideWeatherApi;
    return WeatherSnapshot(
      temperatureC: snap.temperatureC,
      windKmh: snap.windKmh,
      gustKmh: snap.gustKmh,
      sceneKey: WeatherApiSceneKeyMapper.fromWeatherApi(
        code: api.code,
        text: api.text,
      ),
      conditionText: api.text,
      conditionCode: api.code,
    );
  }

  static String _coarseLabelFor(WeatherCondition c) {
    switch (c) {
      case WeatherCondition.clear:
        return 'Clear';
      case WeatherCondition.partlyCloudy:
        return 'Partly cloudy';
      case WeatherCondition.cloudy:
        return 'Cloudy';
      case WeatherCondition.overcast:
        return 'Overcast';
      case WeatherCondition.drizzle:
        return 'Drizzle';
      case WeatherCondition.rain:
        return 'Rain';
      case WeatherCondition.thunderstorm:
        return 'Thunderstorm';
      case WeatherCondition.snow:
        return 'Snow';
      case WeatherCondition.sleet:
        return 'Sleet';
      case WeatherCondition.hail:
        return 'Hail';
      case WeatherCondition.fog:
        return 'Fog';
      case WeatherCondition.mist:
        return 'Mist';
      case WeatherCondition.haze:
        return 'Haze';
      case WeatherCondition.smoke:
        return 'Smoke';
      case WeatherCondition.dust:
        return 'Dust';
      case WeatherCondition.sand:
        return 'Sand';
      case WeatherCondition.ash:
        return 'Ash';
      case WeatherCondition.squall:
        return 'Squall';
      case WeatherCondition.tornado:
        return 'Tornado';
      case WeatherCondition.windy:
        return 'Windy';
    }
  }

  SunTimesSnapshot? sunFor(Place? place) {
    if (place == null) {
      return null;
    }
    return _sunByPlaceId[place.id];
  }

  EnvSnapshot? envFor(Place? place) {
    if (place == null) {
      return null;
    }
    return _envByPlaceId[place.id];
  }

  void ensureSeeded(List<Place> places) {
    var changed = false;
    final nowUtc = this.nowUtc;

    for (final p in places) {
      if (!_weatherByPlaceId.containsKey(p.id)) {
        _weatherByPlaceId[p.id] = _seedWeather(p);
        changed = true;
      }
      if (!_sunByPlaceId.containsKey(p.id)) {
        _sunByPlaceId[p.id] = _seedSunTimes(p, nowUtc);
        changed = true;
      }
      if (!_envByPlaceId.containsKey(p.id)) {
        _envByPlaceId[p.id] = _seedEnv(p);
        changed = true;
      }
    }

    if (changed) {
      // Important: seeding is demo-only. Do not claim "last refreshed" for
      // network-backed weather, otherwise freshness/TTL logic will incorrectly
      // treat seeded demo values as live data.
      if (!weatherNetworkEnabled) {
        _lastRefreshedAt ??= DateTime.now();
      }
      // Avoid notifying during widget build; schedule after this frame.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _notify();
      });
    }
  }

  bool _isTestHarness() {
    // Avoid importing flutter_test into production code. This runtime check is
    // sufficient to prevent widget-test flakiness caused by scheduled timers
    // and fake network latency.
    final name = SchedulerBinding.instance.runtimeType.toString();
    return name.contains('TestWidgetsFlutterBinding') ||
        name.contains('AutomatedTestWidgetsFlutterBinding');
  }

  Future<void> refreshAll({required List<Place> places}) async {
    // Widget tests frequently enable a dev weather backend to validate UI
    // layout and overflow contracts. Do not schedule debounce timers or
    // simulate network latency in that environment, otherwise tests end with
    // pending timers and spurious failures.
    if (_isTestHarness() && !allowLiveRefreshInTestHarness) {
      _debounce?.cancel();
      _isRefreshing = true;
      _lastError = null;
      _notify();

      // Treat this as an immediate "refresh" for UI purposes.
      _lastRefreshedAt = DateTime.now();
      _isRefreshing = false;
      _notify();
      return;
    }
    // Debounce repeated taps so we don't overlap refresh flows.
    _debounce?.cancel();
    final completer = Completer<void>();
    _debounce = Timer(refreshDebounceDuration, () async {
      try {
        _isRefreshing = true;
        _lastError = null;
        _notify();

        // Simulate a short network latency.
        await Future<void>.delayed(simulatedNetworkLatency);
        if (_useWeatherApi || _useOpenMeteo) {
          // Load city metadata (lat/lon) once for best-effort query precision.
          await _cityRepository.load();

          for (final p in places) {
            try {
              final city = _cityRepository.byPlace(
                p.cityName,
                countryCode: p.countryCode,
              );

              final lat = city?.lat;
              final lon = city?.lon;
              final query = (lat != null && lon != null)
                  ? '$lat,$lon'
                  : '${p.cityName},${p.countryCode}';

              final override = _debugWeatherOverride;

              if (_useWeatherApi) {
                final api = await _weatherApi.fetchTodayForecast(query: query);

                final SceneKey sceneKey;
                final String conditionText;
                final int conditionCode;

                if (override == null) {
                  sceneKey = WeatherApiSceneKeyMapper.fromWeatherApi(
                    code: api.conditionCode,
                    text: api.conditionText,
                  );
                  conditionText = api.conditionText;
                  conditionCode = api.conditionCode;
                } else if (override is WeatherDebugOverrideCoarse) {
                  sceneKey =
                      WeatherConditionSceneKeyMapper.fromWeatherCondition(
                        override.condition,
                      );
                  conditionText = _coarseLabelFor(override.condition);
                  conditionCode = api.conditionCode;
                } else {
                  final w = override as WeatherDebugOverrideWeatherApi;
                  sceneKey = WeatherApiSceneKeyMapper.fromWeatherApi(
                    code: w.code,
                    text: w.text,
                  );
                  conditionText = w.text;
                  conditionCode = w.code;
                }

                _weatherByPlaceId[p.id] = WeatherSnapshot(
                  temperatureC: api.temperatureC,
                  windKmh: api.windKmh,
                  gustKmh: api.gustKmh,
                  sceneKey: sceneKey,
                  conditionText: conditionText,
                  conditionCode: conditionCode,
                );

                _sunByPlaceId[p.id] = SunTimesSnapshot(
                  sunriseUtc: api.sunriseUtc,
                  sunsetUtc: api.sunsetUtc,
                );

                await _maybeRefreshEnvForPlace(
                  place: p,
                  latitude: lat,
                  longitude: lon,
                );
                _envByPlaceId.putIfAbsent(p.id, () => _seedEnv(p));
              } else {
                if (lat == null || lon == null) {
                  // Without coordinates, Open-Meteo cannot be queried.
                  // Keep prior snapshots when present, or seed deterministic
                  // fallbacks so critical hero states never go blank.
                  _ensureFallbackSnapshotsForPlace(
                    p,
                    nowUtc: DateTime.now().toUtc(),
                  );
                  continue;
                }

                final om = await _openMeteo.fetchTodayForecast(
                  latitude: lat,
                  longitude: lon,
                );

                final effectiveOverride = override is WeatherDebugOverrideCoarse
                    ? override
                    : null;

                final SceneKey sceneKey;
                final String conditionText;
                final int conditionCode = om.weatherCode;

                if (effectiveOverride == null) {
                  sceneKey = OpenMeteoSceneKeyMapper.fromWmoCode(
                    om.weatherCode,
                  );
                  conditionText = OpenMeteoSceneKeyMapper.labelFor(
                    om.weatherCode,
                  );
                } else {
                  sceneKey =
                      WeatherConditionSceneKeyMapper.fromWeatherCondition(
                        effectiveOverride.condition,
                      );
                  conditionText = _coarseLabelFor(effectiveOverride.condition);
                }

                _weatherByPlaceId[p.id] = WeatherSnapshot(
                  temperatureC: om.temperatureC,
                  windKmh: om.windKmh,
                  gustKmh: om.gustKmh,
                  sceneKey: sceneKey,
                  conditionText: conditionText,
                  conditionCode: conditionCode,
                );

                _sunByPlaceId[p.id] = SunTimesSnapshot(
                  sunriseUtc: om.sunriseUtc,
                  sunsetUtc: om.sunsetUtc,
                );

                await _maybeRefreshEnvForPlace(
                  place: p,
                  latitude: lat,
                  longitude: lon,
                );
                _envByPlaceId.putIfAbsent(p.id, () => _seedEnv(p));
              }
            } catch (_) {
              // Keep last stable values when present; otherwise seed
              // deterministic fallbacks so no critical pill goes blank.
              _ensureFallbackSnapshotsForPlace(
                p,
                nowUtc: DateTime.now().toUtc(),
              );
            }
          }
        } else {
          // Mock mode (no API key): deterministic drift for demo + tests.
          final nowUtc = DateTime.now().toUtc();
          for (final p in places) {
            _weatherByPlaceId[p.id] = _refreshWeather(p);
            // In mock mode we still populate Env + SunTimes so the hero never
            // shows placeholders for AQI/Pollen or Sunrise/Sunset.
            _envByPlaceId[p.id] = _seedEnv(p);
            _sunByPlaceId[p.id] = _seedSunTimes(p, nowUtc);
          }
        }
        await _maybeRefreshCurrency();

        _lastRefreshedAt = DateTime.now();

        if (!currencyNetworkEnabled) {
          _eurToUsd = 1.10;
          _eurBaseRates['USD'] = _eurToUsd;
        }
      } catch (e) {
        _lastError = e;
      } finally {
        _isRefreshing = false;
        _notify();
        completer.complete();
      }
    });
    return completer.future;
  }

  void _ensureFallbackSnapshotsForPlace(Place p, {required DateTime nowUtc}) {
    _weatherByPlaceId.putIfAbsent(p.id, () => _seedWeather(p));
    _sunByPlaceId.putIfAbsent(p.id, () => _seedSunTimes(p, nowUtc));
    _envByPlaceId.putIfAbsent(p.id, () => _seedEnv(p));
  }

  static double _pollenIndexFromGrains(double grains) {
    // Heuristic bucketing to produce a small 0-5 value that fits in a pill.
    // This is a lightweight UX affordance, not a medical claim.
    if (grains <= 10) return 0.0;
    if (grains <= 50) return 1.0;
    if (grains <= 200) return 2.0;
    if (grains <= 500) return 3.0;
    if (grains <= 1000) return 4.0;
    return 5.0;
  }

  Future<void> _maybeRefreshEnvForPlace({
    required Place place,
    required double? latitude,
    required double? longitude,
  }) async {
    if (!weatherNetworkEnabled) return;
    if (latitude == null || longitude == null) return;
    try {
      final current = await _openMeteoAirQuality.fetchCurrent(
        latitude: latitude,
        longitude: longitude,
      );
      final prev = _envByPlaceId[place.id];
      final seeded = _seedEnv(place);
      final pollenGrains = current.maxPollenGrains();
      final pollenIndex = pollenGrains == null
          ? (prev?.pollenIndex ?? seeded.pollenIndex)
          : _pollenIndexFromGrains(pollenGrains);

      _envByPlaceId[place.id] = EnvSnapshot(
        usAqi: current.usAqi ?? prev?.usAqi ?? seeded.usAqi,
        pollenIndex: pollenIndex,
      );
    } catch (_) {
      // Best-effort only. Keep the last stable values, or seed if missing.
      _envByPlaceId.putIfAbsent(place.id, () => _seedEnv(place));
    }
  }

  Future<void> _maybeRefreshCurrency() async {
    if (!currencyNetworkEnabled) return;

    final now = DateTime.now();
    final stale = isCurrencyStale;
    if (!stale) return;

    final errAt = _lastCurrencyErrorAt;
    if (errAt != null && now.difference(errAt) < currencyRetryBackoffDuration) {
      return;
    }

    try {
      double? rate;
      switch (_currencyBackend) {
        case CurrencyBackend.frankfurter:
          final fetched = await _frankfurter.fetchLatestRates(base: 'EUR');
          if (fetched != null && fetched.isNotEmpty) {
            _eurBaseRates
              ..clear()
              ..addAll(fetched);
            rate = fetched['USD'];
          } else {
            rate = await _frankfurter.fetchEurToUsd();
          }
          break;
        case CurrencyBackend.mock:
          rate = null;
          break;
      }

      if (rate == null || rate <= 0) return;

      _eurToUsd = rate;
      _eurBaseRates['USD'] = rate;
      _lastCurrencyRefreshedAt = now;
      _lastCurrencyError = null;
      _lastCurrencyErrorAt = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kCachedEurToUsdRate, rate);
      await prefs.setInt(_kCachedEurToUsdUpdatedAt, now.millisecondsSinceEpoch);
    } catch (e) {
      // Best-effort only. Keep the last stable value.
      _lastCurrencyError = e;
      _lastCurrencyErrorAt = now;
    }
  }

  Map<String, double> _effectiveEurBaseRates() {
    final rates = <String, double>{..._eurBaseRates};
    final debugRate = _debugEurToUsd;
    if (debugRate != null && debugRate > 0) {
      rates['USD'] = debugRate;
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
        // Deterministic fallback for less-common currencies.
        final hash = code.codeUnits.fold<int>(
          0,
          (sum, u) => ((sum * 131) + u) & 0x7fffffff,
        );
        final scaled = 0.35 + ((hash % 9650) / 1000.0); // 0.35..9.999
        return scaled;
    }
  }

  WeatherSnapshot _seedWeather(Place p) {
    // Canonical demo values that match the design mock.
    if (p.cityName.toLowerCase() == 'lisbon') {
      return const WeatherSnapshot(
        temperatureC: 20.0,
        windKmh: 7.0,
        gustKmh: 11.0,
        sceneKey: SceneKey.partlyCloudy,
        conditionText: 'Partly cloudy',
      );
    }
    if (p.cityName.toLowerCase() == 'denver') {
      return const WeatherSnapshot(
        temperatureC: 3.0,
        windKmh: 22.0,
        gustKmh: 34.0,
        sceneKey: SceneKey.clear,
        conditionText: 'Clear',
      );
    }

    // Otherwise, produce a stable deterministic snapshot.
    final seed = p.id.hashCode ^ p.cityName.hashCode;
    final temp = 12.0 + ((seed % 180) / 10.0);
    final wind = 4.0 + ((seed % 70) / 10.0);
    return WeatherSnapshot(
      temperatureC: temp,
      windKmh: wind,
      gustKmh: wind + 4.0,
      sceneKey: SceneKey.partlyCloudy,
      conditionText: 'Partly cloudy',
    );
  }

  EnvSnapshot _seedEnv(Place p) {
    final city = p.cityName.toLowerCase();
    // Canonical demo values that match the intended UI examples.
    if (city == 'lisbon') {
      return const EnvSnapshot(usAqi: 42, pollenIndex: 3.2);
    }
    if (city == 'denver') {
      return const EnvSnapshot(usAqi: 55, pollenIndex: 1.1);
    }

    final seed = p.id.hashCode ^ (p.cityName.hashCode << 2);
    final aqi = 18 + (seed.abs() % 105); // 18..122
    final pollen = ((seed.abs() % 51) / 10.0); // 0.0..5.0
    return EnvSnapshot(usAqi: aqi, pollenIndex: pollen);
  }

  SunTimesSnapshot _seedSunTimes(Place p, DateTime nowUtc) {
    // Anchor to the current *local* date for each place so sunrise/sunset display
    // correctly when switching realities (timezone affects UTC).
    //
    // Important: we treat these values as *wall-clock* times for the place,
    // not device-local times. We use DateTime.utc constructors to avoid the
    // host device timezone leaking into demo data.
    final localNow = TimezoneUtils.nowInZone(
      p.timeZoneId,
      nowUtc: nowUtc,
    ).local;
    final localDay = DateTime.utc(localNow.year, localNow.month, localNow.day);

    DateTime toUtc(DateTime localWallClock) =>
        TimezoneUtils.localToUtc(p.timeZoneId, localWallClock);

    DateTime wall(int h, int m) =>
        DateTime.utc(localDay.year, localDay.month, localDay.day, h, m);

    // Canonical demo values that match the design mock (local clock time).
    final city = p.cityName.toLowerCase();
    if (city == 'lisbon') {
      return SunTimesSnapshot(
        sunriseUtc: toUtc(wall(7, 52)),
        sunsetUtc: toUtc(wall(17, 29)),
      );
    }
    if (city == 'denver') {
      return SunTimesSnapshot(
        sunriseUtc: toUtc(wall(7, 5)),
        sunsetUtc: toUtc(wall(17, 5)),
      );
    }

    // Deterministic but plausible window for other places (local clock time).
    final seed = p.id.hashCode ^ (p.cityName.hashCode << 1);
    final sunriseMinutes = 360 + (seed.abs() % 150); // 06:00 to 08:29
    final sunsetMinutes = 990 + (seed.abs() % 120); // 16:30 to 18:29

    final sunriseLocal = localDay.add(Duration(minutes: sunriseMinutes));
    final sunsetLocal = localDay.add(Duration(minutes: sunsetMinutes));

    return SunTimesSnapshot(
      sunriseUtc: toUtc(sunriseLocal),
      sunsetUtc: toUtc(sunsetLocal),
    );
  }

  WeatherSnapshot _refreshWeather(Place p) {
    final current = _weatherByPlaceId[p.id] ?? _seedWeather(p);
    // Make per-place motion deterministic so toggling cities never looks
    // “stuck” (avoid identical rounded values across places).
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final phase = (p.id.hashCode ^ (p.cityName.hashCode << 1)) % 900000;
    final drift = math.sin((nowMs + phase) / 60000) * 0.8;
    return WeatherSnapshot(
      temperatureC: (current.temperatureC + drift).clamp(-30.0, 45.0),
      windKmh: current.windKmh,
      gustKmh: current.gustKmh,
      sceneKey: current.sceneKey,
      conditionText: current.conditionText,
      conditionCode: current.conditionCode,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
