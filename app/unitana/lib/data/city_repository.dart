import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'cities.dart';

/// Loads the city dataset from assets and caches it in memory.
///
/// Primary source: assets/data/cities_v1.json
/// Fallback: [kCuratedCities] (small built-in list)
class CityRepository {
  CityRepository._();

  static final CityRepository instance = CityRepository._();

  static const String assetPath = 'assets/data/cities_v1.json';

  List<City> _cities = const [];
  Map<String, City> _byId = const {};
  bool _loaded = false;

  /// Clears in-memory caches.
  ///
  /// Storage reset clears SharedPreferences. This method covers the remaining
  /// in-process cache so that developer resets feel like a fresh install.
  void resetCache() {
    _cities = const [];
    _byId = const {};
    _loaded = false;
  }

  Future<List<City>> load() async {
    if (_loaded) return _cities;

    List<City> loaded;
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = json.decode(raw);

      final List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic> && decoded['cities'] is List) {
        list = decoded['cities'] as List;
      } else {
        list = const [];
      }

      loaded = list
          .whereType<Map>()
          .map((m) => City.fromJson(Map<String, dynamic>.from(m)))
          .where((c) => c.id.isNotEmpty && c.cityName.isNotEmpty)
          .toList(growable: false);

      if (loaded.isEmpty) {
        loaded = kCuratedCities;
      }
    } catch (_) {
      loaded = kCuratedCities;
    }

    _cities = loaded;
    _byId = {for (final c in loaded) c.id: c};
    _loaded = true;
    return _cities;
  }

  List<City> get cities => _cities;

  City? byId(String id) => _byId[id];

  /// Best-effort match for a stored place.
  ///
  /// This is intentionally forgiving: we normalize case/whitespace and then
  /// match city name, and optionally country/admin.
  City? byPlace(String cityName, {String? countryCode, String? admin1Code}) {
    if (!_loaded || _cities.isEmpty) return null;

    final nameN = _norm(cityName);
    final ccN = countryCode == null ? null : _norm(countryCode);
    final a1N = admin1Code == null ? null : _norm(admin1Code);

    City? best;
    for (final c in _cities) {
      if (_norm(c.cityName) != nameN) continue;
      if (ccN != null && _norm(c.countryCode) != ccN) continue;
      if (a1N != null && _norm(c.admin1Code ?? '') != a1N) continue;
      best = c;
      break;
    }

    // City data contract requires lat/lon for all records. Keep this
    // fallback as a resilience path in case a malformed or stale dataset slips
    // through in local/dev environments.
    if (best != null && (best.lat == null || best.lon == null)) {
      City? curated;
      for (final c in kCuratedCities) {
        if (_norm(c.cityName) != nameN) continue;
        if (ccN != null && _norm(c.countryCode) != ccN) continue;
        if (a1N != null && _norm(c.admin1Code ?? '') != a1N) continue;
        if (c.lat == null || c.lon == null) continue;
        curated = c;
        break;
      }
      if (curated != null) return curated;
    }

    return best;
  }

  static String _norm(String input) {
    final folded = _foldDiacritics(input).toLowerCase().trim();
    return folded.replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _foldDiacritics(String input) {
    var s = input;
    const map = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'À': 'A',
      'Á': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'Å': 'A',
      'Ç': 'C',
      'È': 'E',
      'É': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Ì': 'I',
      'Í': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ñ': 'N',
      'Ò': 'O',
      'Ó': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'Ù': 'U',
      'Ú': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ý': 'Y',
    };

    map.forEach((k, v) {
      s = s.replaceAll(k, v);
    });
    return s;
  }
}
