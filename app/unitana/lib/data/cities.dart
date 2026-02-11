// City dataset + curated lists used by the city picker and onboarding.
//
// Source of truth is the JSON asset (cities_v1.json) loaded by CityRepository.
// This file defines the City model plus a small curated list for UX defaults
// (popular/quick picks).

import 'dart:math' as math;

import 'city_schema_validator.dart';

/// Currency symbols used for display.
///
/// We intentionally display both symbol and ISO code (e.g. "$ USD")
/// to avoid ambiguity across currencies that share the same symbol.
const Map<String, String> kCurrencySymbols = {
  'USD': r'$',
  'EUR': '€',
  'GBP': '£',
  'JPY': '¥',
  'CNY': '¥',
  'KRW': '₩',
  'INR': '₹',
  'CAD': r'$',
  'AUD': r'$',
  'NZD': r'$',
  'CHF': 'CHF',
  'SEK': 'kr',
  'NOK': 'kr',
  'DKK': 'kr',
  'PLN': 'zł',
  'CZK': 'Kč',
  'HUF': 'Ft',
  'RON': 'lei',
  'BGN': 'лв',
  'TRY': '₺',
  'RUB': '₽',
  'UAH': '₴',
  'BRL': r'R$',
  'MXN': r'$',
  'ARS': r'$',
  'CLP': r'$',
  'COP': r'$',
  'PEN': 'S/',
  'ZAR': 'R',
  'ILS': '₪',
  'SAR': '﷼',
  'AED': 'د.إ',
  'QAR': '﷼',
  'KWD': 'د.ك',
  'EGP': '£',
  'NGN': '₦',
  'KES': 'KSh',
  'GHS': '₵',
  'ETB': 'Br',
  'MAD': 'د.م.',
  'TND': 'د.ت',
  'DZD': 'د.ج',
  'XOF': 'CFA',
  'XAF': 'CFA',
  'BDT': '৳',
  'PKR': '₨',
  'LKR': '₨',
  'NPR': '₨',
  'THB': '฿',
  'VND': '₫',
  'IDR': 'Rp',
  'MYR': 'RM',
  'SGD': r'$',
  'HKD': r'$',
  'TWD': r'$',
  'PHP': '₱',
  'ISK': 'kr',
  'IRR': '﷼',
  'IQD': 'ع.د',
  'JOD': 'د.ا',
  'OMR': '﷼',
  'BHD': 'ب.د',
};

class City {
  final String id;
  final String cityName;
  final String countryCode;
  final String timeZoneId;
  final String currencyCode;

  // Optional administrative / enrichment fields (may be absent in JSON).
  final String? admin1Code;
  final String? admin1Name;
  final String? countryName;
  final String? iso3;
  final String? continent;

  // Optional “defaults” (if absent, we infer from country).
  final String? _defaultUnitSystem;
  final bool? _defaultUse24h;

  // Optional coordinates (for ranking / future proximity features).
  final double? lat;
  final double? lon;

  const City({
    required this.id,
    required this.cityName,
    required this.countryCode,
    required this.timeZoneId,
    required this.currencyCode,
    this.admin1Code,
    this.admin1Name,
    this.countryName,
    this.iso3,
    this.continent,
    String? defaultUnitSystem,
    bool? defaultUse24h,
    this.lat,
    this.lon,
  }) : _defaultUnitSystem = defaultUnitSystem,
       _defaultUse24h = defaultUse24h;

  /// e.g. "Denver, CO, US" / "Lisbon, PT"
  String get display => primaryLabel;

  /// Display label used in lists. Example: "Denver, CO, US" or "Lisbon, PT".
  String get primaryLabel {
    final cc = countryCode.toUpperCase();
    final adminName = (admin1Name ?? '').trim();
    if (adminName.isNotEmpty) return '$cityName, $adminName, $cc';

    final adminCode = (admin1Code ?? '').trim();
    if (adminCode.isEmpty) return '$cityName, $cc';

    // GeoNames admin1 codes are frequently numeric IDs ("17", "01", ...).
    // Keep user-facing labels readable by suppressing numeric codes.
    final numericOnly = RegExp(r'^\d+$').hasMatch(adminCode);
    if (numericOnly) return '$cityName, $cc';

    return '$cityName, $adminCode, $cc';
  }

