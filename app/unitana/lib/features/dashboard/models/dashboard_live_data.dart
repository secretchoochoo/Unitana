import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:flutter/scheduler.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/build_flags.dart';
import '../../../data/city_repository.dart';
import '../../../data/weather_api_client.dart';
import '../../../data/open_meteo_client.dart';
import '../../../data/open_meteo_air_quality_client.dart';
import '../../../data/met_norway_client.dart';
import '../../../data/frankfurter_client.dart';
import '../../../data/open_er_api_client.dart';
import '../../../models/place.dart';
import '../../../utils/timezone_utils.dart';

part 'dashboard_currency_domain.dart';
part 'dashboard_env_domain.dart';
part 'dashboard_weather_confidence.dart';
part 'dashboard_weather_domain.dart';

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

/// Deterministic emergency severity used by hero + weather surfaces.
///
/// Order matters: higher index = higher urgency.
enum WeatherEmergencySeverity { none, advisory, watch, warning, emergency }

@immutable
class WeatherEmergencyAssessment {
  final WeatherEmergencySeverity severity;

  /// Stable machine key for diagnostics/tests and localized copy lookup.
  final String reasonKey;

  /// Stable source domain for explainability ("scene", "wind", "air", etc).
  final String source;

  const WeatherEmergencyAssessment({
    required this.severity,
    required this.reasonKey,
    required this.source,
  });

  bool get isActive => severity != WeatherEmergencySeverity.none;
}

/// Classifies emergency weather from available signals.
///
/// Precedence contract:
/// 1) Severe explicit weather scenes (tornado/squall/blizzard/etc.)
/// 2) Wind/gust thresholds
/// 3) Air quality/pollen stress
/// 4) Condition-text metadata hints ("warning", "watch", "advisory")
///
/// Missing metadata is safe: if no signal is present, severity is `none`.
class WeatherEmergencyTaxonomy {
  const WeatherEmergencyTaxonomy._();

  static const WeatherEmergencyAssessment _none = WeatherEmergencyAssessment(
    severity: WeatherEmergencySeverity.none,
    reasonKey: 'none',
    source: 'fallback',
  );

  static WeatherEmergencyAssessment assess({
    required WeatherSnapshot? weather,
    required EnvSnapshot? env,
  }) {
    final candidates = <WeatherEmergencyAssessment>[];

    if (weather != null) {
      _appendSceneCandidates(candidates, weather.sceneKey);
      _appendWindCandidates(candidates, weather.windKmh, weather.gustKmh);
      _appendConditionTextCandidates(candidates, weather.conditionText);
    }

    _appendAirCandidates(candidates, env);

    if (candidates.isEmpty) return _none;
    candidates.sort(_compareAssessment);
    return candidates.first;
  }

  static int _severityRank(WeatherEmergencySeverity s) {
    switch (s) {
      case WeatherEmergencySeverity.emergency:
        return 5;
      case WeatherEmergencySeverity.warning:
        return 4;
      case WeatherEmergencySeverity.watch:
        return 3;
      case WeatherEmergencySeverity.advisory:
        return 2;
      case WeatherEmergencySeverity.none:
        return 1;
    }
  }

  // Lower number = higher deterministic precedence for ties.
  static int _reasonPriority(String key) {
    switch (key) {
      case 'tornado':
        return 0;
      case 'thunder_snow':
        return 1;
      case 'thunderstorm':
        return 2;
      case 'blizzard':
        return 3;
      case 'squall':
        return 4;
      case 'ice':
        return 5;
      case 'high_wind':
        return 6;
      case 'wildfire_smoke':
        return 7;
      case 'ashfall':
        return 8;
      case 'air_hazardous':
        return 9;
      case 'air_unhealthy':
        return 10;
      case 'air_sensitive':
        return 11;
      case 'pollen_very_high':
        return 12;
      case 'provider_warning':
        return 13;
      case 'provider_watch':
        return 14;
      case 'provider_advisory':
        return 15;
      default:
        return 999;
    }
  }

  static int _compareAssessment(
    WeatherEmergencyAssessment a,
    WeatherEmergencyAssessment b,
  ) {
    final severity = _severityRank(
      b.severity,
    ).compareTo(_severityRank(a.severity));
    if (severity != 0) return severity;
    final reason = _reasonPriority(
      a.reasonKey,
    ).compareTo(_reasonPriority(b.reasonKey));
    if (reason != 0) return reason;
    return a.source.compareTo(b.source);
  }

