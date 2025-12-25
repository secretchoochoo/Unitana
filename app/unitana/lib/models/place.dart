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
