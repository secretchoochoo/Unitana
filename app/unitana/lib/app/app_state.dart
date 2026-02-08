import 'package:flutter/material.dart';

import '../models/place.dart';
import 'storage.dart';

class UnitanaAppState extends ChangeNotifier {
  final UnitanaStorage storage;

  // Multi-profile support.
  //
  // Each profile stores its own places + default place + display name.
  // We keep legacy single-profile fields as computed views over the active profile.
  List<UnitanaProfile> _profiles = <UnitanaProfile>[];
  String _activeProfileId = 'profile_1';
  String? _pendingSuccessToast;
  String _preferredLanguageCode = 'system';

  UnitanaAppState(this.storage);

  List<UnitanaProfile> get profiles =>
      List<UnitanaProfile>.unmodifiable(_profiles);

  String get activeProfileId => _activeProfileId;
  String get preferredLanguageCode => _preferredLanguageCode;
  Locale? get appLocale {
    switch (_preferredLanguageCode) {
      case 'en':
        return const Locale('en');
      case 'es':
        return const Locale('es');
      default:
        return null;
    }
  }

  UnitanaProfile get activeProfile {
    final idx = _profiles.indexWhere((p) => p.id == _activeProfileId);
    if (idx >= 0) return _profiles[idx];
    if (_profiles.isNotEmpty) return _profiles.first;
    // Shouldn't happen after load, but keep a sane fallback.
    return const UnitanaProfile(
      id: 'profile_1',
      name: 'My Places',
      places: <Place>[],
      defaultPlaceId: null,
    );
  }

  bool _profileIsSetupComplete(UnitanaProfile profile) {
    final places = profile.places;
    final hasLiving = places.any((p) => p.type == PlaceType.living);
    final hasVisiting = places.any((p) => p.type == PlaceType.visiting);
    return hasLiving && hasVisiting;
  }

  bool get isActiveProfileSetupComplete =>
      _profileIsSetupComplete(activeProfile);

  bool get hasAnySetupCompleteProfile => _profiles.any(_profileIsSetupComplete);

  // Namespacing token for per-profile persisted settings.
  String get activePrefsNamespace => _activeProfileId;

  // Legacy compatibility views (active profile only).
  List<Place> get places => activeProfile.places;
  set places(List<Place> value) {
    _updateActiveProfile(
      activeProfile.copyWith(places: List<Place>.from(value)),
    );
    notifyListeners();
  }

  String? get defaultPlaceId => activeProfile.defaultPlaceId;
  set defaultPlaceId(String? value) {
    _updateActiveProfile(activeProfile.copyWith(defaultPlaceId: value));
    notifyListeners();
  }

  String get profileName => activeProfile.name;
  set profileName(String value) {
    final normalized = value.trim().isEmpty ? 'My Places' : value.trim();
    _updateActiveProfile(activeProfile.copyWith(name: normalized));
    notifyListeners();
  }

  Place? get defaultPlace {
    final id = defaultPlaceId;
    final ps = places;
    if (ps.isEmpty) return null;
    if (id == null) return ps.first;
    final idx = ps.indexWhere((p) => p.id == id);
    return idx >= 0 ? ps[idx] : ps.first;
  }

  Future<void> load() async {
    final preferredLanguageRaw = await storage.loadPreferredLanguageCode();
    _preferredLanguageCode = _normalizeLanguageCode(preferredLanguageRaw);

    final loadedProfiles = await storage.loadProfiles();
    final loadedActiveId = await storage.loadActiveProfileId();

    if (loadedProfiles.isNotEmpty) {
      _profiles = loadedProfiles;
      _activeProfileId =
          (loadedActiveId != null &&
              loadedProfiles.any((p) => p.id == loadedActiveId))
          ? loadedActiveId
          : loadedProfiles.first.id;

      // Recovery guard: if the active profile is an incomplete draft but at
      // least one complete profile exists, reactivate a complete profile so
      // app boot does not force onboarding for returning users.
      if (!isActiveProfileSetupComplete) {
        UnitanaProfile? fallback;
        for (final profile in _profiles) {
          if (_profileIsSetupComplete(profile)) {
            fallback = profile;
            break;
          }
        }
        if (fallback != null) {
          _activeProfileId = fallback.id;
          await storage.saveActiveProfileId(_activeProfileId);
        }
      }

      // Keep legacy keys in sync with the active profile for older flows.
      await _persistLegacyActive();
      notifyListeners();
      return;
    }

    // Migration path: build profile_1 from legacy single-profile keys.
    final legacyPlaces = await storage.loadPlaces();
    final legacyDefaultId = await storage.loadDefaultPlaceId();
    final legacyName = await storage.loadProfileName();

    final profile = UnitanaProfile(
      id: 'profile_1',
      name: (legacyName != null && legacyName.trim().isNotEmpty)
          ? legacyName.trim()
          : 'My Places',
      places: legacyPlaces,
      defaultPlaceId: legacyDefaultId,
    );

    _profiles = <UnitanaProfile>[profile];
    _activeProfileId = profile.id;

    await storage.saveProfiles(_profiles);
    await storage.saveActiveProfileId(_activeProfileId);
    await _persistLegacyActive();

    notifyListeners();
  }

