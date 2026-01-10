// Generated from WeatherAPI condition catalog.
// Source: https://www.weatherapi.com/docs/weather_conditions.json
//
// NOTE: This is used ONLY for Developer Tools (debug weather override) so
// operators can force any WeatherAPI condition code (day/night text) and
// visually verify SceneKey mapping and marquee scenes.
//
// Keep this file hand-edited if WeatherAPI adds/changes codes; do not add scripts.

class WeatherApiConditionCatalogEntry {
  const WeatherApiConditionCatalogEntry({
    required this.code,
    required this.dayText,
    required this.nightText,
    required this.icon,
  });

  final int code;
  final String dayText;
  final String nightText;
  final int icon;
}

class WeatherApiConditionOption {
  const WeatherApiConditionOption({
    required this.code,
    required this.isNight,
    required this.text,
    required this.icon,
  });

  final int code;
  final bool isNight;
  final String text;
  final int icon;

  String get sortLabel => text;

  String get displayLabel {
    final phase = isNight ? 'Night' : 'Day';
    return '$text ($phase)';
  }
}

String _toTitleCase(String input) {
  final parts = input.split(RegExp(r'\s+'));
  final capped = parts.map((w) {
    if (w.isEmpty) return w;
    final lower = w.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }).toList();
  return capped.join(' ');
}

