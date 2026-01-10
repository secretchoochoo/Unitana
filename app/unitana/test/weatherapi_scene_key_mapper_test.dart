import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/dashboard_live_data.dart';

void main() {
  group('WeatherApiSceneKeyMapper', () {
    test('maps representative WeatherAPI codes to SceneKey', () {
      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(code: 1000, text: 'Sunny'),
        SceneKey.clear,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(
          code: 1003,
          text: 'Partly cloudy',
        ),
        SceneKey.partlyCloudy,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(code: 1006, text: 'Cloudy'),
        SceneKey.cloudy,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(code: 1009, text: 'Overcast'),
        SceneKey.overcast,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(
          code: 1153,
          text: 'Light drizzle',
        ),
        SceneKey.drizzle,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(code: 1183, text: 'Light rain'),
        SceneKey.rainLight,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(code: 1195, text: 'Heavy rain'),
        SceneKey.rainHeavy,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(
          code: 1204,
          text: 'Light sleet',
        ),
        SceneKey.sleet,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(code: 1222, text: 'Heavy snow'),
        SceneKey.snowHeavy,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(
          code: 1237,
          text: 'Ice pellets',
        ),
        SceneKey.icePellets,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(code: 1273, text: 'Thunder'),
        SceneKey.thunderRain,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(
          code: 1279,
          text: 'Thundersnow',
        ),
        SceneKey.thunderSnow,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(code: 1135, text: 'Fog'),
        SceneKey.fog,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(code: 1030, text: 'Mist'),
        SceneKey.mist,
      );
    });

    test('falls back to text heuristics for unknown codes', () {
      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(code: 9999, text: 'Blizzard'),
        SceneKey.blizzard,
      );

      expect(
        WeatherApiSceneKeyMapper.fromWeatherApi(
          code: 9999,
          text: 'Freezing rain',
        ),
        SceneKey.freezingRain,
      );
    });
  });
}