  Future<void> _persistLegacyActive() async {
    // These writes keep older tests/builds and transitional code paths stable.
    final p = activeProfile;
    await storage.saveProfileName(p.name);
    await storage.savePlaces(p.places);
    final defaultId = p.defaultPlaceId;
    if (defaultId != null && defaultId.trim().isNotEmpty) {
      await storage.saveDefaultPlaceId(defaultId);
    }
  }

  Future<void> _persistProfiles() async {
    await storage.saveProfiles(_profiles);
    await storage.saveActiveProfileId(_activeProfileId);
    await _persistLegacyActive();
  }

  Future<void> setPreferredLanguageCode(String code) async {
    final normalized = _normalizeLanguageCode(code);
    if (_preferredLanguageCode == normalized) return;
    _preferredLanguageCode = normalized;
    await storage.savePreferredLanguageCode(normalized);
    notifyListeners();
  }

  Future<void> switchToProfile(String id) async {
    if (id.trim().isEmpty) return;
    if (_activeProfileId == id) return;
    if (!_profiles.any((p) => p.id == id)) return;
    _activeProfileId = id;
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> setProfileName(String name) async {
    final v = name.trim().isEmpty ? 'My Places' : name.trim();
    _updateActiveProfile(activeProfile.copyWith(name: v));
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> overwritePlaces({
    required List<Place> newPlaces,
    required String defaultId,
  }) async {
    _updateActiveProfile(
      activeProfile.copyWith(places: newPlaces, defaultPlaceId: defaultId),
    );
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> addOrReplacePlace(Place place) async {
    final ps = List<Place>.from(activeProfile.places);
    final idx = ps.indexWhere((p) => p.id == place.id);
    if (idx >= 0) {
      ps[idx] = place;
    } else {
      ps.add(place);
    }
    _updateActiveProfile(activeProfile.copyWith(places: ps));
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> setDefaultPlaceId(String id) async {
    _updateActiveProfile(activeProfile.copyWith(defaultPlaceId: id));
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> createProfile(UnitanaProfile profile) async {
    final id = profile.id.trim();
    if (id.isEmpty) return;
    if (_profiles.any((p) => p.id == id)) return;

    _profiles = <UnitanaProfile>[..._profiles, profile];
    _activeProfileId = id;
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> updateProfile(UnitanaProfile profile) async {
    final id = profile.id.trim();
    if (id.isEmpty) return;
    final idx = _profiles.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    _profiles[idx] = profile;
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> reorderProfiles(List<String> orderedProfileIds) async {
    if (orderedProfileIds.isEmpty) return;
    if (orderedProfileIds.length != _profiles.length) return;

    final currentIds = _profiles.map((p) => p.id).toSet();
    final nextIds = orderedProfileIds.toSet();
    if (currentIds.length != nextIds.length) return;
    if (!currentIds.containsAll(nextIds)) return;

    final byId = <String, UnitanaProfile>{for (final p in _profiles) p.id: p};
    _profiles = orderedProfileIds
        .map((id) => byId[id])
        .whereType<UnitanaProfile>()
        .toList(growable: false);

    await _persistProfiles();
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    final targetId = id.trim();
    if (targetId.isEmpty) return;
    if (_profiles.length <= 1) return;

    final idx = _profiles.indexWhere((p) => p.id == targetId);
    if (idx < 0) return;

    final wasActive = _activeProfileId == targetId;
    _profiles.removeAt(idx);

    if (wasActive) {
      _activeProfileId = _profiles.first.id;
    }

    await _persistProfiles();
    notifyListeners();
  }

  void _updateActiveProfile(UnitanaProfile next) {
    final idx = _profiles.indexWhere((p) => p.id == _activeProfileId);
    if (idx >= 0) {
      _profiles[idx] = next;
    } else if (_profiles.isNotEmpty) {
      _profiles[0] = next;
      _activeProfileId = _profiles[0].id;
    } else {
      _profiles = <UnitanaProfile>[next];
      _activeProfileId = next.id;
    }
  }

  Future<void> resetAll() async {
    await storage.clearAll();
    _profiles = <UnitanaProfile>[];
    _activeProfileId = 'profile_1';
    _pendingSuccessToast = null;
    _preferredLanguageCode = 'system';
    notifyListeners();
  }

  void setPendingSuccessToast(String? message) {
    final next = message?.trim();
    _pendingSuccessToast = (next == null || next.isEmpty) ? null : next;
  }

  String? consumePendingSuccessToast() {
    final text = _pendingSuccessToast;
    _pendingSuccessToast = null;
    return text;
  }

  static String _normalizeLanguageCode(String? raw) {
    final code = (raw ?? '').trim().toLowerCase();
    if (code == 'en' || code == 'es') return code;
    return 'system';
  }
}
