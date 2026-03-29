import 'package:flutter_test/flutter_test.dart';

import 'package:unitana/features/dashboard/models/tool_pace_energy_helpers.dart';

void main() {
  test('pace helpers parse and format inputs consistently', () {
    expect(parsePaceMinutesValue('5:00'), 5);
    expect(parsePaceMinutesValue('4.5'), 4.5);
    expect(parsePaceMinutesValue('0'), isNull);

    expect(parseDurationMinutesValue('25:00'), 25);
    expect(parseDurationMinutesValue('1:02:30'), closeTo(62.5, 0.0001));
    expect(parseDurationMinutesValue('oops'), isNull);

    expect(formatPace(8.05), '8:03');
    expect(formatDurationMinutes(125.5), '2:05:30');
  });

  test('pace helpers normalize, project, and plan', () {
    final perKm = normalizePaceToPerKmMinutes(
      inputMinutes: 8.04672,
      fromUnit: 'min/mi',
    );
    final builder = computePaceBuilderResult(
      distance: 5,
      distanceUnit: 'km',
      durationMinutes: 25,
    );
    final goal = computePaceGoalResult(
      goalDurationMinutes: 26,
      goalDistanceKm: 5,
    );

    expect(perKm, closeTo(5.0, 0.0001));
    expect(builder, isNotNull);
    expect(builder!.distanceKm, 5);
    expect(builder.perKmMinutes, 5);
    expect(builder.perMiMinutes, closeTo(8.04672, 0.0001));
    expect(builder.split500Minutes, 2.5);
    expect(builder.minutesForInputUnit('min/mi'), closeTo(8.04672, 0.0001));

    expect(goal, isNotNull);
    expect(goal!.perKmMinutes, 5.2);
    expect(goal.perMiMinutes, closeTo(8.3686, 0.001));
    expect(goal.split500Minutes, 2.6);
    expect(goal.checkpoints, hasLength(4));
    expect(goal.checkpoints.last.label, '100% • 5.00km');
    expect(goal.checkpoints.last.minutes, 26);
  });

  test('pace mode helpers return mode-appropriate defaults and targets', () {
    expect(
      paceProjectionTargetsForMode(
        PaceActivityMode.running,
      ).map((t) => t.label).toList(),
      const <String>['5K', '10K', 'Half', 'Marathon'],
    );
    expect(
      paceGoalTargetsForMode(
        PaceActivityMode.rowing,
      ).map((t) => t.label).toList(),
      const <String>['500m', '2K', '5K', '10K'],
    );
    expect(paceBuilderDistanceUnits(PaceActivityMode.rowing), const <String>[
      'm',
      'km',
    ]);
    expect(paceBuilderDistanceHint(PaceActivityMode.rowing), '2000');
    expect(defaultPaceGoalDistanceKmForMode(PaceActivityMode.rowing), 2.0);
  });

  test('energy snapshot converts weight and produces daily targets', () {
    final snapshot = computeEnergySnapshot(
      weightRaw: 155,
      weightUnit: 'lb',
      activityLevel: 'moderate',
    );

    expect(snapshot, isNotNull);
    expect(snapshot!.weightKg, closeTo(70.30676, 0.0001));
    expect(snapshot.activityFactor, 1.08);
    expect(snapshot.maintenanceCalories, closeTo(2505.73, 0.01));
    expect(snapshot.maintenanceKilojoules, closeTo(10483.99, 0.1));
    expect(snapshot.cutCalories, closeTo(2155.73, 0.01));
    expect(snapshot.gainCalories, closeTo(2755.73, 0.01));
  });
}
