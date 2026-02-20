import 'package:flutter/material.dart';

import '../features/dashboard/models/profile_auto_selector.dart';
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
  String _preferredThemeMode = 'dark';
  bool _autoProfileSuggestEnabled = false;
  String? _autoProfileSuggestionReason;
  String? _autoSuggestedProfileId;
  Map<String, int> _profileLastActivatedEpochById = const <String, int>{};
  bool _lofiAudioEnabled = false;
  double _lofiAudioVolume = 0.25;
  bool _tutorialDismissed = true;
  bool _tutorialReplayRequested = false;
  Set<String> _completedTutorialSurfaces = <String>{};

  UnitanaAppState(this.storage);

  List<UnitanaProfile> get profiles =>
      List<UnitanaProfile>.unmodifiable(_profiles);

  String get activeProfileId => _activeProfileId;
  String get preferredLanguageCode => _preferredLanguageCode;
  String get preferredThemeMode => _preferredThemeMode;
  ThemeMode get appThemeMode {
    switch (_preferredThemeMode) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  bool get autoProfileSuggestEnabled => _autoProfileSuggestEnabled;
  String? get autoProfileSuggestionReason => _autoProfileSuggestionReason;
  String? get autoSuggestedProfileId => _autoSuggestedProfileId;
  bool get lofiAudioEnabled => _lofiAudioEnabled;
  double get lofiAudioVolume => _lofiAudioVolume;
  bool get tutorialDismissed => _tutorialDismissed;
  bool get tutorialReplayRequested => _tutorialReplayRequested;
  Set<String> get completedTutorialSurfaces =>
      Set<String>.unmodifiable(_completedTutorialSurfaces);
  bool get shouldShowTutorial => false;
  Locale? get appLocale {
    switch (_preferredLanguageCode) {
      case 'en':
        return const Locale('en');
      case 'es':
        return const Locale('es');
      case 'fr':
        return const Locale('fr');
      case 'pt-PT':
        return const Locale('pt', 'PT');
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
    final preferredThemeRaw = await storage.loadPreferredThemeMode();
    _preferredThemeMode = _normalizeThemeMode(preferredThemeRaw);
    _autoProfileSuggestEnabled = await storage.loadAutoProfileSuggestEnabled();
    _autoProfileSuggestionReason = await storage.loadAutoProfileSuggestReason();
    _autoSuggestedProfileId = await storage.loadAutoProfileSuggestProfileId();
    _profileLastActivatedEpochById = await storage
        .loadProfileLastActivatedAtById();
    _lofiAudioEnabled = await storage.loadLofiAudioEnabled();
    _lofiAudioVolume = await storage.loadLofiAudioVolume();
    _tutorialDismissed = await storage.loadTutorialDismissed();
    _tutorialReplayRequested = await storage.loadTutorialReplayRequested();
    _completedTutorialSurfaces = await storage.loadTutorialCompletedSurfaces();

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

      _profileLastActivatedEpochById = _normalizeRecencyMap(
        _profileLastActivatedEpochById,
      );
      _touchProfileRecency(_activeProfileId, notify: false);
      await _persistRecencyMap();

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
    _touchProfileRecency(_activeProfileId, notify: false);

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

  Future<void> _persistRecencyMap() async {
    await storage.saveProfileLastActivatedAtById(
      _profileLastActivatedEpochById,
    );
  }

  Future<void> _persistAutoSuggestionState() async {
    await storage.saveAutoProfileSuggestEnabled(_autoProfileSuggestEnabled);
    await storage.saveAutoProfileSuggestReason(_autoProfileSuggestionReason);
    await storage.saveAutoProfileSuggestProfileId(_autoSuggestedProfileId);
  }

  Future<void> _persistAudioState() async {
    await storage.saveLofiAudioEnabled(_lofiAudioEnabled);
    await storage.saveLofiAudioVolume(_lofiAudioVolume);
  }

  Future<void> _persistTutorialState() async {
    await storage.saveTutorialDismissed(_tutorialDismissed);
    await storage.saveTutorialReplayRequested(_tutorialReplayRequested);
    await storage.saveTutorialCompletedSurfaces(_completedTutorialSurfaces);
  }

  Future<void> setPreferredLanguageCode(String code) async {
    final normalized = _normalizeLanguageCode(code);
    if (_preferredLanguageCode == normalized) return;
    _preferredLanguageCode = normalized;
    await storage.savePreferredLanguageCode(normalized);
    notifyListeners();
  }

  Future<void> setPreferredThemeMode(String mode) async {
    final normalized = _normalizeThemeMode(mode);
    if (_preferredThemeMode == normalized) return;
    _preferredThemeMode = normalized;
    await storage.savePreferredThemeMode(normalized);
    notifyListeners();
  }

  Future<void> switchToProfile(String id) async {
    if (id.trim().isEmpty) return;
    if (_activeProfileId == id) return;
    if (!_profiles.any((p) => p.id == id)) return;
    _activeProfileId = id;
    _touchProfileRecency(_activeProfileId, notify: false);
    await _persistProfiles();
    await _persistRecencyMap();
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

  Future<void> createProfile(UnitanaProfile profile, {int? insertIndex}) async {
    final id = profile.id.trim();
    if (id.isEmpty) return;
    if (_profiles.any((p) => p.id == id)) return;

    final next = List<UnitanaProfile>.from(_profiles);
    final targetIndex = insertIndex == null
        ? next.length
        : insertIndex.clamp(0, next.length).toInt();
    next.insert(targetIndex, profile);
    _profiles = next;
    _activeProfileId = id;
    _touchProfileRecency(_activeProfileId, notify: false);
    await _persistProfiles();
    await _persistRecencyMap();
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
      _touchProfileRecency(_activeProfileId, notify: false);
    }

    _profileLastActivatedEpochById.remove(targetId);
    await _persistProfiles();
    await _persistRecencyMap();
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
    _preferredThemeMode = 'dark';
    _autoProfileSuggestEnabled = false;
    _autoProfileSuggestionReason = null;
    _autoSuggestedProfileId = null;
    _profileLastActivatedEpochById = const <String, int>{};
    _lofiAudioEnabled = false;
    _lofiAudioVolume = 0.25;
    _tutorialDismissed = true;
    _tutorialReplayRequested = false;
    notifyListeners();
  }

  Future<void> markTutorialDismissed() async {
    _tutorialDismissed = true;
    _tutorialReplayRequested = false;
    await _persistTutorialState();
    notifyListeners();
  }

  Future<void> requestTutorialReplay() async {
    _tutorialReplayRequested = false;
    await _persistTutorialState();
    notifyListeners();
  }

  bool hasCompletedTutorialSurface(String surfaceId) {
    final id = surfaceId.trim();
    if (id.isEmpty) return false;
    return _completedTutorialSurfaces.contains(id);
  }

  Future<void> markTutorialSurfaceCompleted(String surfaceId) async {
    final id = surfaceId.trim();
    if (id.isEmpty) return;
    if (_completedTutorialSurfaces.contains(id)) return;
    _completedTutorialSurfaces = <String>{..._completedTutorialSurfaces, id};
    await _persistTutorialState();
    notifyListeners();
  }

  Future<void> resetTutorialSurfaces() async {
    _tutorialDismissed = false;
    _tutorialReplayRequested = false;
    _completedTutorialSurfaces = <String>{};
    await _persistTutorialState();
    notifyListeners();
  }

  Future<void> setLofiAudioEnabled(bool enabled) async {
    if (_lofiAudioEnabled == enabled) return;
    _lofiAudioEnabled = enabled;
    await _persistAudioState();
    notifyListeners();
  }

  Future<void> setLofiAudioVolume(double volume) async {
    final normalized = volume.isNaN || volume.isInfinite
        ? 0.25
        : volume.clamp(0.0, 1.0).toDouble();
    if ((_lofiAudioVolume - normalized).abs() < 0.0001) return;
    _lofiAudioVolume = normalized;
    await _persistAudioState();
    notifyListeners();
  }

  Future<void> setAutoProfileSuggestEnabled(bool enabled) async {
    if (_autoProfileSuggestEnabled == enabled) return;
    _autoProfileSuggestEnabled = enabled;
    if (!enabled) {
      _autoSuggestedProfileId = null;
      _autoProfileSuggestionReason =
          'Disabled. Turn on to evaluate location-based profile suggestions.';
    }
    await _persistAutoSuggestionState();
    notifyListeners();
  }

  Future<void> evaluateAutoProfileSuggestion({
    required ProfileLocationSignal? signal,
  }) async {
    if (!_autoProfileSuggestEnabled) {
      _autoSuggestedProfileId = null;
      _autoProfileSuggestionReason =
          'Disabled. Turn on to evaluate location-based profile suggestions.';
      await _persistAutoSuggestionState();
      notifyListeners();
      return;
    }

    final result = await ProfileAutoSelector.evaluate(
      profiles: _profiles,
      activeProfileId: _activeProfileId,
      lastActivatedEpochByProfileId: _profileLastActivatedEpochById,
      signal: signal,
    );
    _autoSuggestedProfileId = result.profileId;
    _autoProfileSuggestionReason = result.reason;
    await _persistAutoSuggestionState();
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
    final rawCode = (raw ?? '').trim();
    if (rawCode.isEmpty) return 'system';
    final code = rawCode.toLowerCase();
    if (code == 'en' || code == 'es' || code == 'fr') return code;
    if (code == 'pt' || code == 'pt-pt') return 'pt-PT';
    return 'system';
  }

  static String _normalizeThemeMode(String? raw) {
    final mode = (raw ?? '').trim().toLowerCase();
    if (mode == 'light' || mode == 'dark' || mode == 'system') return mode;
    return 'dark';
  }

  void _touchProfileRecency(String profileId, {bool notify = true}) {
    if (profileId.trim().isEmpty) return;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final next = Map<String, int>.from(_profileLastActivatedEpochById);
    next[profileId] = now;
    _profileLastActivatedEpochById = _normalizeRecencyMap(next);
    if (notify) {
      notifyListeners();
    }
  }

  Map<String, int> _normalizeRecencyMap(Map<String, int> input) {
    if (_profiles.isEmpty) return const <String, int>{};
    final allowed = _profiles.map((p) => p.id).toSet();
    final out = <String, int>{};
    for (final entry in input.entries) {
      final id = entry.key.trim();
      final ts = entry.value;
      if (id.isEmpty || !allowed.contains(id) || ts <= 0) continue;
      out[id] = ts;
    }
    return out;
  }
}