  /// Secondary label used in lists. Example: "America/Denver · $ USD"
  String get secondaryLabel => '$timeZoneId · $currencyLabel';

  String get countryLabel => countryCode.toUpperCase();

  String get currencyLabel {
    final code = currencyCode.trim().toUpperCase();
    final sym = kCurrencySymbols[code] ?? '';
    if (sym.isEmpty) return code;
    return '$sym $code';
  }

  /// Currency symbol variants; best-effort based on currencyCode.
  String? get currencySymbol {
    final code = currencyCode.trim().toUpperCase();
    return kCurrencySymbols[code];
  }

  String? get currencySymbolNarrow => currencySymbol;
  String? get currencySymbolNative => currencySymbol;

  /// Onboarding defaults. If the dataset provides defaults, use them.
  /// Otherwise infer from country.
  String get defaultUnitSystem {
    final v = _defaultUnitSystem;
    if (v != null && v.isNotEmpty) return v;

    final cc = countryCode.toUpperCase();
    // US + common holdouts.
    if (cc == 'US' || cc == 'LR' || cc == 'MM') return 'imperial';
    return 'metric';
  }

  bool get defaultUse24h {
    final v = _defaultUse24h;
    if (v != null) return v;

    final cc = countryCode.toUpperCase();
    // US defaults 12h; most others 24h for onboarding.
    if (cc == 'US') return false;
    return true;
  }

