import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';

void main() {
  test('taxonomy falls back to none when all alert metadata is missing', () {
    final assessment = WeatherEmergencyTaxonomy.assess(
      weather: null,
      env: null,
    );
    expect(assessment.severity, WeatherEmergencySeverity.none);
    expect(assessment.reasonKey, 'none');
  });

  test('tornado scene has highest precedence over other signals', () {
    final assessment = WeatherEmergencyTaxonomy.assess(
      weather: const WeatherSnapshot(
        temperatureC: 21,
        windKmh: 30,
        gustKmh: 45,
        sceneKey: SceneKey.tornado,
        conditionText: 'Clear',
      ),
      env: const EnvSnapshot(usAqi: 325, pollenIndex: 4.5),
    );
    expect(assessment.severity, WeatherEmergencySeverity.emergency);
    expect(assessment.reasonKey, 'tornado');
    expect(assessment.source, 'scene');
  });

  test('provider warning text maps to warning when scene is neutral', () {
    final assessment = WeatherEmergencyTaxonomy.assess(
      weather: const WeatherSnapshot(
        temperatureC: 17,
        windKmh: 12,
        gustKmh: 18,
        sceneKey: SceneKey.cloudy,
        conditionText: 'Coastal Flood Warning',
      ),
      env: const EnvSnapshot(usAqi: 45, pollenIndex: 0.2),
    );
    expect(assessment.severity, WeatherEmergencySeverity.warning);
    expect(assessment.reasonKey, 'provider_warning');
    expect(assessment.source, 'provider_text');
  });

  test(
    'wind threshold produces deterministic advisory/watch/warning bands',
    () {
      final advisory = WeatherEmergencyTaxonomy.assess(
        weather: const WeatherSnapshot(
          temperatureC: 9,
          windKmh: 30,
          gustKmh: 52,
          sceneKey: SceneKey.clear,
          conditionText: 'Clear',
        ),
        env: null,
      );
      final watch = WeatherEmergencyTaxonomy.assess(
        weather: const WeatherSnapshot(
          temperatureC: 9,
          windKmh: 40,
          gustKmh: 72,
          sceneKey: SceneKey.clear,
          conditionText: 'Clear',
        ),
        env: null,
      );
      final warning = WeatherEmergencyTaxonomy.assess(
        weather: const WeatherSnapshot(
          temperatureC: 9,
          windKmh: 65,
          gustKmh: 102,
          sceneKey: SceneKey.clear,
          conditionText: 'Clear',
        ),
        env: null,
      );

      expect(advisory.severity, WeatherEmergencySeverity.advisory);
      expect(watch.severity, WeatherEmergencySeverity.watch);
      expect(warning.severity, WeatherEmergencySeverity.warning);
      expect(advisory.reasonKey, 'high_wind');
      expect(watch.reasonKey, 'high_wind');
      expect(warning.reasonKey, 'high_wind');
    },
  );
}
