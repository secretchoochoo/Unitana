/// A small curated city list for first-run and quick picking.
///
/// Notes:
/// - `defaultUnitSystem` matches `Place.unitSystem` (String): 'imperial' or 'metric'
/// - `defaultUse24h` matches `Place.use24h` (bool)
///
/// Keep this file lightweight and const-friendly.
class City {
  final String id;
  final String cityName;
  final String countryCode;
  final String timeZoneId;
  final String currencyCode;

  /// 'imperial' | 'metric'
  final String defaultUnitSystem;

  /// true = 24h clock
  final bool defaultUse24h;

  const City({
    required this.id,
    required this.cityName,
    required this.countryCode,
    required this.timeZoneId,
    required this.currencyCode,
    required this.defaultUnitSystem,
    required this.defaultUse24h,
  });

  String get display => '$cityName, $countryCode';
}

const List<City> kCities = [
  // USA (imperial, 12h)
  City(
    id: 'denver_us',
    cityName: 'Denver',
    countryCode: 'US',
    timeZoneId: 'America/Denver',
    currencyCode: 'USD',
    defaultUnitSystem: 'imperial',
    defaultUse24h: false,
  ),
  City(
    id: 'new_york_us',
    cityName: 'New York',
    countryCode: 'US',
    timeZoneId: 'America/New_York',
    currencyCode: 'USD',
    defaultUnitSystem: 'imperial',
    defaultUse24h: false,
  ),
  City(
    id: 'los_angeles_us',
    cityName: 'Los Angeles',
    countryCode: 'US',
    timeZoneId: 'America/Los_Angeles',
    currencyCode: 'USD',
    defaultUnitSystem: 'imperial',
    defaultUse24h: false,
  ),
  City(
    id: 'chicago_us',
    cityName: 'Chicago',
    countryCode: 'US',
    timeZoneId: 'America/Chicago',
    currencyCode: 'USD',
    defaultUnitSystem: 'imperial',
    defaultUse24h: false,
  ),

  // Canada (metric-ish, 12h commonly)
  City(
    id: 'toronto_ca',
    cityName: 'Toronto',
    countryCode: 'CA',
    timeZoneId: 'America/Toronto',
    currencyCode: 'CAD',
    defaultUnitSystem: 'metric',
    defaultUse24h: false,
  ),
  City(
    id: 'vancouver_ca',
    cityName: 'Vancouver',
    countryCode: 'CA',
    timeZoneId: 'America/Vancouver',
    currencyCode: 'CAD',
    defaultUnitSystem: 'metric',
    defaultUse24h: false,
  ),

  // Portugal (metric, 24h)
  City(
    id: 'lisbon_pt',
    cityName: 'Lisbon',
    countryCode: 'PT',
    timeZoneId: 'Europe/Lisbon',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'porto_pt',
    cityName: 'Porto',
    countryCode: 'PT',
    timeZoneId: 'Europe/Lisbon',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),

  // Western Europe (metric, 24h)
  City(
    id: 'london_gb',
    cityName: 'London',
    countryCode: 'GB',
    timeZoneId: 'Europe/London',
    currencyCode: 'GBP',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'paris_fr',
    cityName: 'Paris',
    countryCode: 'FR',
    timeZoneId: 'Europe/Paris',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'madrid_es',
    cityName: 'Madrid',
    countryCode: 'ES',
    timeZoneId: 'Europe/Madrid',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'barcelona_es',
    cityName: 'Barcelona',
    countryCode: 'ES',
    timeZoneId: 'Europe/Madrid',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'rome_it',
    cityName: 'Rome',
    countryCode: 'IT',
    timeZoneId: 'Europe/Rome',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'milan_it',
    cityName: 'Milan',
    countryCode: 'IT',
    timeZoneId: 'Europe/Rome',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'berlin_de',
    cityName: 'Berlin',
    countryCode: 'DE',
    timeZoneId: 'Europe/Berlin',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'amsterdam_nl',
    cityName: 'Amsterdam',
    countryCode: 'NL',
    timeZoneId: 'Europe/Amsterdam',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),

  // Nordics (metric, 24h)
  City(
    id: 'stockholm_se',
    cityName: 'Stockholm',
    countryCode: 'SE',
    timeZoneId: 'Europe/Stockholm',
    currencyCode: 'SEK',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'oslo_no',
    cityName: 'Oslo',
    countryCode: 'NO',
    timeZoneId: 'Europe/Oslo',
    currencyCode: 'NOK',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'copenhagen_dk',
    cityName: 'Copenhagen',
    countryCode: 'DK',
    timeZoneId: 'Europe/Copenhagen',
    currencyCode: 'DKK',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),

  // LATAM (metric, 24h common)
  City(
    id: 'mexico_city_mx',
    cityName: 'Mexico City',
    countryCode: 'MX',
    timeZoneId: 'America/Mexico_City',
    currencyCode: 'MXN',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'sao_paulo_br',
    cityName: 'São Paulo',
    countryCode: 'BR',
    timeZoneId: 'America/Sao_Paulo',
    currencyCode: 'BRL',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),

  // APAC (metric, 24h common)
  City(
    id: 'tokyo_jp',
    cityName: 'Tokyo',
    countryCode: 'JP',
    timeZoneId: 'Asia/Tokyo',
    currencyCode: 'JPY',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'seoul_kr',
    cityName: 'Seoul',
    countryCode: 'KR',
    timeZoneId: 'Asia/Seoul',
    currencyCode: 'KRW',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'sydney_au',
    cityName: 'Sydney',
    countryCode: 'AU',
    timeZoneId: 'Australia/Sydney',
    currencyCode: 'AUD',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
];
