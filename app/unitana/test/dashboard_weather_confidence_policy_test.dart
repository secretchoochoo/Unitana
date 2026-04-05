import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/dashboard_copy.dart';
import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';

void main() {
  test('open-meteo fog stays medium-confidence and softens the scene', () {
    final presentation = WeatherConfidencePolicy.evaluate(
      weather: const WeatherSnapshot(
        temperatureC: 9.0,
        windKmh: 5.0,
        gustKmh: 8.0,
        sceneKey: SceneKey.fog,
        cloudCoverPercent: 95,
        visibilityKm: 0.06,
        conditionText: 'Fog',
        conditionCode: 45,
      ),
      forecast: const WeatherForecastSnapshot(hourly: [], daily: []),
      backend: WeatherBackend.openMeteo,
      now: DateTime(2026, 4, 5, 7, 34),
      nowUtc: DateTime.utc(2026, 4, 5, 6, 34),
      lastWeatherRefreshedAt: DateTime(2026, 4, 5, 7, 33),
    );

    expect(presentation.confidenceBand, WeatherConfidenceBand.medium);
    expect(presentation.displaySceneKey, SceneKey.mist);
    expect(presentation.confidenceScore, greaterThan(0.60));
    expect(presentation.confidenceScore, lessThan(0.80));
  });

  test('second-opinion disagreement drops risky fog to low confidence', () {
    final presentation = WeatherConfidencePolicy.evaluate(
      weather: const WeatherSnapshot(
        temperatureC: 9.0,
        windKmh: 5.0,
        gustKmh: 8.0,
        sceneKey: SceneKey.fog,
        cloudCoverPercent: 95,
        visibilityKm: 0.06,
        conditionText: 'Fog',
        conditionCode: 45,
      ),
      forecast: const WeatherForecastSnapshot(hourly: [], daily: []),
      backend: WeatherBackend.openMeteo,
      now: DateTime(2026, 4, 5, 7, 34),
      nowUtc: DateTime.utc(2026, 4, 5, 6, 34),
      lastWeatherRefreshedAt: DateTime(2026, 4, 5, 7, 33),
      secondOpinion: WeatherSecondOpinion(
        provider: 'MET Norway',
        sampledAtUtc: DateTime.utc(2026, 4, 5, 7),
        sceneKey: SceneKey.partlyCloudy,
        conditionText: 'fair_day',
        temperatureC: 10.7,
        windKmh: 7.2,
        cloudCoverPercent: 20,
      ),
    );

    expect(presentation.confidenceBand, WeatherConfidenceBand.low);
    expect(presentation.displaySceneKey, SceneKey.cloudy);
    expect(presentation.hasSecondaryDisagreement, isTrue);
  });

  test('clear weather with supporting signals stays high-confidence', () {
    final presentation = WeatherConfidencePolicy.evaluate(
      weather: const WeatherSnapshot(
        temperatureC: 16.0,
        windKmh: 8.0,
        gustKmh: 12.0,
        sceneKey: SceneKey.clear,
        cloudCoverPercent: 8,
        visibilityKm: 16.0,
        conditionText: 'Clear',
      ),
      forecast: const WeatherForecastSnapshot(hourly: [], daily: []),
      backend: WeatherBackend.openMeteo,
      now: DateTime(2026, 4, 5, 7, 34),
      nowUtc: DateTime.utc(2026, 4, 5, 6, 34),
      lastWeatherRefreshedAt: DateTime(2026, 4, 5, 7, 32),
    );

    expect(presentation.confidenceBand, WeatherConfidenceBand.high);
    expect(presentation.displaySceneKey, SceneKey.clear);
  });

  test('stale uncertain weather downshifts to very low confidence', () {
    final presentation = WeatherConfidencePolicy.evaluate(
      weather: const WeatherSnapshot(
        temperatureC: 12.0,
        windKmh: 10.0,
        gustKmh: 14.0,
        sceneKey: SceneKey.fog,
        cloudCoverPercent: 45,
        visibilityKm: 10.0,
        conditionText: 'Fog',
      ),
      forecast: const WeatherForecastSnapshot(hourly: [], daily: []),
      backend: WeatherBackend.openMeteo,
      now: DateTime(2026, 4, 5, 9, 34),
      nowUtc: DateTime.utc(2026, 4, 5, 8, 34),
      lastWeatherRefreshedAt: DateTime(2026, 4, 5, 7, 0),
    );

    expect(presentation.confidenceBand, WeatherConfidenceBand.veryLow);
    expect(presentation.displaySceneKey, SceneKey.cloudy);
  });

  testWidgets('confidence copy softens medium and very-low presentations', (
    tester,
  ) async {
    late String mediumLabel;
    late String veryLowLabel;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            mediumLabel = DashboardCopy.weatherPresentationLabel(
              context,
              presentation: const WeatherPresentation(
                originalSceneKey: SceneKey.fog,
                displaySceneKey: SceneKey.mist,
                rawConditionText: 'Fog',
                confidenceBand: WeatherConfidenceBand.medium,
                confidenceScore: 0.68,
              ),
            );
            veryLowLabel = DashboardCopy.weatherPresentationLabel(
              context,
              presentation: const WeatherPresentation(
                originalSceneKey: SceneKey.fog,
                displaySceneKey: SceneKey.cloudy,
                rawConditionText: 'Fog',
                confidenceBand: WeatherConfidenceBand.veryLow,
                confidenceScore: 0.32,
              ),
            );
            final lowLabel = DashboardCopy.weatherPresentationLabel(
              context,
              presentation: const WeatherPresentation(
                originalSceneKey: SceneKey.fog,
                displaySceneKey: SceneKey.cloudy,
                rawConditionText: 'Fog',
                confidenceBand: WeatherConfidenceBand.low,
                confidenceScore: 0.46,
                hasSecondaryDisagreement: true,
              ),
            );
            expect(lowLabel, 'Low visibility risk');
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(mediumLabel, 'Fog likely');
    expect(veryLowLabel, 'Current conditions uncertain');
  });
}
