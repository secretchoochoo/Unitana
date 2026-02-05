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

  UnitanaAppState(this.storage);

  List<UnitanaProfile> get profiles =>
      List<UnitanaProfile>.unmodifiable(_profiles);

  String get activeProfileId => _activeProfileId;

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
    final loadedProfiles = await storage.loadProfiles();
    final loadedActiveId = await storage.loadActiveProfileId();

    if (loadedProfiles.isNotEmpty) {
      _profiles = loadedProfiles;
      _activeProfileId =
          (loadedActiveId != null &&
              loadedProfiles.any((p) => p.id == loadedActiveId))
          ? loadedActiveId
          : loadedProfiles.first.id;
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
    notifyListeners();
  }
}
