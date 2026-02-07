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

  static List<TimeZoneOption> options({
    required Place? home,
    required Place? destination,
  }) {
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
        'Home · ${home.cityName}, ${home.countryCode.toUpperCase()}',
      );
    }
    if (destination != null) {
      add(
        destination.timeZoneId,
        'Destination · ${destination.cityName}, ${destination.countryCode.toUpperCase()}',
      );
    }

    final sourceCities = CityRepository.instance.cities.isNotEmpty
        ? CityRepository.instance.cities
        : kCuratedCities;
    final byZone = <String, City>{};
    for (final city in sourceCities) {
      final zone = city.timeZoneId.trim();
      if (zone.isEmpty) continue;
      byZone.putIfAbsent(zone, () => city);
    }
    final sortedZones = byZone.keys.toList()..sort();
    for (final zone in sortedZones) {
      final city = byZone[zone]!;
      add(zone, '${city.cityName}, ${_cityCountryLabel(city)}', subtitle: zone);
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
        subtitle: 'Home',
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
        subtitle: 'Destination',
        countryCode: destination.countryCode,
      );
    }

    final sourceCities = CityRepository.instance.cities.isNotEmpty
        ? CityRepository.instance.cities
        : kCuratedCities;
    final sorted = sourceCities.toList(growable: false)
      ..sort((a, b) {
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
    for (final city in sorted) {
      add(
        key: '${city.cityName}|${city.countryCode}|${city.timeZoneId}',
        zoneId: city.timeZoneId,
        label:
            '${CityLabelUtils.cleanCityName(city.cityName)}, ${_cityCountryLabel(city)}',
        subtitle: city.timeZoneId,
        countryCode: city.countryCode,
      );
    }
    return out;
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
}