  static void _appendSceneCandidates(
    List<WeatherEmergencyAssessment> out,
    SceneKey scene,
  ) {
    switch (scene) {
      case SceneKey.tornado:
        out.add(
          const WeatherEmergencyAssessment(
            severity: WeatherEmergencySeverity.emergency,
            reasonKey: 'tornado',
            source: 'scene',
          ),
        );
        return;
      case SceneKey.thunderSnow:
        out.add(
          const WeatherEmergencyAssessment(
            severity: WeatherEmergencySeverity.warning,
            reasonKey: 'thunder_snow',
            source: 'scene',
          ),
        );
        return;
      case SceneKey.thunderRain:
        out.add(
          const WeatherEmergencyAssessment(
            severity: WeatherEmergencySeverity.warning,
            reasonKey: 'thunderstorm',
            source: 'scene',
          ),
        );
        return;
      case SceneKey.blizzard:
        out.add(
          const WeatherEmergencyAssessment(
            severity: WeatherEmergencySeverity.warning,
            reasonKey: 'blizzard',
            source: 'scene',
          ),
        );
        return;
      case SceneKey.squall:
        out.add(
          const WeatherEmergencyAssessment(
            severity: WeatherEmergencySeverity.warning,
            reasonKey: 'squall',
            source: 'scene',
          ),
        );
        return;
      case SceneKey.icePellets:
      case SceneKey.freezingRain:
      case SceneKey.freezingDrizzle:
        out.add(
          const WeatherEmergencyAssessment(
            severity: WeatherEmergencySeverity.watch,
            reasonKey: 'ice',
            source: 'scene',
          ),
        );
        return;
      case SceneKey.smokeWildfire:
        out.add(
          const WeatherEmergencyAssessment(
            severity: WeatherEmergencySeverity.watch,
            reasonKey: 'wildfire_smoke',
            source: 'scene',
          ),
        );
        return;
      case SceneKey.ashfall:
        out.add(
          const WeatherEmergencyAssessment(
            severity: WeatherEmergencySeverity.watch,
            reasonKey: 'ashfall',
            source: 'scene',
          ),
        );
        return;
      case SceneKey.rainHeavy:
      case SceneKey.snowHeavy:
      case SceneKey.blowingSnow:
        out.add(
          const WeatherEmergencyAssessment(
            severity: WeatherEmergencySeverity.advisory,
            reasonKey: 'provider_advisory',
            source: 'scene',
          ),
        );
        return;
      case SceneKey.clear:
      case SceneKey.partlyCloudy:
      case SceneKey.cloudy:
      case SceneKey.overcast:
      case SceneKey.mist:
      case SceneKey.fog:
      case SceneKey.drizzle:
      case SceneKey.rainLight:
      case SceneKey.rainModerate:
      case SceneKey.sleet:
      case SceneKey.snowLight:
      case SceneKey.snowModerate:
      case SceneKey.hazeDust:
      case SceneKey.windy:
        return;
    }
  }

  static void _appendWindCandidates(
    List<WeatherEmergencyAssessment> out,
    double windKmh,
    double gustKmh,
  ) {
    final peak = math.max(windKmh, gustKmh);
    if (peak >= 100) {
      out.add(
        const WeatherEmergencyAssessment(
          severity: WeatherEmergencySeverity.warning,
          reasonKey: 'high_wind',
          source: 'wind',
        ),
      );
      return;
    }
    if (peak >= 70) {
      out.add(
        const WeatherEmergencyAssessment(
          severity: WeatherEmergencySeverity.watch,
          reasonKey: 'high_wind',
          source: 'wind',
        ),
      );
      return;
    }
    if (peak >= 45) {
      out.add(
        const WeatherEmergencyAssessment(
          severity: WeatherEmergencySeverity.advisory,
          reasonKey: 'high_wind',
          source: 'wind',
        ),
      );
    }
  }

