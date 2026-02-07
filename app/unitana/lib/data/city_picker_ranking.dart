/// Shared mainstream ranking heuristics used by city-picker surfaces.
class CityPickerRanking {
  static const List<String> mainstreamHubZonePriority = <String>[
    'America/New_York',
    'America/Los_Angeles',
    'America/Chicago',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Madrid',
    'Asia/Tokyo',
    'Asia/Singapore',
    'Asia/Hong_Kong',
    'Asia/Seoul',
    'Asia/Kolkata',
    'Australia/Sydney',
    'America/Toronto',
    'America/Vancouver',
    'America/Mexico_City',
    'America/Sao_Paulo',
    'Pacific/Auckland',
    'UTC',
  ];

  static final Set<String> mainstreamCountryCodes = <String>{
    'US',
    'GB',
    'FR',
    'DE',
    'ES',
    'IT',
    'JP',
    'SG',
    'HK',
    'KR',
    'IN',
    'CA',
    'AU',
    'NZ',
    'MX',
    'BR',
  };

  static int hubPriorityBonus(String timeZoneId) {
    final hubIndex = mainstreamHubZonePriority.indexOf(timeZoneId);
    if (hubIndex == -1) return 0;
    return 220 - (hubIndex * 6);
  }

  static bool isMainstreamCountryCode(String countryCode) {
    return mainstreamCountryCodes.contains(countryCode.toUpperCase());
  }

  static const Map<String, String> _preferredZoneByCityCountry =
      <String, String>{
        // Ambiguity v3: prefer mainstream travel-default rows for same-city
        // same-country collisions where multiple zones exist in data.
        'portland|US': 'America/Los_Angeles',
      };

  static int exactCityDisambiguationBonus({
    required String cityNameNorm,
    required String countryCode,
    required String timeZoneId,
  }) {
    final key = '${cityNameNorm.toLowerCase()}|${countryCode.toUpperCase()}';
    final preferredZone = _preferredZoneByCityCountry[key];
    if (preferredZone == null) return 0;
    return timeZoneId == preferredZone ? 160 : -45;
  }
}
