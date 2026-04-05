part of 'dashboard_live_data.dart';

enum WeatherConfidenceBand { high, medium, low, veryLow }

@immutable
class WeatherPresentation {
  final SceneKey originalSceneKey;
  final SceneKey displaySceneKey;
  final String rawConditionText;
  final WeatherConfidenceBand confidenceBand;
  final double confidenceScore;
  final bool hasSecondaryDisagreement;

  const WeatherPresentation({
    required this.originalSceneKey,
    required this.displaySceneKey,
    required this.rawConditionText,
    required this.confidenceBand,
    required this.confidenceScore,
    this.hasSecondaryDisagreement = false,
  });
}

@immutable
class WeatherSecondOpinion {
  final String provider;
  final DateTime sampledAtUtc;
  final SceneKey sceneKey;
  final String conditionText;
  final double? temperatureC;
  final double? windKmh;
  final int? cloudCoverPercent;

  const WeatherSecondOpinion({
    required this.provider,
    required this.sampledAtUtc,
    required this.sceneKey,
    required this.conditionText,
    this.temperatureC,
    this.windKmh,
    this.cloudCoverPercent,
  });
}

class WeatherConfidencePolicy {
  const WeatherConfidencePolicy._();

  static const Map<WeatherBackend, double> _providerPriors =
      <WeatherBackend, double>{
        WeatherBackend.openMeteo: 0.479,
        WeatherBackend.weatherApi: 0.500,
        WeatherBackend.mock: 0.250,
      };

  static WeatherPresentation evaluate({
    required WeatherSnapshot weather,
    required WeatherForecastSnapshot? forecast,
    required WeatherBackend backend,
    required DateTime now,
    required DateTime nowUtc,
    required DateTime? lastWeatherRefreshedAt,
    WeatherSecondOpinion? secondOpinion,
  }) {
    var score = _providerPriors[backend] ?? 0.5;
    score += _freshnessAdjustment(
      now: now,
      lastWeatherRefreshedAt: lastWeatherRefreshedAt,
    );
    score += _severityAdjustment(weather.sceneKey);
    score += _supportAdjustment(
      weather: weather,
      forecast: forecast,
      nowUtc: nowUtc,
      backend: backend,
      secondOpinion: secondOpinion,
    );

    final normalizedScore = score.clamp(0.0, 1.0);
    final band = _bandFor(normalizedScore);
    final disagreement = _hasMaterialDisagreement(
      weather.sceneKey,
      secondOpinion?.sceneKey,
    );
    return WeatherPresentation(
      originalSceneKey: weather.sceneKey,
      displaySceneKey: _displaySceneKey(weather.sceneKey, band),
      rawConditionText: weather.conditionText,
      confidenceBand: band,
      confidenceScore: normalizedScore,
      hasSecondaryDisagreement: disagreement,
    );
  }

  static double _freshnessAdjustment({
    required DateTime now,
    required DateTime? lastWeatherRefreshedAt,
  }) {
    if (lastWeatherRefreshedAt == null) return -0.20;
    final age = now.difference(lastWeatherRefreshedAt);
    if (age <= const Duration(minutes: 5)) return 0.18;
    if (age <= const Duration(minutes: 15)) return 0.10;
    if (age <= const Duration(minutes: 30)) return 0.0;
    if (age <= const Duration(hours: 1)) return -0.08;
    return -0.18;
  }

  static double _severityAdjustment(SceneKey sceneKey) {
    switch (sceneKey) {
      case SceneKey.fog:
      case SceneKey.mist:
      case SceneKey.hazeDust:
      case SceneKey.smokeWildfire:
      case SceneKey.ashfall:
      case SceneKey.thunderRain:
      case SceneKey.thunderSnow:
      case SceneKey.blowingSnow:
      case SceneKey.blizzard:
      case SceneKey.freezingRain:
      case SceneKey.tornado:
      case SceneKey.squall:
        return -0.10;
      case SceneKey.drizzle:
      case SceneKey.freezingDrizzle:
      case SceneKey.rainLight:
      case SceneKey.rainModerate:
      case SceneKey.rainHeavy:
      case SceneKey.sleet:
      case SceneKey.snowLight:
      case SceneKey.snowModerate:
      case SceneKey.snowHeavy:
      case SceneKey.icePellets:
      case SceneKey.windy:
        return -0.05;
      case SceneKey.clear:
      case SceneKey.partlyCloudy:
      case SceneKey.cloudy:
      case SceneKey.overcast:
        return 0.05;
    }
  }