  static void _appendAirCandidates(
    List<WeatherEmergencyAssessment> out,
    EnvSnapshot? env,
  ) {
    final aqi = env?.usAqi;
    if (aqi != null) {
      if (aqi >= 300) {
        out.add(
          const WeatherEmergencyAssessment(
            severity: WeatherEmergencySeverity.warning,
            reasonKey: 'air_hazardous',
            source: 'air',
          ),
        );
      } else if (aqi >= 200) {
        out.add(
          const WeatherEmergencyAssessment(
            severity: WeatherEmergencySeverity.watch,
            reasonKey: 'air_unhealthy',
            source: 'air',
          ),
        );
      } else if (aqi >= 150) {
        out.add(
          const WeatherEmergencyAssessment(
            severity: WeatherEmergencySeverity.advisory,
            reasonKey: 'air_sensitive',
            source: 'air',
          ),
        );
      }
    }

    final pollen = env?.pollenIndex;
    if (pollen != null && pollen >= 4.0) {
      out.add(
        const WeatherEmergencyAssessment(
          severity: WeatherEmergencySeverity.advisory,
          reasonKey: 'pollen_very_high',
          source: 'air',
        ),
      );
    }
  }

  static void _appendConditionTextCandidates(
    List<WeatherEmergencyAssessment> out,
    String conditionText,
  ) {
    final text = conditionText.toLowerCase();
    if (text.contains('tornado emergency')) {
      out.add(
        const WeatherEmergencyAssessment(
          severity: WeatherEmergencySeverity.emergency,
          reasonKey: 'tornado',
          source: 'provider_text',
        ),
      );
      return;
    }
    if (text.contains('warning')) {
      out.add(
        const WeatherEmergencyAssessment(
          severity: WeatherEmergencySeverity.warning,
          reasonKey: 'provider_warning',
          source: 'provider_text',
        ),
      );
      return;
    }
    if (text.contains('watch')) {
      out.add(
        const WeatherEmergencyAssessment(
          severity: WeatherEmergencySeverity.watch,
          reasonKey: 'provider_watch',
          source: 'provider_text',
        ),
      );
      return;
    }
    if (text.contains('advisory')) {
      out.add(
        const WeatherEmergencyAssessment(
          severity: WeatherEmergencySeverity.advisory,
          reasonKey: 'provider_advisory',
          source: 'provider_text',
        ),
      );
    }
  }
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

class MetNorwaySceneKeyMapper {
  const MetNorwaySceneKeyMapper._();

  static SceneKey fromSymbolCode(String symbolCode) {
    final normalized = symbolCode.trim().toLowerCase();
    if (normalized.contains('thundersnow')) {
      return SceneKey.thunderSnow;
    }
    if (normalized.contains('thunder')) {
      return SceneKey.thunderRain;
    }
    if (normalized.contains('blizzard')) {
      return SceneKey.blizzard;
    }
    if (normalized.contains('fog')) {
      return SceneKey.fog;
    }
    if (normalized.contains('sleet')) {
      return SceneKey.sleet;
    }
    if (normalized.contains('snow')) {
      return normalized.contains('heavy')
          ? SceneKey.snowHeavy
          : SceneKey.snowModerate;
    }
    if (normalized.contains('freezingrain')) {
      return SceneKey.freezingRain;
    }
    if (normalized.contains('drizzle')) {
      return SceneKey.drizzle;
    }
    if (normalized.contains('rain') || normalized.contains('showers')) {
      if (normalized.contains('heavy')) return SceneKey.rainHeavy;
      if (normalized.contains('light')) return SceneKey.rainLight;
      return SceneKey.rainModerate;
    }
    if (normalized.contains('partlycloudy') || normalized.contains('fair')) {
      return SceneKey.partlyCloudy;
    }
    if (normalized.contains('cloudy')) {
      return SceneKey.cloudy;
    }
    if (normalized.contains('clearsky')) {
      return SceneKey.clear;
    }
    return SceneKey.cloudy;
  }
}

@immutable
class WeatherSnapshot {
  final double temperatureC;
  final double windKmh;
  final double gustKmh;
  final SceneKey sceneKey;
  final int? cloudCoverPercent;
  final double? visibilityKm;

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
    this.cloudCoverPercent,
    this.visibilityKm,
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

@immutable
class HourlyForecastPoint {
  final DateTime timeUtc;
  final double temperatureC;
  final int? precipitationChancePercent;

