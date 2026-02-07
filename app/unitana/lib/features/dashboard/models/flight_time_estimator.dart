import 'dart:math' as math;

class FlightTimeEstimate {
  final double distanceKm;
  final Duration duration;

  const FlightTimeEstimate({required this.distanceKm, required this.duration});

  String get compactLabel {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (minutes == 0) return '~${hours}h flight';
    return '~${hours}h ${minutes}m flight';
  }

  String get factsLabel => 'Estimated flight time: $compactLabel';
}

class FlightTimeEstimator {
  static FlightTimeEstimate? estimate({
    required double? fromLat,
    required double? fromLon,
    required double? toLat,
    required double? toLon,
  }) {
    if (fromLat == null || fromLon == null || toLat == null || toLon == null) {
      return null;
    }

    final distanceKm = _haversineKm(
      lat1: fromLat,
      lon1: fromLon,
      lat2: toLat,
      lon2: toLon,
    );

    // Deterministic phase-1 heuristic:
    // - cruise ~830 km/h
    // - +90 min fixed overhead (taxi/climb/descent)
    // - +30 min extra overhead on long-haul routes (> 5,000 km)
    final cruiseHours = distanceKm / 830.0;
    var minutes = (cruiseHours * 60).round() + 90;
    if (distanceKm > 5000) minutes += 30;
    minutes = math.max(40, minutes);

    return FlightTimeEstimate(
      distanceKm: distanceKm,
      duration: Duration(minutes: minutes),
    );
  }

  static double _haversineKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    const earthRadiusKm = 6371.0;
    return earthRadiusKm * c;
  }
}
