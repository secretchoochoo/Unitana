import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../models/place.dart';

enum WeatherCondition { partlyCloudy }

@immutable
class WeatherSnapshot {
  final double temperatureC;
  final double windKmh;
  final double gustKmh;
  final WeatherCondition condition;

  const WeatherSnapshot({
    required this.temperatureC,
    required this.windKmh,
    required this.gustKmh,
    required this.condition,
  });
}

@immutable
class SunTimesSnapshot {
  final DateTime sunriseUtc;
  final DateTime sunsetUtc;

  const SunTimesSnapshot({required this.sunriseUtc, required this.sunsetUtc});
}

/// Small live-data controller for the dashboard hero.
///
/// This slice wires refresh behavior and stabilizes UI state. Real network
/// implementations can replace the internal generators later.
class DashboardLiveDataController extends ChangeNotifier {
  final Map<String, WeatherSnapshot> _weatherByPlaceId = {};
  final Map<String, SunTimesSnapshot> _sunByPlaceId = {};

  double _eurToUsd = 1.10;
  bool _isRefreshing = false;
  Object? _lastError;
  DateTime? _lastRefreshedAt;

  Timer? _debounce;

  bool get isRefreshing => _isRefreshing;
  Object? get lastError => _lastError;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;
  double get eurToUsd => _eurToUsd;

  WeatherSnapshot? weatherFor(Place? place) {
    if (place == null) return null;
    return _weatherByPlaceId[place.id];
  }

  SunTimesSnapshot? sunFor(Place? place) {
    if (place == null) return null;
    return _sunByPlaceId[place.id];
  }

  void ensureSeeded(List<Place> places) {
    var changed = false;
    final nowUtc = DateTime.now().toUtc();

    for (final p in places) {
      if (!_weatherByPlaceId.containsKey(p.id)) {
        _weatherByPlaceId[p.id] = _seedWeather(p);
        changed = true;
      }
      if (!_sunByPlaceId.containsKey(p.id)) {
        _sunByPlaceId[p.id] = _seedSunTimes(p, nowUtc);
        changed = true;
      }
    }

    if (changed) {
      _lastRefreshedAt ??= DateTime.now();
      // Avoid notifying during widget build; schedule after this frame.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }

  Future<void> refreshAll({required List<Place> places}) async {
    // Debounce repeated taps so we don't overlap refresh flows.
    _debounce?.cancel();
    final completer = Completer<void>();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        _isRefreshing = true;
        _lastError = null;
        notifyListeners();

        // Simulate a short network latency.
        await Future<void>.delayed(const Duration(milliseconds: 350));

        for (final p in places) {
          _weatherByPlaceId[p.id] = _refreshWeather(p);
          // Sun times stay stable in this mock layer.
        }

        _lastRefreshedAt = DateTime.now();

        // Simulate a tiny rate drift while keeping outputs stable.
        _eurToUsd =
            (_eurToUsd +
                    (math.sin(DateTime.now().millisecondsSinceEpoch / 100000) *
                        0.01))
                .clamp(1.02, 1.25);
      } catch (e) {
        _lastError = e;
      } finally {
        _isRefreshing = false;
        notifyListeners();
        completer.complete();
      }
    });
    return completer.future;
  }

  WeatherSnapshot _seedWeather(Place p) {
    // Canonical demo values that match the design mock.
    if (p.cityName.toLowerCase() == 'lisbon') {
      return const WeatherSnapshot(
        temperatureC: 20.0,
        windKmh: 7.0,
        gustKmh: 11.0,
        condition: WeatherCondition.partlyCloudy,
      );
    }
    if (p.cityName.toLowerCase() == 'denver') {
      return const WeatherSnapshot(
        temperatureC: 20.0,
        windKmh: 9.0,
        gustKmh: 14.0,
        condition: WeatherCondition.partlyCloudy,
      );
    }

    // Otherwise, produce a stable deterministic snapshot.
    final seed = p.id.hashCode ^ p.cityName.hashCode;
    final temp = 12.0 + ((seed % 180) / 10.0);
    final wind = 4.0 + ((seed % 70) / 10.0);
    return WeatherSnapshot(
      temperatureC: temp,
      windKmh: wind,
      gustKmh: wind + 4.0,
      condition: WeatherCondition.partlyCloudy,
    );
  }

  SunTimesSnapshot _seedSunTimes(Place p, DateTime nowUtc) {
    // Anchor to the current UTC date for stable display.
    final day = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);

    // Canonical demo values that match the design mock.
    if (p.cityName.toLowerCase() == 'lisbon') {
      return SunTimesSnapshot(
        sunriseUtc: DateTime.utc(day.year, day.month, day.day, 7, 52),
        sunsetUtc: DateTime.utc(day.year, day.month, day.day, 17, 29),
      );
    }

    // Deterministic but plausible window for other places.
    final seed = p.id.hashCode ^ (p.cityName.hashCode << 1);
    final sunriseMinutes = 360 + (seed.abs() % 150); // 06:00 to 08:29
    final sunsetMinutes = 990 + (seed.abs() % 120); // 16:30 to 18:29

    return SunTimesSnapshot(
      sunriseUtc: day.add(Duration(minutes: sunriseMinutes)),
      sunsetUtc: day.add(Duration(minutes: sunsetMinutes)),
    );
  }

  WeatherSnapshot _refreshWeather(Place p) {
    final current = _weatherByPlaceId[p.id] ?? _seedWeather(p);
    final drift = math.sin(DateTime.now().millisecondsSinceEpoch / 60000) * 0.4;
    return WeatherSnapshot(
      temperatureC: (current.temperatureC + drift).clamp(-30.0, 45.0),
      windKmh: current.windKmh,
      gustKmh: current.gustKmh,
      condition: current.condition,
    );
  }
}
