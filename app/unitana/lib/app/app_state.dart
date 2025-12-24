import '../models/place.dart';
import 'storage.dart';

class UnitanaAppState {
  final UnitanaStorage storage;

  List<Place> places = [];
  String? defaultPlaceId;
  DateTime? lastUpdated;

  UnitanaAppState({required this.storage});

  bool get hasDefaultPlace => defaultPlaceId != null;

  Place? get defaultPlace {
    if (defaultPlaceId == null) return null;
    return places.where((p) => p.id == defaultPlaceId).cast<Place?>().firstWhere(
          (p) => p != null,
          orElse: () => null,
        );
  }

  Future<void> load() async {
    places = await storage.loadPlaces();
    defaultPlaceId = await storage.loadDefaultPlaceId();
    lastUpdated = await storage.loadLastUpdated();
  }

  Future<void> setPlaces({
    required List<Place> newPlaces,
    required String newDefaultPlaceId,
  }) async {
    places = newPlaces;
    defaultPlaceId = newDefaultPlaceId;
    await storage.savePlaces(newPlaces);
    await storage.saveDefaultPlaceId(newDefaultPlaceId);
    lastUpdated = await storage.loadLastUpdated();
  }
}

