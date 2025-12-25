import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';

class UnitanaStorage {
  static const String _kPlaces = 'places_v1';
  static const String _kDefaultPlaceId = 'default_place_id_v1';
  static const String _kProfileName = 'profile_name_v1';

  Future<List<Place>> loadPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPlaces);
    if (raw == null || raw.trim().isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePlaces(List<Place> places) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(places.map((p) => p.toJson()).toList());
    await prefs.setString(_kPlaces, raw);
  }

  Future<String?> loadDefaultPlaceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDefaultPlaceId);
  }

  Future<void> saveDefaultPlaceId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefaultPlaceId, id);
  }

  Future<String?> loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kProfileName);
  }

  Future<void> saveProfileName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileName, name);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPlaces);
    await prefs.remove(_kDefaultPlaceId);
    await prefs.remove(_kProfileName);
  }
}
