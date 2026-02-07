import '../../../data/cities.dart';
import '../../../data/city_label_utils.dart';
import '../../../data/city_repository.dart';
import '../../../models/place.dart';

typedef TimeZoneOption = ({String id, String label, String? subtitle});
typedef TimeZoneCityOption = ({
  String key,
  String timeZoneId,
  String label,
  String subtitle,
  String countryCode,
});

class TimeZoneCatalog {
  static const List<String> _mainstreamHubZonePriority = <String>[
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
  static final Set<String> _mainstreamCountryCodes = <String>{
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
  static const List<String> _fallbackZones = <String>[
    'UTC',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Lisbon',
    'Europe/Paris',
    'Europe/Berlin',
    'Asia/Tokyo',
    'Asia/Kolkata',
    'Australia/Sydney',
    'Pacific/Auckland',
  ];
  static String? _cachedSourceToken;
  static List<TimeZoneOption>? _cachedBaseZoneOptions;
  static List<TimeZoneCityOption>? _cachedBaseCityOptions;

  static String _sourceToken(List<City> cities) {
    if (cities.isEmpty) return 'empty';
    return '${cities.length}:${cities.first.id}:${cities.last.id}';
  }

  static List<City> _sourceCities() {
    return CityRepository.instance.cities.isNotEmpty
        ? CityRepository.instance.cities
        : kCuratedCities;
  }

  static void _ensureCaches(List<City> sourceCities) {
    final token = _sourceToken(sourceCities);
    if (token == _cachedSourceToken &&
        _cachedBaseZoneOptions != null &&
        _cachedBaseCityOptions != null) {
      return;
    }
    _cachedSourceToken = token;
    _cachedBaseZoneOptions = _buildBaseZoneOptions(sourceCities);
    _cachedBaseCityOptions = _buildBaseCityOptions(sourceCities);
  }

  static List<TimeZoneOption> options({
    required Place? home,
    required Place? destination,
  }) {
    final sourceCities = _sourceCities();
    _ensureCaches(sourceCities);
    final baseOptions = _cachedBaseZoneOptions ?? const <TimeZoneOption>[];
    final out = <TimeZoneOption>[];
    final seen = <String>{};

    void add(String id, String label, {String? subtitle}) {
      final norm = id.trim();
      if (norm.isEmpty || !seen.add(norm)) return;
      out.add((id: norm, label: label, subtitle: subtitle));
    }

    if (home != null) {
      add(
        home.timeZoneId,
        '${home.cityName}, ${home.countryCode.toUpperCase()}',
      );
    }
    if (destination != null) {
      add(
        destination.timeZoneId,
        '${destination.cityName}, ${destination.countryCode.toUpperCase()}',
      );
    }

    for (final option in baseOptions) {
      add(option.id, option.label, subtitle: option.subtitle);
    }

    for (final zone in _fallbackZones) {
      add(zone, _friendlyFallbackLabel(zone), subtitle: zone);
    }
    add('UTC', 'UTC');
    return out;
  }

  static List<TimeZoneCityOption> cityOptions({
    required Place? home,
    required Place? destination,
  }) {
    final sourceCities = _sourceCities();
    _ensureCaches(sourceCities);
    final baseOptions = _cachedBaseCityOptions ?? const <TimeZoneCityOption>[];
    final out = <TimeZoneCityOption>[];
    final seen = <String>{};

    void add({
      required String key,
      required String zoneId,
      required String label,
      required String subtitle,
      required String countryCode,
    }) {
      final norm = key.trim().toLowerCase();
      final normZone = zoneId.trim();
      if (norm.isEmpty || normZone.isEmpty || !seen.add(norm)) return;
      out.add((
        key: norm,
        timeZoneId: normZone,
        label: label,
        subtitle: subtitle,
        countryCode: countryCode,
      ));
    }

    if (home != null) {
      add(
        key: 'home|${home.cityName}|${home.countryCode}|${home.timeZoneId}',
        zoneId: home.timeZoneId,
        label:
            '${CityLabelUtils.cleanCityName(home.cityName)}, ${home.countryCode.toUpperCase()}',
        subtitle: home.timeZoneId,
        countryCode: home.countryCode,
      );
    }
    if (destination != null) {
      add(
        key:
            'destination|${destination.cityName}|${destination.countryCode}|${destination.timeZoneId}',
        zoneId: destination.timeZoneId,
        label:
            '${CityLabelUtils.cleanCityName(destination.cityName)}, ${destination.countryCode.toUpperCase()}',
        subtitle: destination.timeZoneId,
        countryCode: destination.countryCode,
      );
    }

    for (final option in baseOptions) {
      add(
        key: option.key,
        zoneId: option.timeZoneId,
        label: option.label,
        subtitle: option.subtitle,
        countryCode: option.countryCode,
      );
    }
    return out;
  }

  static List<TimeZoneCityOption> mainstreamCityOptions({
    required Place? home,
    required Place? destination,
    int limit = 24,
  }) {
    final all = cityOptions(home: home, destination: destination);
    return mainstreamCityOptionsFromAll(
      all: all,
      home: home,
      destination: destination,
      limit: limit,
    );
  }

  static List<TimeZoneCityOption> mainstreamCityOptionsFromAll({
    required List<TimeZoneCityOption> all,
    required Place? home,
    required Place? destination,
    int limit = 24,
  }) {
    if (all.isEmpty) return const <TimeZoneCityOption>[];

    final preferredZones = <String>{
      if (home != null) home.timeZoneId,
      if (destination != null) destination.timeZoneId,
    };
    final seenZones = <String>{};
    final seenCityNames = <String>{};
    final out = <TimeZoneCityOption>[];

    bool isLowSignal(String label) {
      final clean = CityLabelUtils.cleanCityName(label).trim();
      if (clean.isEmpty) return true;
      if (RegExp(r'^[^A-Za-z0-9]').hasMatch(clean)) return true;
      if (RegExp(r'\d{2,}').hasMatch(clean)) return true;
      return false;
    }

    String cityNameToken(String label) {
      final clean = CityLabelUtils.cleanCityName(label).toLowerCase();
      return clean.split(',').first.trim();
    }

    void add(TimeZoneCityOption option, {bool allowDuplicateCity = false}) {
      if (!seenZones.add(option.timeZoneId)) return;
      final token = cityNameToken(option.label);
      if (!allowDuplicateCity &&
          token.isNotEmpty &&
          !seenCityNames.add(token)) {
        return;
      }
      if (allowDuplicateCity && token.isNotEmpty) {
        seenCityNames.add(token);
      }
      out.add(option);
    }

    // Keep seeded profile zones first so defaults remain context-aware.
    for (final option in all) {
      if (preferredZones.contains(option.timeZoneId)) {
        add(option, allowDuplicateCity: true);
      }
    }

    // `all` is already base-ranked and de-duped by source; keep iteration
    // linear to avoid expensive full-list resorting on every picker open.
    for (final option in all) {
      if (out.length >= limit) break;
      if (preferredZones.contains(option.timeZoneId)) continue;
      if (isLowSignal(option.label)) continue;
      add(option);
    }

    if (out.length < limit) {
      for (final option in all) {
        if (out.length >= limit) break;
        add(option);
      }
    }

    return out;
  }

  static List<TimeZoneOption> _buildBaseZoneOptions(List<City> sourceCities) {
    final byZone = <String, City>{};
    for (final city in sourceCities) {
      final zone = city.timeZoneId.trim();
      if (zone.isEmpty) continue;
      byZone.putIfAbsent(zone, () => city);
    }
    final sortedZones = byZone.keys.toList()..sort();
    return sortedZones
        .map((zone) {
          final city = byZone[zone]!;
          return (
            id: zone,
            label: '${city.cityName}, ${_cityCountryLabel(city)}',
            subtitle: zone,
          );
        })
        .toList(growable: false);
  }

  static List<TimeZoneCityOption> _buildBaseCityOptions(
    List<City> sourceCities,
  ) {
    final curatedZoneIds = kCuratedCities.map((c) => c.timeZoneId).toSet();
    final sorted = sourceCities.toList(growable: false)
      ..sort((a, b) {
        final scoreA = _catalogScore(city: a, curatedZoneIds: curatedZoneIds);
        final scoreB = _catalogScore(city: b, curatedZoneIds: curatedZoneIds);
        if (scoreA != scoreB) return scoreB.compareTo(scoreA);
        final city = a.cityName.toLowerCase().compareTo(
          b.cityName.toLowerCase(),
        );
        if (city != 0) return city;
        final country = _cityCountryLabel(
          a,
        ).toLowerCase().compareTo(_cityCountryLabel(b).toLowerCase());
        if (country != 0) return country;
        return a.timeZoneId.toLowerCase().compareTo(b.timeZoneId.toLowerCase());
      });
    return sorted
        .map(
          (city) => (
            key: '${city.cityName}|${city.countryCode}|${city.timeZoneId}'
                .toLowerCase(),
            timeZoneId: city.timeZoneId.trim(),
            label:
                '${CityLabelUtils.cleanCityName(city.cityName)}, ${_cityCountryLabel(city)}',
            subtitle: city.timeZoneId,
            countryCode: city.countryCode,
          ),
        )
        .toList(growable: false);
  }

  static String _cityCountryLabel(City city) {
    return CityLabelUtils.cleanCountryLabel(city);
  }

  static String _friendlyFallbackLabel(String zone) {
    if (zone == 'UTC') return 'UTC';
    final pieces = zone.split('/');
    final tail = pieces.isEmpty ? zone : pieces.last.replaceAll('_', ' ');
    return '$tail ($zone)';
  }

  static int _catalogScore({
    required City city,
    required Set<String> curatedZoneIds,
  }) {
    var score = 0;
    if (curatedZoneIds.contains(city.timeZoneId)) score += 240;
    final hubIndex = _mainstreamHubZonePriority.indexOf(city.timeZoneId);
    if (hubIndex != -1) score += 220 - (hubIndex * 6);
    if (_mainstreamCountryCodes.contains(city.countryCode.toUpperCase())) {
      score += 70;
    }
    final clean = CityLabelUtils.cleanCityName(city.cityName);
    if (RegExp(r'^[^A-Za-z0-9]').hasMatch(clean)) score -= 220;
    if (RegExp(r'\d').hasMatch(clean)) score -= 50;
    score -= clean.length ~/ 4;
    return score;
  }
}