  static double _supportAdjustment({
    required WeatherSnapshot weather,
    required WeatherForecastSnapshot? forecast,
    required DateTime nowUtc,
    required WeatherBackend backend,
    required WeatherSecondOpinion? secondOpinion,
  }) {
    var score = 0.0;
    final precipChance = _primaryPrecipitationChance(
      nowUtc: nowUtc,
      forecast: forecast,
    );
    final visibilityKm = weather.visibilityKm;
    final cloudCoverPercent = weather.cloudCoverPercent;

    switch (weather.sceneKey) {
      case SceneKey.fog:
      case SceneKey.mist:
      case SceneKey.hazeDust:
      case SceneKey.smokeWildfire:
      case SceneKey.ashfall:
        if (visibilityKm != null) {
          if (visibilityKm <= 0.3) {
            score += 0.18;
          } else if (visibilityKm <= 1.0) {
            score += 0.12;
          } else if (visibilityKm <= 3.0) {
            score += 0.05;
          } else if (visibilityKm > 8.0) {
            score -= 0.22;
          } else if (visibilityKm > 3.0) {
            score -= 0.10;
          }
        }
        if (cloudCoverPercent != null) {
          if (cloudCoverPercent >= 85) {
            score += 0.08;
          } else if (cloudCoverPercent <= 30) {
            score -= 0.10;
          }
        }
        if (backend == WeatherBackend.openMeteo) {
          score -= 0.14;
        }
        break;
      case SceneKey.clear:
      case SceneKey.partlyCloudy:
        if (cloudCoverPercent != null) {
          if (cloudCoverPercent <= 25) {
            score += 0.14;
          } else if (cloudCoverPercent <= 45) {
            score += 0.06;
          } else if (cloudCoverPercent >= 85) {
            score -= 0.20;
          } else if (cloudCoverPercent >= 70) {
            score -= 0.12;
          }
        }
        if (visibilityKm != null && visibilityKm >= 8.0) {
          score += 0.04;
        }
        break;
      case SceneKey.cloudy:
      case SceneKey.overcast:
        if (cloudCoverPercent != null) {
          if (cloudCoverPercent >= 75) {
            score += 0.12;
          } else if (cloudCoverPercent < 35) {
            score -= 0.18;
          }
        }
        break;
      case SceneKey.drizzle:
      case SceneKey.freezingDrizzle:
      case SceneKey.rainLight:
      case SceneKey.rainModerate:
      case SceneKey.rainHeavy:
      case SceneKey.thunderRain:
      case SceneKey.freezingRain:
        score += _precipitationSupport(precipChance);
        break;
      case SceneKey.sleet:
      case SceneKey.snowLight:
      case SceneKey.snowModerate:
      case SceneKey.snowHeavy:
      case SceneKey.blowingSnow:
      case SceneKey.blizzard:
      case SceneKey.icePellets:
      case SceneKey.thunderSnow:
        score += _precipitationSupport(precipChance, snowy: true);
        break;
      case SceneKey.windy:
      case SceneKey.tornado:
      case SceneKey.squall:
        if (weather.gustKmh >= 35) {
          score += 0.10;
        } else if (weather.gustKmh <= 15) {
          score -= 0.08;
        }
        break;
    }

    score += _secondaryOpinionAdjustment(
      primaryScene: weather.sceneKey,
      secondOpinion: secondOpinion,
    );

    return score;
  }

  static double _secondaryOpinionAdjustment({
    required SceneKey primaryScene,
    required WeatherSecondOpinion? secondOpinion,
  }) {
    if (secondOpinion == null) return 0.0;
    final primaryBucket = _bucketFor(primaryScene);
    final secondaryBucket = _bucketFor(secondOpinion.sceneKey);
    if (primaryBucket == secondaryBucket) return 0.10;
    if (primaryBucket == _ConfidenceBucket.lowVisibility &&
        (secondaryBucket == _ConfidenceBucket.clearSkies ||
            secondaryBucket == _ConfidenceBucket.cloudCover)) {
      return -0.24;
    }
    if (primaryBucket == _ConfidenceBucket.precipitation &&
        (secondaryBucket == _ConfidenceBucket.clearSkies ||
            secondaryBucket == _ConfidenceBucket.cloudCover)) {
      return -0.14;
    }
    if (primaryBucket == _ConfidenceBucket.severe &&
        secondaryBucket != _ConfidenceBucket.severe) {
      return -0.20;
    }
    if (primaryBucket == _ConfidenceBucket.clearSkies &&
        (secondaryBucket == _ConfidenceBucket.lowVisibility ||
            secondaryBucket == _ConfidenceBucket.precipitation)) {
      return -0.18;
    }
    return -0.08;
  }

