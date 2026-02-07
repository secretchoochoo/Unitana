import '../../../data/cities.dart';
import '../../../data/city_repository.dart';
import '../../../models/place.dart';

typedef GeoPoint = ({double lat, double lon});

class PlaceGeoLookup {
  static GeoPoint? forPlace(Place? place) {
    if (place == null) return null;

    City? city = CityRepository.instance.byPlace(
      place.cityName,
      countryCode: place.countryCode,
    );
    city ??= _bestCuratedMatch(
      cityName: place.cityName,
      countryCode: place.countryCode,
    );
    if (city == null || city.lat == null || city.lon == null) return null;

    return (lat: city.lat!, lon: city.lon!);
  }

  static City? _bestCuratedMatch({
    required String cityName,
    required String countryCode,
  }) {
    final name = _norm(cityName);
    final cc = _norm(countryCode);

    for (final city in kCuratedCities) {
      if (_norm(city.cityName) == name && _norm(city.countryCode) == cc) {
        return city;
      }
    }

    for (final city in kCuratedCities) {
      if (_norm(city.cityName) == name) return city;
    }
    return null;
  }

  static String _norm(String v) =>
      v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
