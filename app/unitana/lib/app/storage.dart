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
  static const String _kPreferredLanguageCode = 'preferred_language_code_v1';
  static const String _kPreferredThemeMode = 'preferred_theme_mode_v1';
  static const String _kAutoProfileSuggestEnabled =
      'auto_profile_suggest_enabled_v1';
  static const String _kAutoProfileSuggestReason =
      'auto_profile_suggest_reason_v1';
  static const String _kAutoProfileSuggestProfileId =
      'auto_profile_suggest_profile_id_v1';
  static const String _kProfileLastActivatedAtById =
      'profile_last_activated_at_by_id_v1';

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

  Future<String?> loadPreferredLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPreferredLanguageCode);
  }

  Future<void> savePreferredLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPreferredLanguageCode, code);
  }

  Future<String?> loadPreferredThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPreferredThemeMode);
  }

  Future<void> savePreferredThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPreferredThemeMode, mode);
  }

  Future<bool> loadAutoProfileSuggestEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoProfileSuggestEnabled) ?? false;
  }

  Future<void> saveAutoProfileSuggestEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoProfileSuggestEnabled, enabled);
  }

  Future<String?> loadAutoProfileSuggestReason() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAutoProfileSuggestReason);
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.trim();
  }

  Future<void> saveAutoProfileSuggestReason(String? reason) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = reason?.trim();
    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(_kAutoProfileSuggestReason);
      return;
    }
    await prefs.setString(_kAutoProfileSuggestReason, normalized);
  }

  Future<String?> loadAutoProfileSuggestProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAutoProfileSuggestProfileId);
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.trim();
  }

  Future<void> saveAutoProfileSuggestProfileId(String? profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = profileId?.trim();
    if (normalized == null || normalized.isEmpty) {
      await prefs.remove(_kAutoProfileSuggestProfileId);
      return;
    }
    await prefs.setString(_kAutoProfileSuggestProfileId, normalized);
  }

  Future<Map<String, int>> loadProfileLastActivatedAtById() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProfileLastActivatedAtById);
    if (raw == null || raw.trim().isEmpty) return const <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, int>{};
      final out = <String, int>{};
      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String) continue;
        if (value is int) {
          out[key.trim()] = value;
        } else if (value is num) {
          out[key.trim()] = value.toInt();
        }
      }
      return out;
    } catch (_) {
      return const <String, int>{};
    }
  }

  Future<void> saveProfileLastActivatedAtById(Map<String, int> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileLastActivatedAtById, jsonEncode(values));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPlaces);
    await prefs.remove(_kDefaultPlaceId);
    await prefs.remove(_kProfileName);
    await prefs.remove(_kProfiles);
    await prefs.remove(_kActiveProfileId);
    await prefs.remove(_kPreferredLanguageCode);
    await prefs.remove(_kPreferredThemeMode);
    await prefs.remove(_kAutoProfileSuggestEnabled);
    await prefs.remove(_kAutoProfileSuggestReason);
    await prefs.remove(_kAutoProfileSuggestProfileId);
    await prefs.remove(_kProfileLastActivatedAtById);
  }
}