  factory City.fromJson(Map<String, dynamic> json) {
    final errors = CitySchemaValidator.validateRecord(json);
    if (errors.isNotEmpty) {
      final id = (json['id'] ?? 'unknown-id').toString();
      throw FormatException('Invalid city record ($id): ${errors.join(', ')}');
    }
    return City(
      id: json['id'].toString().trim(),
      cityName: json['cityName'].toString().trim().replaceAll('_', ' '),
      countryCode: json['countryCode'].toString().trim(),
      timeZoneId: json['timeZoneId'].toString().trim(),
      currencyCode: json['currencyCode'].toString().trim(),
      admin1Code: json['admin1Code']?.toString(),
      admin1Name: json['admin1Name']?.toString(),
      countryName: json['countryName']?.toString(),
      iso3: json['iso3']?.toString(),
      continent: json['continent']?.toString(),
      defaultUnitSystem: json['defaultUnitSystem']?.toString(),
      defaultUse24h: json['defaultUse24h'] as bool,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cityName': cityName,
    'countryCode': countryCode,
    'timeZoneId': timeZoneId,
    'currencyCode': currencyCode,
    'admin1Code': admin1Code,
    'admin1Name': admin1Name,
    'countryName': countryName,
    'iso3': iso3,
    'continent': continent,
    'defaultUnitSystem': _defaultUnitSystem,
    'defaultUse24h': _defaultUse24h,
    'lat': lat,
    'lon': lon,
  };

  /// Rough distance helper for ranking (optional use).
  double distanceTo(double? otherLat, double? otherLon) {
    if (lat == null || lon == null || otherLat == null || otherLon == null) {
      return double.infinity;
    }
    final dLat = (otherLat - lat!) * math.pi / 180.0;
    final dLon = (otherLon - lon!) * math.pi / 180.0;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat! * math.pi / 180.0) *
            math.cos(otherLat * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    const earthRadiusKm = 6371.0;
    return earthRadiusKm * c;
  }
}

/// Small, curated list used for onboarding defaults and “quick picks”.
///
/// This should remain small and intentionally “world-spanning”.
const List<City> kCuratedCities = [
  City(
    id: 'denver_us',
    cityName: 'Denver',
    countryCode: 'US',
    timeZoneId: 'America/Denver',
    currencyCode: 'USD',
    defaultUnitSystem: 'imperial',
    defaultUse24h: false,
    admin1Code: 'CO',
    admin1Name: 'Colorado',
    countryName: 'United States',
    iso3: 'USA',
    continent: 'NA',
    lat: 39.7392,
    lon: -104.9903,
  ),
  City(
    id: 'new_york_us',
    cityName: 'New York',
    countryCode: 'US',
    timeZoneId: 'America/New_York',
    currencyCode: 'USD',
    defaultUnitSystem: 'imperial',
    defaultUse24h: false,
    admin1Code: 'NY',
    admin1Name: 'New York',
    countryName: 'United States',
    iso3: 'USA',
    continent: 'NA',
    lat: 40.71427,
    lon: -74.00597,
  ),
  City(
    id: 'los_angeles_us',
    cityName: 'Los Angeles',
    countryCode: 'US',
    timeZoneId: 'America/Los_Angeles',
    currencyCode: 'USD',
    defaultUnitSystem: 'imperial',
    defaultUse24h: false,
    admin1Code: 'CA',
    admin1Name: 'California',
    countryName: 'United States',
    iso3: 'USA',
    continent: 'NA',
    lat: 34.05223,
    lon: -118.24368,
  ),
  City(
    id: 'chicago_us',
    cityName: 'Chicago',
    countryCode: 'US',
    timeZoneId: 'America/Chicago',
    currencyCode: 'USD',
    defaultUnitSystem: 'imperial',
    defaultUse24h: false,
    admin1Code: 'IL',
    admin1Name: 'Illinois',
    countryName: 'United States',
    iso3: 'USA',
    continent: 'NA',
    lat: 41.85003,
    lon: -87.65005,
  ),
  City(
    id: 'miami_us',
    cityName: 'Miami',
    countryCode: 'US',
    timeZoneId: 'America/New_York',
    currencyCode: 'USD',
    defaultUnitSystem: 'imperial',
    defaultUse24h: false,
    admin1Code: 'FL',
    admin1Name: 'Florida',
    countryName: 'United States',
    iso3: 'USA',
    continent: 'NA',
    lat: 25.77427,
    lon: -80.19366,
  ),
  City(
    id: 'toronto_ca',
    cityName: 'Toronto',
    countryCode: 'CA',
    timeZoneId: 'America/Toronto',
    currencyCode: 'CAD',
    defaultUnitSystem: 'metric',
    defaultUse24h: false,
    admin1Code: 'ON',
    admin1Name: 'Ontario',
    countryName: 'Canada',
    iso3: 'CAN',
    continent: 'NA',
    lat: 43.70011,
    lon: -79.4163,
  ),
  City(
    id: 'vancouver_ca',
    cityName: 'Vancouver',
    countryCode: 'CA',
    timeZoneId: 'America/Vancouver',
    currencyCode: 'CAD',
    defaultUnitSystem: 'metric',
    defaultUse24h: false,
    admin1Code: 'BC',
    admin1Name: 'British Columbia',
    countryName: 'Canada',
    iso3: 'CAN',
    continent: 'NA',
    lat: 49.24966,
    lon: -123.11934,
  ),
  City(
    id: 'london_gb',
    cityName: 'London',
    countryCode: 'GB',
    timeZoneId: 'Europe/London',
    currencyCode: 'GBP',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
    countryName: 'United Kingdom',
    iso3: 'GBR',
    continent: 'EU',
    lat: 51.50853,
    lon: -0.12574,
  ),
  City(
    id: 'lisbon_pt',
    cityName: 'Lisbon',
    countryCode: 'PT',
    timeZoneId: 'Europe/Lisbon',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
    countryName: 'Portugal',
    iso3: 'PRT',
    continent: 'EU',
    // Coordinates required for Open-Meteo live weather.
    lat: 38.7223,
    lon: -9.1393,
  ),
  City(
    id: 'porto_pt',
    cityName: 'Porto',
    countryCode: 'PT',
    timeZoneId: 'Europe/Lisbon',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
    countryName: 'Portugal',
    iso3: 'PRT',
    continent: 'EU',
    // Coordinates required for Open-Meteo live weather.
    lat: 41.1579,
    lon: -8.6291,
  ),
  City(
    id: 'amsterdam_nl',
    cityName: 'Amsterdam',
    countryCode: 'NL',
    timeZoneId: 'Europe/Amsterdam',
    currencyCode: 'EUR',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
    countryName: 'Netherlands',
    iso3: 'NLD',
    continent: 'EU',
    lat: 52.37403,
    lon: 4.88969,
  ),
  City(
    id: 'tokyo_jp',
    cityName: 'Tokyo',
    countryCode: 'JP',
    timeZoneId: 'Asia/Tokyo',
    currencyCode: 'JPY',
    defaultUnitSystem: 'metric',
    defaultUse24h: true,
    countryName: 'Japan',
    iso3: 'JPN',
    continent: 'AS',
    lat: 35.6895,
    lon: 139.69171,
  ),
];

/// Backwards-compatible alias.
const List<City> kCities = kCuratedCities;
