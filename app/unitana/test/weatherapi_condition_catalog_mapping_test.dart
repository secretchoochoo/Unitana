import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';
import 'package:unitana/features/dashboard/models/weatherapi_conditions.dart';

void main() {
  test(
    'WeatherAPI condition catalog codes map to expected SceneKeys (day + night text)',
    () {
      const expectedByCode = <int, SceneKey>{
        1000: SceneKey.clear,
        1003: SceneKey.partlyCloudy,
        1006: SceneKey.cloudy,
        1009: SceneKey.overcast,
        1030: SceneKey.mist,
        1063: SceneKey.rainLight,
        1066: SceneKey.snowLight,
        1069: SceneKey.sleet,
        1072: SceneKey.freezingDrizzle,
        1087: SceneKey.thunderRain,
        1114: SceneKey.blowingSnow,
        1117: SceneKey.blizzard,
        1135: SceneKey.fog,
        1147: SceneKey.fog,
        1150: SceneKey.drizzle,
        1153: SceneKey.drizzle,
        1168: SceneKey.freezingDrizzle,
        1171: SceneKey.freezingDrizzle,
        1180: SceneKey.rainLight,
        1183: SceneKey.rainLight,
        1186: SceneKey.rainModerate,
        1189: SceneKey.rainModerate,
        1192: SceneKey.rainHeavy,
        1195: SceneKey.rainHeavy,
        1198: SceneKey.freezingRain,
        1201: SceneKey.freezingRain,
        1204: SceneKey.sleet,
        1207: SceneKey.sleet,
        1210: SceneKey.snowLight,
        1213: SceneKey.snowLight,
        1216: SceneKey.snowModerate,
        1219: SceneKey.snowModerate,
        1222: SceneKey.snowHeavy,
        1225: SceneKey.snowHeavy,
        1237: SceneKey.icePellets,
        1240: SceneKey.rainLight,
        1243: SceneKey.rainModerate,
        1246: SceneKey.rainHeavy,
        1249: SceneKey.sleet,
        1252: SceneKey.sleet,
        1255: SceneKey.snowLight,
        1258: SceneKey.snowModerate,
        1261: SceneKey.icePellets,
        1264: SceneKey.icePellets,
        1273: SceneKey.thunderRain,
        1276: SceneKey.thunderRain,
        1279: SceneKey.thunderSnow,
        1282: SceneKey.thunderSnow,
      };

      // Sanity: catalog should not drift without the test being updated.
      expect(
        WeatherApiConditionCatalog.entries.length,
        expectedByCode.length,
        reason:
            'WeatherAPI catalog entry count changed; update the expected map.',
      );

      for (final entry in WeatherApiConditionCatalog.entries) {
        final expected = expectedByCode[entry.code];
        expect(
          expected,
          isNotNull,
          reason:
              'No expected mapping defined in test for WeatherAPI code ${entry.code}.',
        );

        final dayKey = WeatherApiSceneKeyMapper.fromWeatherApi(
          code: entry.code,
          text: entry.dayText,
        );
        final nightKey = WeatherApiSceneKeyMapper.fromWeatherApi(
          code: entry.code,
          text: entry.nightText,
        );

        expect(
          dayKey,
          expected,
          reason: 'Unexpected SceneKey for code ${entry.code} (day text).',
        );
        expect(
          nightKey,
          expected,
          reason: 'Unexpected SceneKey for code ${entry.code} (night text).',
        );
      }
    },
  );
}
