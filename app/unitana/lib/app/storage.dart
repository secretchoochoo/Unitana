import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';

class UnitanaStorage {
  static const _placesKey = 'places_v1';
  static const _defaultPlaceIdKey = 'default_place_id_v1';
  static const _lastUpdatedKey = 'last_updated_v1';

  Future<List<Place>> loadPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_placesKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> savePlaces(List<Place> places) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(places.map((p) => p.toJson()).toList());
    await prefs.setString(_placesKey, encoded);
    await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
  }

  Future<String?> loadDefaultPlaceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultPlaceIdKey);
  }

  Future<void> saveDefaultPlaceId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultPlaceIdKey, id);
  }

  Future<DateTime?> loadLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastUpdatedKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}