  static double _precipitationSupport(int? precipChance, {bool snowy = false}) {
    if (precipChance == null) return snowy ? -0.04 : -0.02;
    if (precipChance >= 70) return 0.15;
    if (precipChance >= 40) return 0.08;
    if (precipChance <= 10) return -0.18;
    if (precipChance <= 25) return -0.10;
    return 0.0;
  }

  static int? _primaryPrecipitationChance({
    required DateTime nowUtc,
    required WeatherForecastSnapshot? forecast,
  }) {
    if (forecast == null) return null;
    for (final hourly in forecast.hourly) {
      if (hourly.timeUtc.isBefore(nowUtc)) continue;
      final precip = hourly.precipitationChancePercent;
      if (precip != null) return precip;
    }
    for (final daily in forecast.daily) {
      final precip = daily.precipitationChancePercent;
      if (precip != null) return precip;
    }
    return null;
  }

  static WeatherConfidenceBand _bandFor(double score) {
    if (score >= 0.80) return WeatherConfidenceBand.high;
    if (score >= 0.60) return WeatherConfidenceBand.medium;
    if (score >= 0.40) return WeatherConfidenceBand.low;
    return WeatherConfidenceBand.veryLow;
  }

  static bool _hasMaterialDisagreement(
    SceneKey primaryScene,
    SceneKey? secondaryScene,
  ) {
    if (secondaryScene == null) return false;
    return _bucketFor(primaryScene) != _bucketFor(secondaryScene);
  }

  static _ConfidenceBucket _bucketFor(SceneKey scene) {
    switch (scene) {
      case SceneKey.clear:
      case SceneKey.partlyCloudy:
        return _ConfidenceBucket.clearSkies;
      case SceneKey.cloudy:
      case SceneKey.overcast:
        return _ConfidenceBucket.cloudCover;
      case SceneKey.fog:
      case SceneKey.mist:
      case SceneKey.hazeDust:
      case SceneKey.smokeWildfire:
      case SceneKey.ashfall:
        return _ConfidenceBucket.lowVisibility;
      case SceneKey.drizzle:
      case SceneKey.freezingDrizzle:
      case SceneKey.rainLight:
      case SceneKey.rainModerate:
      case SceneKey.rainHeavy:
      case SceneKey.freezingRain:
      case SceneKey.sleet:
      case SceneKey.snowLight:
      case SceneKey.snowModerate:
      case SceneKey.snowHeavy:
      case SceneKey.blowingSnow:
      case SceneKey.blizzard:
      case SceneKey.icePellets:
        return _ConfidenceBucket.precipitation;
      case SceneKey.thunderRain:
      case SceneKey.thunderSnow:
      case SceneKey.windy:
      case SceneKey.tornado:
      case SceneKey.squall:
        return _ConfidenceBucket.severe;
    }
  }

  static SceneKey _displaySceneKey(
    SceneKey original,
    WeatherConfidenceBand band,
  ) {
    switch (band) {
      case WeatherConfidenceBand.high:
        return original;
      case WeatherConfidenceBand.medium:
        return switch (original) {
          SceneKey.fog => SceneKey.mist,
          SceneKey.smokeWildfire => SceneKey.hazeDust,
          SceneKey.thunderRain => SceneKey.rainModerate,
          SceneKey.thunderSnow => SceneKey.snowModerate,
          SceneKey.blizzard => SceneKey.snowHeavy,
          SceneKey.tornado => SceneKey.windy,
          SceneKey.squall => SceneKey.windy,
          _ => original,
        };
      case WeatherConfidenceBand.low:
        return switch (original) {
          SceneKey.fog ||
          SceneKey.mist ||
          SceneKey.hazeDust ||
          SceneKey.smokeWildfire ||
          SceneKey.ashfall => SceneKey.cloudy,
          SceneKey.thunderRain || SceneKey.rainHeavy => SceneKey.rainLight,
          SceneKey.thunderSnow ||
          SceneKey.blizzard ||
          SceneKey.snowHeavy => SceneKey.snowLight,
          SceneKey.tornado || SceneKey.squall => SceneKey.windy,
          _ => original,
        };
      case WeatherConfidenceBand.veryLow:
        return switch (original) {
          SceneKey.tornado ||
          SceneKey.squall ||
          SceneKey.windy => SceneKey.windy,
          SceneKey.overcast => SceneKey.overcast,
          _ => SceneKey.cloudy,
        };
    }
  }
}

enum _ConfidenceBucket {
  clearSkies,
  cloudCover,
  lowVisibility,
  precipitation,
  severe,
}
