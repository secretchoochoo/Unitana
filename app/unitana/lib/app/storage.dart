import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';

class UnitanaStorage {
  static const String _kPlaces = 'places_v1';
  static const String _kDefaultPlaceId = 'default_place_id_v1';
  static const String _kProfileName = 'profile_name_v1';

  // Multi-profile storage.
  static const String _kProfiles = 'profiles_v1';
  static const String _kActiveProfileId = 'active_profile_id_v1';

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

  Future<List<UnitanaProfile>> loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProfiles);
    if (raw == null || raw.trim().isEmpty) return <UnitanaProfile>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <UnitanaProfile>[];
      final out = <UnitanaProfile>[];
      for (final entry in decoded) {
        final p = UnitanaProfile.fromJson(entry);
        if (p != null) out.add(p);
      }
      return out;
    } catch (_) {
      return <UnitanaProfile>[];
    }
  }

  Future<void> saveProfiles(List<UnitanaProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_kProfiles, raw);
  }

  Future<String?> loadActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kActiveProfileId);
  }

  Future<void> saveActiveProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kActiveProfileId, id);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPlaces);
    await prefs.remove(_kDefaultPlaceId);
    await prefs.remove(_kProfileName);
    await prefs.remove(_kProfiles);
    await prefs.remove(_kActiveProfileId);
  }
}
