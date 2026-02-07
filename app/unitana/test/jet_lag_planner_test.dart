import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/jet_lag_planner.dart';
import 'package:unitana/utils/timezone_utils.dart';

ZoneTime _zone(int offsetHours) => ZoneTime(
  local: DateTime(2026, 2, 7, 12, 0),
  offsetHours: offsetHours,
  abbreviation: 'T$offsetHours',
);

void main() {
  test('zero offset yields no-shift plan labels', () {
    final plan = JetLagPlanner.planFromZoneTimes(
      fromNow: _zone(0),
      toNow: _zone(0),
    );

    expect(plan.isNoShift, isTrue);
    expect(plan.deltaHours, 0);
    expect(plan.adjustmentDays, 1);
    expect(plan.band, JetLagBand.minimal);
    expect(plan.bandLabel, 'Minimal');
    expect(plan.directionLabel, 'No shift');
    expect(plan.directionShortLabel, 'Same zone');
    expect(plan.deltaLabelForUi, 'same zone (0h)');
    expect(plan.tilePrimaryLabel, 'Same zone');
    expect(plan.tileSecondaryLabel, 'No adjustment needed');
    expect(plan.dailyShiftMinutes, 0);
    expect(plan.dailyShiftLabel, 'No shift needed');
    expect(
      plan.adjustmentEstimateLabel,
      'Adjustment estimate: no adjustment needed',
    );
    expect(plan.showOverlapHints, isFalse);
  });

  test('eastbound delta computes adjustment days and guidance', () {
    final plan = JetLagPlanner.planFromZoneTimes(
      fromNow: _zone(-6),
      toNow: _zone(1),
    );

    expect(plan.direction, JetLagDirection.eastbound);
    expect(plan.band, JetLagBand.high);
    expect(plan.bandLabel, 'High');
    expect(plan.deltaHours, 7);
    expect(plan.adjustmentDays, 5);
    expect(plan.deltaLabelRaw, '+7h');
    expect(plan.tilePrimaryLabel, '+7h Eastbound');
    expect(plan.tileSecondaryLabel, 'High • ~5d adapt');
    expect(plan.dailyShiftMinutes, 90);
    expect(plan.dailyShiftLabel, '~90 min/day');
    expect(plan.showOverlapHints, isTrue);
    expect(
      plan.directionGuidance(destinationLabel: 'Destination (Barcelona)'),
      contains('is ahead'),
    );
  });

  test('westbound delta computes adjustment days and guidance', () {
    final plan = JetLagPlanner.planFromZoneTimes(
      fromNow: _zone(2),
      toNow: _zone(-3),
    );

    expect(plan.direction, JetLagDirection.westbound);
    expect(plan.band, JetLagBand.moderate);
    expect(plan.deltaHours, -5);
    expect(plan.adjustmentDays, 4);
    expect(plan.deltaLabelRaw, '-5h');
    expect(plan.dailyShiftMinutes, 60);
    expect(
      plan.directionGuidance(destinationLabel: 'Home (Chicago)'),
      contains('is behind'),
    );
  });

  test('extreme offsets clamp adjustment estimate to 10 days', () {
    final plan = JetLagPlanner.planFromZoneTimes(
      fromNow: _zone(-12),
      toNow: _zone(14),
    );
    expect(plan.deltaHours, 26);
    expect(plan.band, JetLagBand.extreme);
    expect(plan.adjustmentDays, 10);
  });

  test('date impact label handles same/next/previous day', () {
    final same = JetLagPlanner.dateImpactLabel(
      fromLocal: DateTime(2026, 2, 7, 10, 0),
      toLocal: DateTime(2026, 2, 7, 21, 0),
    );
    final next = JetLagPlanner.dateImpactLabel(
      fromLocal: DateTime(2026, 2, 7, 23, 0),
      toLocal: DateTime(2026, 2, 8, 5, 0),
    );
    final prev = JetLagPlanner.dateImpactLabel(
      fromLocal: DateTime(2026, 2, 8, 2, 0),
      toLocal: DateTime(2026, 2, 7, 23, 0),
    );

    expect(same, 'Same calendar day');
    expect(next, 'Destination is next calendar day');
    expect(prev, 'Destination is previous calendar day');
  });
}
