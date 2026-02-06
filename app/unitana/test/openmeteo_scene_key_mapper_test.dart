import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';

void main() {
  group('OpenMeteoSceneKeyMapper audit', () {
    const expectedByCode = <int, SceneKey>{
      0: SceneKey.clear,
      1: SceneKey.partlyCloudy,
      2: SceneKey.partlyCloudy,
      3: SceneKey.overcast,
      45: SceneKey.fog,
      48: SceneKey.fog,
      51: SceneKey.drizzle,
      53: SceneKey.drizzle,
      55: SceneKey.drizzle,
      56: SceneKey.freezingDrizzle,
      57: SceneKey.freezingDrizzle,
      61: SceneKey.rainLight,
      63: SceneKey.rainModerate,
      65: SceneKey.rainHeavy,
      66: SceneKey.freezingRain,
      67: SceneKey.freezingRain,
      71: SceneKey.snowLight,
      73: SceneKey.snowModerate,
      75: SceneKey.snowHeavy,
      77: SceneKey.snowLight,
      80: SceneKey.rainLight,
      81: SceneKey.rainModerate,
      82: SceneKey.rainHeavy,
      85: SceneKey.snowModerate,
      86: SceneKey.snowModerate,
      95: SceneKey.thunderRain,
      96: SceneKey.thunderRain,
      99: SceneKey.thunderRain,
    };

    test('maps full known WMO code set used by Open-Meteo contract', () {
      for (final entry in expectedByCode.entries) {
        expect(
          OpenMeteoSceneKeyMapper.fromWmoCode(entry.key),
          entry.value,
          reason: 'Unexpected mapping for WMO code ${entry.key}',
        );
      }
    });

    test('labels are explicit for all known WMO codes', () {
      for (final code in expectedByCode.keys) {
        final label = OpenMeteoSceneKeyMapper.labelFor(code);
        expect(
          label,
          isNot('Weather'),
          reason: 'Known WMO code $code fell through to generic label',
        );
      }

      expect(OpenMeteoSceneKeyMapper.labelFor(0), 'Clear');
      expect(OpenMeteoSceneKeyMapper.labelFor(1), 'Mostly clear');
      expect(OpenMeteoSceneKeyMapper.labelFor(2), 'Partly cloudy');
      expect(OpenMeteoSceneKeyMapper.labelFor(3), 'Overcast');
      expect(OpenMeteoSceneKeyMapper.labelFor(9999), 'Weather');
    });
  });
}
