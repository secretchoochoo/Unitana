enum PlaceType { living, visiting, other }

class Place {
  final String id;
  final PlaceType type;

  /// User-facing name for this Place (Home Base or Destination).
  final String name;

  /// City metadata (MVP contract)
  final String cityName; // display label, e.g. "Denver"
  final String countryCode; // e.g. "US"
  /// IANA timezone IDs, e.g. "America/Denver", "Europe/Lisbon"
  final String timeZoneId;

  /// Unit system (MVP)
  final String unitSystem; // "imperial" or "metric"

  /// Clock preference (MVP)
  final bool use24h;

  const Place({
    required this.id,
    required this.type,
    required this.name,
    required this.cityName,
    required this.countryCode,
    required this.timeZoneId,
    required this.unitSystem,
    required this.use24h,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'cityName': cityName,
    'countryCode': countryCode,
    'timeZoneId': timeZoneId,
    'unitSystem': unitSystem,
    'use24h': use24h,
  };

  static Place fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      type: PlaceType.values.firstWhere((t) => t.name == json['type']),
      name: json['name'] as String,
      cityName: json['cityName'] as String? ?? 'Unknown',
      countryCode: json['countryCode'] as String? ?? '',
      timeZoneId: json['timeZoneId'] as String? ?? 'UTC',
      unitSystem: json['unitSystem'] as String? ?? 'metric',
      use24h: json['use24h'] as bool? ?? true,
    );
  }
}

/// A saved dashboard configuration (name + places + defaults).
///
/// Stored in SharedPreferences under `profiles_v1` as a JSON list.
/// Active profile id is stored under `active_profile_id_v1`.
class UnitanaProfile {
  final String id;
  final String name;
  final List<Place> places;
  final String? defaultPlaceId;

  const UnitanaProfile({
    required this.id,
    required this.name,
    required this.places,
    required this.defaultPlaceId,
  });

  UnitanaProfile copyWith({
    String? id,
    String? name,
    List<Place>? places,
    String? defaultPlaceId,
  }) {
    return UnitanaProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      places: places ?? this.places,
      defaultPlaceId: defaultPlaceId ?? this.defaultPlaceId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'defaultPlaceId': defaultPlaceId,
    'places': places.map((p) => p.toJson()).toList(),
  };

  static UnitanaProfile? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    if (id is! String || id.trim().isEmpty) return null;
    if (name is! String || name.trim().isEmpty) return null;

    final placesRaw = raw['places'];
    final places = <Place>[];
    if (placesRaw is List) {
      for (final entry in placesRaw) {
        try {
          final decoded = Place.fromJson(entry);
          places.add(decoded);
        } catch (_) {
          // Skip bad entries.
        }
      }
    }

    final defaultId = raw['defaultPlaceId'];
    return UnitanaProfile(
      id: id.trim(),
      name: name.trim(),
      places: places,
      defaultPlaceId: defaultId is String && defaultId.trim().isNotEmpty
          ? defaultId.trim()
          : null,
    );
  }
}
