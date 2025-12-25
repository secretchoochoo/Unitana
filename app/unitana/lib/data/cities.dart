/// A curated starter list (fallback) plus the shared City model.
///
/// The authoritative list is loaded from an asset via CityRepository:
///   assets/data/cities_world_v1.json
///
/// Keep this file const-friendly so the app can always boot even if the asset
/// is missing or malformed.
class City {
  final String id;
  final String cityName;

  /// ISO 3166-1 alpha-2 (e.g. US, GB, PT)
  final String countryCode;

  /// Country display name (e.g. United States, Portugal). Optional in fallback list.
  final String countryName;

  /// State/province code where applicable (e.g. CO, BC). Nullable.
  final String? admin1Code;

  /// State/province name where applicable (e.g. Colorado, British Columbia). Nullable.
  final String? admin1Name;

  /// IANA time zone ID (e.g. America/Denver, Europe/Lisbon)
  final String timeZoneId;

  /// ISO 4217 (e.g. USD, EUR)
  final String currencyCode;

  /// 'imperial' | 'metric'
  final String defaultUnitSystem;

  /// true = 24h clock
  final bool defaultUse24h;

  const City({
    required this.id,
    required this.cityName,
    required this.countryCode,
    this.countryName = '',
    this.admin1Code,
    this.admin1Name,
    required this.timeZoneId,
    required this.currencyCode,
    required this.defaultUnitSystem,
    required this.defaultUse24h,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim();
    final cityName = (json['cityName'] as String?)?.trim() ?? '';
    final countryCode = (json['countryCode'] as String?)?.trim() ?? '';

    // Reasonable fallback id if missing.
    final computedId = '${cityName.toLowerCase().replaceAll(' ', '_')}_'
        '${countryCode.toLowerCase()}';

    return City(
      id: (id == null || id.isEmpty) ? computedId : id,
      cityName: cityName,
      countryCode: countryCode,
      countryName: (json['countryName'] as String?)?.trim() ?? '',
      admin1Code: (json['admin1Code'] as String?)?.trim(),
      admin1Name: (json['admin1Name'] as String?)?.trim(),
      timeZoneId: (json['timeZoneId'] as String?)?.trim() ?? 'UTC',
      currencyCode: (json['currencyCode'] as String?)?.trim() ?? '',
      defaultUnitSystem:
          (json['defaultUnitSystem'] as String?)?.trim() ?? 'metric',
      defaultUse24h: (json['defaultUse24h'] as bool?) ?? true,
    );
  }

  String get display => '$cityName, $countryCode';
}

const List<City> kCities = [
  // USA (imperial, 12h)
  City(
    id: 'denver_us',
    cityName: 'Denver',
    countryCode: 'US',
    countryName: 'United States',
    admin1Code: 'CO',
    admin1Name: 'Colorado',
    timeZoneId: 'America/Denver',
    currencyCode: 'USD',
    defaultUnitSystem: 'imperial',
    defaultUse24h: false,
  ),
  City(
    id: 'new_york_us',
    cityName: 'New York',
    countryCode: 'US',
    countryName: 'United States',
    admin1Code: 'NY',
    admin1Name: 'New York',
    timeZoneId: 'America/New_York',
    currencyCode: 'USD',
    defaultUnitSystem: 'imperial',
    defaultUse24h: false,
  ),
  City(
    id: 'los_angeles_us',
    cityName: 'Los Angeles',
    countryCode: 'US',
    countryName: 'United States',
    admin1Code: 'CA',
    admin1Name: 'California',
    timeZoneId: 'America/Los_Angeles',
    currencyCode: 'USD',
    defaultUnitSystem: 'imperial',
    defaultUse24h: false,
  ),
  City(
    id: 'chicago_us',
    cityName: 'Chicago',
    countryCode: 'US',
    countryName: 'United States',
    admin1Code: 'IL',
    admin1Name: 'Illinois',
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
    countryName: 'Canada',
    admin1Code: 'ON',
    admin1Name: 'Ontario',
    timeZoneId: 'America/Toronto',
    currencyCode: 'CAD',
    defaultUnitSystem: 'metric',
    defaultUse24h: false,
  ),
  City(
    id: 'vancouver_ca',
    cityName: 'Vancouver',
    countryCode: 'CA',
    countryName: 'Canada',
    admin1Code: 'BC',
    admin1Name: 'British Columbia',
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
    countryName: 'Portugal',
    timeZoneId: 'Europe/Lisbon',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'porto_pt',
    cityName: 'Porto',
    countryCode: 'PT',
    countryName: 'Portugal',
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
    countryName: 'United Kingdom',
    timeZoneId: 'Europe/London',
    currencyCode: 'GBP',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
  City(
    id: 'paris_fr',
    cityName: 'Paris',
    countryCode: 'FR',
    countryName: 'France',
    timeZoneId: 'Europe/Paris',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
  ),
];