  const HourlyForecastPoint({
    required this.timeUtc,
    required this.temperatureC,
    required this.precipitationChancePercent,
  });
}

@immutable
class DailyForecastPoint {
  final DateTime dayUtc;
  final double maxTemperatureC;
  final double minTemperatureC;
  final int? precipitationChancePercent;

  const DailyForecastPoint({
    required this.dayUtc,
    required this.maxTemperatureC,
    required this.minTemperatureC,
    required this.precipitationChancePercent,
  });
}

@immutable
class WeatherForecastSnapshot {
  final List<HourlyForecastPoint> hourly;
  final List<DailyForecastPoint> daily;

  const WeatherForecastSnapshot({required this.hourly, required this.daily});
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

  Duration? _debugClockOffset;

  double? _debugEurToUsd;
  bool _isRefreshing = false;
  Object? _lastError;
  DateTime? _lastRefreshedAt;
  int _refreshGeneration = 0;
  String _activePlacesSignature = '';

  Timer? _debounce;

  final CityRepository _cityRepository;
  final WeatherApiClient _weatherApi;
  final OpenMeteoClient _openMeteo;
  final OpenMeteoAirQualityClient _openMeteoAirQuality;
  final MetNorwayClient _metNorway;
  final FrankfurterClient _frankfurter;
  final OpenErApiClient _openErApi;
  final bool allowLiveRefreshInTestHarness;
  final Duration refreshDebounceDuration;
  final Duration simulatedNetworkLatency;
  final Duration currencyRetryBackoffDuration;
  late final _DashboardCurrencyDomain _currencyDomain;
  late final _DashboardEnvDomain _envDomain;
  late final _DashboardWeatherDomain _weatherDomain;

  DashboardLiveDataController({
    CityRepository? cityRepository,
    WeatherApiClient? weatherApiClient,
    OpenMeteoClient? openMeteoClient,
    OpenMeteoAirQualityClient? openMeteoAirQualityClient,
    MetNorwayClient? metNorwayClient,
    FrankfurterClient? frankfurterClient,
    OpenErApiClient? openErApiClient,
    this.allowLiveRefreshInTestHarness = false,
    this.refreshDebounceDuration = const Duration(milliseconds: 250),
    this.simulatedNetworkLatency = const Duration(milliseconds: 350),
    this.currencyRetryBackoffDuration = const Duration(minutes: 2),
  }) : _cityRepository = cityRepository ?? CityRepository.instance,
       _weatherApi = weatherApiClient ?? WeatherApiClient.fromEnvironment(),
       _openMeteo = openMeteoClient ?? OpenMeteoClient(),
       _openMeteoAirQuality =
           openMeteoAirQualityClient ?? OpenMeteoAirQualityClient(),
       _metNorway = metNorwayClient ?? MetNorwayClient(),
       _frankfurter = frankfurterClient ?? FrankfurterClient(),
       _openErApi = openErApiClient ?? OpenErApiClient() {
    _currencyDomain = _DashboardCurrencyDomain(
      frankfurterClient: _frankfurter,
      openErApiClient: _openErApi,
    );
    _envDomain = _DashboardEnvDomain(
      openMeteoAirQualityClient: _openMeteoAirQuality,
    );
    _weatherDomain = _DashboardWeatherDomain(
      cityRepository: _cityRepository,
      weatherApiClient: _weatherApi,
      openMeteoClient: _openMeteo,
      metNorwayClient: _metNorway,
    );
  }

  bool get isRefreshing => _isRefreshing;
  Object? get lastError => _lastError;
  Object? get lastWeatherError => _weatherDomain.lastError;
  DateTime? get lastWeatherErrorAt => _weatherDomain.lastErrorAt;
  DateTime? get lastWeatherRefreshedAt => _weatherDomain.lastRefreshedAt;
  Object? get lastEnvError => _envDomain.lastError;
  DateTime? get lastEnvErrorAt => _envDomain.lastErrorAt;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;

  /// Test hook for deterministic stale/fresh rendering contracts.
  ///
  /// Production code should not call this.
  @visibleForTesting
  void debugSetLastRefreshedAt(DateTime? value) {
    _lastRefreshedAt = value;
    _notify();
  }

  @visibleForTesting
  void debugSetLastWeatherRefreshedAt(DateTime? value) {
    _weatherDomain.debugSetLastRefreshedAt(value);
    _notify();
  }

