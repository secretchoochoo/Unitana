import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:unitana/data/cities.dart';

class CityRepository {
  CityRepository._();

  static List<City>? _cache;

  /// Loads the authoritative city list from assets, with a safe fallback to kCities.
  ///
  /// Asset path:
  ///   assets/data/cities_world_v1.json
  static Future<List<City>> loadCities() async {
    final cached = _cache;
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final raw = await rootBundle.loadString('assets/data/cities_world_v1.json');
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        final cities = decoded
            .whereType<Map<String, dynamic>>()
            .map(City.fromJson)
            .toList(growable: false);

        if (cities.isNotEmpty) {
          final sorted = List<City>.from(cities)
            ..sort((a, b) => a.display.toLowerCase().compareTo(b.display.toLowerCase()));
          _cache = sorted;
          return sorted;
        }
      }
    } catch (_) {
      // Fall through to fallback.
    }

    final fallback = List<City>.from(kCities)
      ..sort((a, b) => a.display.toLowerCase().compareTo(b.display.toLowerCase()));
    _cache = fallback;
    return fallback;
  }

  /// For dev or testing: clears the cache so a fresh load occurs.
  static void clearCache() {
    _cache = null;
  }
}

