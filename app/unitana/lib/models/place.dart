enum PlaceType { living, visiting, other }

class Place {
  final String id;
  final PlaceType type;
  final String name;

  /// IANA timezone IDs, e.g. "America/Denver", "Europe/Lisbon"
  final String homeTimeZone;
  final String localTimeZone;

  /// Unit system hints (simple for MVP)
  final String homeSystem; // "imperial" or "metric"
  final String localSystem; // "imperial" or "metric"

  const Place({
    required this.id,
    required this.type,
    required this.name,
    required this.homeTimeZone,
    required this.localTimeZone,
    required this.homeSystem,
    required this.localSystem,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'homeTimeZone': homeTimeZone,
        'localTimeZone': localTimeZone,
        'homeSystem': homeSystem,
        'localSystem': localSystem,
      };

  static Place fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      type: PlaceType.values.firstWhere((t) => t.name == json['type']),
      name: json['name'] as String,
      homeTimeZone: json['homeTimeZone'] as String,
      localTimeZone: json['localTimeZone'] as String,
      homeSystem: json['homeSystem'] as String,
      localSystem: json['localSystem'] as String,
    );
  }
}