  /// Test hook for deterministic currency stale/fresh contracts.
  ///
  /// Production code should not call this.
  @visibleForTesting
  void debugSetLastCurrencyRefreshedAt(DateTime? value) {
    _currencyDomain.debugSetLastRefreshedAt(value);
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

  bool get isWeatherStale {
    final last = lastWeatherRefreshedAt;
    if (last == null) return true;
    return DateTime.now().difference(last) > const Duration(minutes: 10);
  }

  double get eurToUsd => _debugEurToUsd ?? _currencyDomain.eurToUsd;

  /// Returns the conversion rate for [fromCode] -> [toCode].
  ///
  /// Contract:
  /// - Always returns 1.0 for same-currency conversions.
  /// - Uses live EUR-base rates when available.
  /// - Falls back to deterministic mock rates so currency UI never blanks.
  double? currencyRate({required String fromCode, required String toCode}) {
    return _currencyDomain.currencyRate(
      fromCode: fromCode,
      toCode: toCode,
      debugEurToUsd: _debugEurToUsd,
    );
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
  /// Contract:
  /// - Runtime builds default to live weather (Open-Meteo) for real devices.
  /// - Flutter tests remain hermetic via the FLUTTER_TEST guard.
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
    defaultValue: true,
  );
  static const String _envWeatherProvider = String.fromEnvironment(
    'WEATHER_PROVIDER',
    defaultValue: 'openmeteo',
  );
  static const bool _weatherNetworkAllowed = bool.fromEnvironment(
    'WEATHER_NETWORK_ALLOWED',
    defaultValue: true,
  );

  // Currency backend selection.
  //
  // Contract:
  // - Runtime builds default to live currency (Frankfurter).
  // - Flutter tests remain hermetic via the FLUTTER_TEST guard.
  //
  // Compile-time defaults (optional):
  // - --dart-define=CURRENCY_NETWORK_ENABLED=true
  // - --dart-define=CURRENCY_PROVIDER=frankfurter
  //
  // Compile-time hard-disable (optional):
  // - --dart-define=CURRENCY_NETWORK_ALLOWED=false
  static const bool _envCurrencyNetworkEnabled = bool.fromEnvironment(
    'CURRENCY_NETWORK_ENABLED',
    defaultValue: true,
  );
  static const String _envCurrencyProvider = String.fromEnvironment(
    'CURRENCY_PROVIDER',
    defaultValue: 'frankfurter',
  );
  static const bool _currencyNetworkAllowed = bool.fromEnvironment(
    'CURRENCY_NETWORK_ALLOWED',
    defaultValue: true,
  );
  static const bool _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

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

  bool _devSettingsLoaded = false;
  WeatherBackend get weatherBackend => _weatherDomain.backend;

  CurrencyBackend get currencyBackend => _currencyDomain.backend;

  /// Whether live network currency is enabled (and allowed) for this build.
  bool get currencyNetworkEnabled =>
      !_isFlutterTest &&
      _currencyNetworkAllowed &&
      _currencyDomain.backend != CurrencyBackend.mock;

  bool get currencyNetworkAllowed => _currencyNetworkAllowed;

  DateTime? get lastCurrencyRefreshedAt => _currencyDomain.lastRefreshedAt;
  DateTime? get lastCurrencyErrorAt => _currencyDomain.lastErrorAt;
  Object? get lastCurrencyError => _currencyDomain.lastError;
  Duration get currencyRefreshCadence => _currencyDomain.refreshCadence;

  bool get isCurrencyStale => _currencyDomain.isStale(now: DateTime.now());

  bool get shouldRetryCurrencyNow => _currencyDomain.shouldRetryNow(
    now: DateTime.now(),
    currencyNetworkEnabled: currencyNetworkEnabled,
    retryBackoffDuration: currencyRetryBackoffDuration,
  );

  /// Whether live network weather is enabled (and allowed) for this build.
  bool get weatherNetworkEnabled =>
      !_isFlutterTest &&
      _weatherNetworkAllowed &&
      _weatherDomain.backend != WeatherBackend.mock;

  bool get weatherNetworkAllowed => _weatherNetworkAllowed;

  bool get canUseWeatherApi => _weatherDomain.canUseWeatherApi;
  Future<void> loadDevSettings() async {
    if (_devSettingsLoaded) return;
    _devSettingsLoaded = true;

    final prefs = await SharedPreferences.getInstance();

    _weatherDomain.loadPersistedState(
      prefs: prefs,
      developerToolsEnabled: kDeveloperToolsEnabled,
    );

    _currencyDomain.loadPersistedState(
      prefs: prefs,
      developerToolsEnabled: kDeveloperToolsEnabled,
      currencyNetworkAllowed: _currencyNetworkAllowed,
    );
    _notify();
  }

  Future<void> setWeatherBackend(WeatherBackend backend) async {
    if (!kDeveloperToolsEnabled) return;
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

    if (_weatherDomain.backend == backend) return;
    _weatherDomain.setBackend(backend);

    final prefs = await SharedPreferences.getInstance();
    await _weatherDomain.persistBackendPreference(prefs);

    _notify();
  }

  Future<void> setCurrencyBackend(CurrencyBackend backend) async {
    if (!kDeveloperToolsEnabled) return;
    if (!_currencyNetworkAllowed && backend != CurrencyBackend.mock) {
      _lastError = StateError('Network currency is disallowed for this build');
      _notify();
      return;
    }

    if (_currencyDomain.backend == backend) return;
    _currencyDomain.setBackend(backend);

    final prefs = await SharedPreferences.getInstance();
    await _currencyDomain.persistBackendPreference(prefs);

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
  WeatherDebugOverride? get debugWeatherOverride =>
      _weatherDomain.debugWeatherOverride;

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
    if (!_weatherDomain.setDebugWeatherOverride(value)) return;
    _notify();
  }

  /// Developer-only emergency override for testing alert badge behavior.
  ///
  /// When non-null, `emergencyFor` returns this severity regardless of weather.
  WeatherEmergencySeverity? get debugEmergencySeverityOverride =>
      _weatherDomain.debugEmergencySeverityOverride;

  void setDebugEmergencySeverityOverride(WeatherEmergencySeverity? value) {
    if (!_weatherDomain.setDebugEmergencySeverityOverride(value)) return;
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
    if (!_weatherDomain.setDebugWeatherApiOverride(
      code: code,
      isNight: isNight,
      text: text,
    )) {
      return;
    }
    _notify();
  }

  WeatherSnapshot? weatherFor(Place? place) {
    return _weatherDomain.weatherFor(place);
  }

  SunTimesSnapshot? sunFor(Place? place) {
    return _weatherDomain.sunFor(place);
  }

  EnvSnapshot? envFor(Place? place) {
    return _envDomain.envFor(place);
  }

  WeatherForecastSnapshot? forecastFor(Place? place) {
    return _weatherDomain.forecastFor(place);
  }

  WeatherPresentation? weatherPresentationFor(Place? place) {
    if (place == null) return null;
    final weather = weatherFor(place);
    if (weather == null) return null;
    return WeatherConfidencePolicy.evaluate(
      weather: weather,
      forecast: forecastFor(place),
      backend: weatherBackend,
      now: DateTime.now(),
      nowUtc: nowUtc,
      lastWeatherRefreshedAt: lastWeatherRefreshedAt,
      secondOpinion: _weatherDomain.secondOpinionFor(place),
    );
  }

  WeatherEmergencyAssessment emergencyFor(Place? place) {
    return _weatherDomain.emergencyFor(place: place, env: envFor(place));
  }

  void ensureSeeded(List<Place> places) {
    var changed = false;
    final nowUtc = this.nowUtc;
    changed =
        _weatherDomain.ensureSeeded(
          places: places,
          nowUtc: nowUtc,
          weatherNetworkEnabled: weatherNetworkEnabled,
          envDomain: _envDomain,
        ) ||
        changed;

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

  void invalidateForPlaces({required List<Place> places}) {
    _activePlacesSignature = _placesSignature(places);
    _refreshGeneration += 1;
    _debounce?.cancel();
    _isRefreshing = false;
    _clearPlaceSnapshots();
    _lastRefreshedAt = null;
    _notify();
  }

  bool _isCurrentRefresh(int generation) =>
      !_isDisposed && generation == _refreshGeneration;

  String _placesSignature(List<Place> places) {
    return places
        .map(
          (p) => [
            p.id,
            p.type.name,
            p.cityName,
            p.countryCode,
            p.timeZoneId,
            p.unitSystem,
            p.use24h ? '24h' : '12h',
          ].join(':'),
        )
        .join('|');
  }

  void _clearPlaceSnapshots() {
    _weatherDomain.clearPlaceSnapshots();
    _envDomain.clearPlaceSnapshots();
  }

  void _recordRefreshError({
    required Object error,
    required StackTrace stackTrace,
    required String contextLabel,
    bool weather = false,
  }) {
    final now = DateTime.now();
    _lastError = error;
    if (weather) {
      _weatherDomain.recordLastError(error, now: now);
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'dashboard_live_data',
        context: ErrorDescription(contextLabel),
      ),
    );
  }

  Future<void> refreshAll({required List<Place> places}) async {
    final scopeSignature = _placesSignature(places);
    final scopeChanged = scopeSignature != _activePlacesSignature;
    _activePlacesSignature = scopeSignature;
    final requestGeneration = ++_refreshGeneration;
    if (scopeChanged) {
      _clearPlaceSnapshots();
      _lastRefreshedAt = null;
      _notify();
    }

    // Widget tests frequently enable a dev weather backend to validate UI
    // layout and overflow contracts. Do not schedule debounce timers or
    // simulate network latency in that environment, otherwise tests end with
    // pending timers and spurious failures.
    if (_isTestHarness() && !allowLiveRefreshInTestHarness) {
      _debounce?.cancel();
      _isRefreshing = true;
      _lastError = null;
      _notify();

      final nowUtc = this.nowUtc;
      for (final place in places) {
        _ensureFallbackSnapshotsForPlace(place, nowUtc: nowUtc);
      }

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
        if (!_isCurrentRefresh(requestGeneration)) {
          return;
        }
        _isRefreshing = true;
        _lastError = null;
        _notify();

        var didApplyAnyLiveWeatherUpdate = false;

        // Simulate a short network latency.
        await Future<void>.delayed(simulatedNetworkLatency);
        if (!_isCurrentRefresh(requestGeneration)) {
          return;
        }
        didApplyAnyLiveWeatherUpdate = await _weatherDomain.refreshPlaces(
          places: places,
          refreshGeneration: requestGeneration,
          weatherNetworkEnabled: weatherNetworkEnabled,
          envDomain: _envDomain,
          isCurrentRefresh: _isCurrentRefresh,
          recordRefreshError: (error, stackTrace, contextLabel) {
            _recordRefreshError(
              error: error,
              stackTrace: stackTrace,
              contextLabel: contextLabel,
            );
          },
          nowUtc: nowUtc,
        );
        if (!_isCurrentRefresh(requestGeneration)) {
          return;
        }
        final didRefreshCurrency = await _currencyDomain.maybeRefresh(
          refreshGeneration: requestGeneration,
          isCurrentRefresh: _isCurrentRefresh,
          currencyNetworkEnabled: currencyNetworkEnabled,
          retryBackoffDuration: currencyRetryBackoffDuration,
          recordRefreshError: (error, stackTrace, contextLabel) {
            _recordRefreshError(
              error: error,
              stackTrace: stackTrace,
              contextLabel: contextLabel,
            );
          },
        );
        if (!_isCurrentRefresh(requestGeneration)) {
          return;
        }
        final now = DateTime.now();
        if (didApplyAnyLiveWeatherUpdate || didRefreshCurrency) {
          _lastRefreshedAt = now;
        }

        if (!currencyNetworkEnabled) {
          _currencyDomain.restoreMockDefaults();
        }
      } catch (error, stackTrace) {
        if (_isCurrentRefresh(requestGeneration)) {
          _recordRefreshError(
            error: error,
            stackTrace: stackTrace,
            contextLabel: 'while refreshing dashboard live data',
          );
        }
      } finally {
        if (_isCurrentRefresh(requestGeneration)) {
          _isRefreshing = false;
          _notify();
        }
        completer.complete();
      }
    });
    return completer.future;
  }

  void _ensureFallbackSnapshotsForPlace(Place p, {required DateTime nowUtc}) {
    _weatherDomain.ensureFallbackSnapshotsForPlace(
      p,
      nowUtc: nowUtc,
      envDomain: _envDomain,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
