part of 'dashboard_live_data.dart';

class _DashboardEnvDomain {
  _DashboardEnvDomain({
    required OpenMeteoAirQualityClient openMeteoAirQualityClient,
  }) : _openMeteoAirQuality = openMeteoAirQualityClient;

  final OpenMeteoAirQualityClient _openMeteoAirQuality;
  final Map<String, EnvSnapshot> _envByPlaceId = {};

  Object? _lastError;
  DateTime? _lastErrorAt;

  Object? get lastError => _lastError;
  DateTime? get lastErrorAt => _lastErrorAt;

  EnvSnapshot? envFor(Place? place) {
    if (place == null) return null;
    return _envByPlaceId[place.id];
  }

  bool ensureSeededForPlace(Place place) {
    if (_envByPlaceId.containsKey(place.id)) {
      return false;
    }
    _envByPlaceId[place.id] = _seedEnv(place);
    return true;
  }

  void putSeeded(Place place) {
    _envByPlaceId[place.id] = _seedEnv(place);
  }

  void clearPlaceSnapshots() {
    _envByPlaceId.clear();
  }

  Future<void> maybeRefreshForPlace({
    required Place place,
    required double? latitude,
    required double? longitude,
    required int refreshGeneration,
    required bool weatherNetworkEnabled,
    required bool Function(int refreshGeneration) isCurrentRefresh,
    required void Function(
      Object error,
      StackTrace stackTrace,
      String contextLabel,
    )
    reportRefreshError,
  }) async {
    if (!weatherNetworkEnabled) return;
    if (latitude == null || longitude == null) return;
    try {
      final current = await _openMeteoAirQuality.fetchCurrent(
        latitude: latitude,
        longitude: longitude,
      );
      if (!isCurrentRefresh(refreshGeneration)) {
        return;
      }
      final prev = _envByPlaceId[place.id];
      final seeded = _seedEnv(place);
      final pollenGrains = current.maxPollenGrains();
      final pollenIndex = pollenGrains == null
          ? (prev?.pollenIndex ?? seeded.pollenIndex)
          : _pollenIndexFromGrains(pollenGrains);

      _envByPlaceId[place.id] = EnvSnapshot(
        usAqi: current.usAqi ?? prev?.usAqi ?? seeded.usAqi,
        pollenIndex: pollenIndex,
      );
      _lastError = null;
      _lastErrorAt = null;
    } catch (error, stackTrace) {
      if (!isCurrentRefresh(refreshGeneration)) {
        return;
      }
      _lastError = error;
      _lastErrorAt = DateTime.now();
      reportRefreshError(
        error,
        stackTrace,
        'while refreshing air quality for ${place.id}',
      );
      _envByPlaceId.putIfAbsent(place.id, () => _seedEnv(place));
    }
  }

  static double _pollenIndexFromGrains(double grains) {
    // Heuristic bucketing to produce a small 0-5 value that fits in a pill.
    // This is a lightweight UX affordance, not a medical claim.
    if (grains <= 10) return 0.0;
    if (grains <= 50) return 1.0;
    if (grains <= 200) return 2.0;
    if (grains <= 500) return 3.0;
    if (grains <= 1000) return 4.0;
    return 5.0;
  }

  EnvSnapshot _seedEnv(Place place) {
    final city = place.cityName.toLowerCase();
    // Canonical demo values that match the intended UI examples.
    if (city == 'lisbon') {
      return const EnvSnapshot(usAqi: 42, pollenIndex: 3.2);
    }
    if (city == 'denver') {
      return const EnvSnapshot(usAqi: 55, pollenIndex: 1.1);
    }

    final seed = place.id.hashCode ^ (place.cityName.hashCode << 2);
    final aqi = 18 + (seed.abs() % 105); // 18..122
    final pollen = ((seed.abs() % 51) / 10.0); // 0.0..5.0
    return EnvSnapshot(usAqi: aqi, pollenIndex: pollen);
  }
}