class WeatherApiConditionCatalog {
  static const List<WeatherApiConditionCatalogEntry> entries =
      <WeatherApiConditionCatalogEntry>[
        WeatherApiConditionCatalogEntry(
          code: 1000,
          dayText: 'Sunny',
          nightText: 'Clear',
          icon: 113,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1003,
          dayText: 'Partly cloudy',
          nightText: 'Partly cloudy',
          icon: 116,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1006,
          dayText: 'Cloudy',
          nightText: 'Cloudy',
          icon: 119,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1009,
          dayText: 'Overcast',
          nightText: 'Overcast',
          icon: 122,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1030,
          dayText: 'Mist',
          nightText: 'Mist',
          icon: 143,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1063,
          dayText: 'Patchy rain possible',
          nightText: 'Patchy rain possible',
          icon: 176,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1066,
          dayText: 'Patchy snow possible',
          nightText: 'Patchy snow possible',
          icon: 179,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1069,
          dayText: 'Patchy sleet possible',
          nightText: 'Patchy sleet possible',
          icon: 182,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1072,
          dayText: 'Patchy freezing drizzle possible',
          nightText: 'Patchy freezing drizzle possible',
          icon: 185,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1087,
          dayText: 'Thundery outbreaks possible',
          nightText: 'Thundery outbreaks possible',
          icon: 200,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1114,
          dayText: 'Blowing snow',
          nightText: 'Blowing snow',
          icon: 227,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1117,
          dayText: 'Blizzard',
          nightText: 'Blizzard',
          icon: 230,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1135,
          dayText: 'Fog',
          nightText: 'Fog',
          icon: 248,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1147,
          dayText: 'Freezing fog',
          nightText: 'Freezing fog',
          icon: 260,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1150,
          dayText: 'Patchy light drizzle',
          nightText: 'Patchy light drizzle',
          icon: 263,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1153,
          dayText: 'Light drizzle',
          nightText: 'Light drizzle',
          icon: 266,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1168,
          dayText: 'Freezing drizzle',
          nightText: 'Freezing drizzle',
          icon: 281,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1171,
          dayText: 'Heavy freezing drizzle',
          nightText: 'Heavy freezing drizzle',
          icon: 284,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1180,
          dayText: 'Patchy light rain',
          nightText: 'Patchy light rain',
          icon: 293,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1183,
          dayText: 'Light rain',
          nightText: 'Light rain',
          icon: 296,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1186,
          dayText: 'Moderate rain at times',
          nightText: 'Moderate rain at times',
          icon: 299,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1189,
          dayText: 'Moderate rain',
          nightText: 'Moderate rain',
          icon: 302,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1192,
          dayText: 'Heavy rain at times',
          nightText: 'Heavy rain at times',
          icon: 305,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1195,
          dayText: 'Heavy rain',
          nightText: 'Heavy rain',
          icon: 308,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1198,
          dayText: 'Light freezing rain',
          nightText: 'Light freezing rain',
          icon: 311,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1201,
          dayText: 'Moderate or heavy freezing rain',
          nightText: 'Moderate or heavy freezing rain',
          icon: 314,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1204,
          dayText: 'Light sleet',
          nightText: 'Light sleet',
          icon: 317,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1207,
          dayText: 'Moderate or heavy sleet',
          nightText: 'Moderate or heavy sleet',
          icon: 320,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1210,
          dayText: 'Patchy light snow',
          nightText: 'Patchy light snow',
          icon: 323,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1213,
          dayText: 'Light snow',
          nightText: 'Light snow',
          icon: 326,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1216,
          dayText: 'Patchy moderate snow',
          nightText: 'Patchy moderate snow',
          icon: 329,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1219,
          dayText: 'Moderate snow',
          nightText: 'Moderate snow',
          icon: 332,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1222,
          dayText: 'Patchy heavy snow',
          nightText: 'Patchy heavy snow',
          icon: 335,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1225,
          dayText: 'Heavy snow',
          nightText: 'Heavy snow',
          icon: 338,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1237,
          dayText: 'Ice pellets',
          nightText: 'Ice pellets',
          icon: 350,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1240,
          dayText: 'Light rain shower',
          nightText: 'Light rain shower',
          icon: 353,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1243,
          dayText: 'Moderate or heavy rain shower',
          nightText: 'Moderate or heavy rain shower',
          icon: 356,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1246,
          dayText: 'Torrential rain shower',
          nightText: 'Torrential rain shower',
          icon: 359,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1249,
          dayText: 'Light sleet showers',
          nightText: 'Light sleet showers',
          icon: 362,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1252,
          dayText: 'Moderate or heavy sleet showers',
          nightText: 'Moderate or heavy sleet showers',
          icon: 365,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1255,
          dayText: 'Light snow showers',
          nightText: 'Light snow showers',
          icon: 368,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1258,
          dayText: 'Moderate or heavy snow showers',
          nightText: 'Moderate or heavy snow showers',
          icon: 371,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1261,
          dayText: 'Light showers of ice pellets',
          nightText: 'Light showers of ice pellets',
          icon: 374,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1264,
          dayText: 'Moderate or heavy showers of ice pellets',
          nightText: 'Moderate or heavy showers of ice pellets',
          icon: 377,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1273,
          dayText: 'Patchy light rain with thunder',
          nightText: 'Patchy light rain with thunder',
          icon: 386,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1276,
          dayText: 'Moderate or heavy rain with thunder',
          nightText: 'Moderate or heavy rain with thunder',
          icon: 389,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1279,
          dayText: 'Patchy light snow with thunder',
          nightText: 'Patchy light snow with thunder',
          icon: 392,
        ),
        WeatherApiConditionCatalogEntry(
          code: 1282,
          dayText: 'Moderate or heavy snow with thunder',
          nightText: 'Moderate or heavy snow with thunder',
          icon: 395,
        ),
      ];

  /// All selectable options (Day + Night variants) for Developer Tools.
  static List<WeatherApiConditionOption> allOptions() {
    final out = <WeatherApiConditionOption>[];
    for (final e in entries) {
      out.add(
        WeatherApiConditionOption(
          code: e.code,
          isNight: false,
          text: _toTitleCase(e.dayText),
          icon: e.icon,
        ),
      );
      out.add(
        WeatherApiConditionOption(
          code: e.code,
          isNight: true,
          text: _toTitleCase(e.nightText),
          icon: e.icon,
        ),
      );
    }
    out.sort(
      (a, b) => a.sortLabel.toLowerCase().compareTo(b.sortLabel.toLowerCase()),
    );
    return out;
  }
}
