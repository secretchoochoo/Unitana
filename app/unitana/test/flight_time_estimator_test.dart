import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/flight_time_estimator.dart';

void main() {
  test('returns null when coordinates are missing', () {
    final estimate = FlightTimeEstimator.estimate(
      fromLat: null,
      fromLon: -104.99,
      toLat: 41.15,
      toLon: -8.62,
    );
    expect(estimate, isNull);
  });

  test('estimates long-haul duration for Denver -> Porto', () {
    final estimate = FlightTimeEstimator.estimate(
      fromLat: 39.7392,
      fromLon: -104.9903,
      toLat: 41.1579,
      toLon: -8.6291,
    );

    expect(estimate, isNotNull);
    expect(estimate!.distanceKm, greaterThan(7000));
    expect(estimate.duration.inHours, inInclusiveRange(10, 12));
    expect(estimate.compactLabel, contains('flight'));
  });
}
