import 'package:flutter/material.dart';
import '../models/place.dart';
import 'storage.dart';

class UnitanaAppState extends ChangeNotifier {
  final UnitanaStorage storage;

  List<Place> places = [];
  String? defaultPlaceId;

  /// Profile name lives alongside places (not inside a Place).
  String profileName = 'My Places';

  UnitanaAppState(this.storage);

  Future<void> load() async {
    places = await storage.loadPlaces();
    defaultPlaceId = await storage.loadDefaultPlaceId();

    final storedProfile = await storage.loadProfileName();
    if (storedProfile != null && storedProfile.trim().isNotEmpty) {
      profileName = storedProfile.trim();
    }

    notifyListeners();
  }

  Future<void> setProfileName(String name) async {
    final v = name.trim().isEmpty ? 'My Places' : name.trim();
    profileName = v;
    await storage.saveProfileName(v);
    notifyListeners();
  }

  Future<void> overwritePlaces({
    required List<Place> newPlaces,
    required String defaultId,
  }) async {
    places = newPlaces;
    defaultPlaceId = defaultId;
    await storage.savePlaces(newPlaces);
    await storage.saveDefaultPlaceId(defaultId);
    notifyListeners();
  }

  Future<void> addOrReplacePlace(Place place) async {
    final idx = places.indexWhere((p) => p.id == place.id);
    if (idx >= 0) {
      places[idx] = place;
    } else {
      places.add(place);
    }
    await storage.savePlaces(places);
    notifyListeners();
  }

  Future<void> setDefaultPlaceId(String id) async {
    defaultPlaceId = id;
    await storage.saveDefaultPlaceId(id);
    notifyListeners();
  }

  Place? get defaultPlace =>
      places.where((p) => p.id == defaultPlaceId).isNotEmpty
      ? places.firstWhere((p) => p.id == defaultPlaceId)
      : (places.isNotEmpty ? places.first : null);

  Future<void> resetAll() async {
    await storage.clearAll();
    places = [];
    defaultPlaceId = null;
    profileName = 'My Places';
    notifyListeners();
  }
}
