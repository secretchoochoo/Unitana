import 'dart:math' as math;

import 'package:flutter/foundation.dart';

const double _kmPerMile = 1.609344;
const double _kgPerLb = 0.453592;

enum PaceActivityMode { running, rowing }

@immutable
class PaceCheckpoint {
  final String label;
  final double minutes;

  const PaceCheckpoint({required this.label, required this.minutes});
}

@immutable
class PaceDistanceTarget {
  final String label;
  final double km;

  const PaceDistanceTarget({required this.label, required this.km});
}

@immutable
class PaceBuilderResult {
  final double distanceKm;
  final double perKmMinutes;
  final double perMiMinutes;
  final double split500Minutes;

  const PaceBuilderResult({
    required this.distanceKm,
    required this.perKmMinutes,
    required this.perMiMinutes,
    required this.split500Minutes,
  });

  double minutesForInputUnit(String unit) {
    return unit == 'min/mi' ? perMiMinutes : perKmMinutes;
  }
}

@immutable
class PaceGoalResult {
  final double perKmMinutes;
  final double perMiMinutes;
  final double split500Minutes;
  final List<PaceCheckpoint> checkpoints;

  const PaceGoalResult({
    required this.perKmMinutes,
    required this.perMiMinutes,
    required this.split500Minutes,
    required this.checkpoints,
  });
}

@immutable
class EnergySnapshot {
  final double weightKg;
  final double activityFactor;
  final double maintenanceCalories;
  final double maintenanceKilojoules;
  final double cutCalories;
  final double gainCalories;

  const EnergySnapshot({
    required this.weightKg,
    required this.activityFactor,
    required this.maintenanceCalories,
    required this.maintenanceKilojoules,
    required this.cutCalories,
    required this.gainCalories,
  });
}

const List<PaceDistanceTarget> _runningPaceTargets = <PaceDistanceTarget>[
  PaceDistanceTarget(label: '5K', km: 5.0),
  PaceDistanceTarget(label: '10K', km: 10.0),
  PaceDistanceTarget(label: 'Half', km: 21.0975),
  PaceDistanceTarget(label: 'Marathon', km: 42.195),
];

const List<PaceDistanceTarget> _rowingPaceTargets = <PaceDistanceTarget>[
  PaceDistanceTarget(label: '500m', km: 0.5),
  PaceDistanceTarget(label: '2K', km: 2.0),
  PaceDistanceTarget(label: '5K', km: 5.0),
  PaceDistanceTarget(label: '10K', km: 10.0),
];

const List<String> _runningBuilderUnits = <String>['km', 'mi'];
const List<String> _rowingBuilderUnits = <String>['m', 'km'];

double? parsePaceMinutesValue(String raw) {
  final cleaned = raw.trim();
  if (cleaned.isEmpty) return null;
  final mmss = RegExp(r'^(\d{1,2}):([0-5]\d)$').firstMatch(cleaned);
  if (mmss != null) {
    final min = int.parse(mmss.group(1)!);
    final sec = int.parse(mmss.group(2)!);
    return min + (sec / 60.0);
  }
  final asDouble = double.tryParse(cleaned);
  if (asDouble == null || asDouble <= 0) return null;
  return asDouble;
}

double? parseDurationMinutesValue(String raw) {
  final cleaned = raw.trim();
  if (cleaned.isEmpty) return null;
  final hhmmss = RegExp(r'^(\d{1,2}):([0-5]\d):([0-5]\d)$').firstMatch(cleaned);
  if (hhmmss != null) {
    final hh = int.parse(hhmmss.group(1)!);
    final mm = int.parse(hhmmss.group(2)!);
    final ss = int.parse(hhmmss.group(3)!);
    return (hh * 60) + mm + (ss / 60.0);
  }
  final mmss = RegExp(r'^(\d{1,3}):([0-5]\d)$').firstMatch(cleaned);
  if (mmss != null) {
    final mm = int.parse(mmss.group(1)!);
    final ss = int.parse(mmss.group(2)!);
    return mm + (ss / 60.0);
  }
  return null;
}

double? parsePositiveDouble(String raw) {
  final value = double.tryParse(raw.trim());
  if (value == null || value <= 0) return null;
  return value;
}

String formatPace(double minutes) {
  final whole = minutes.floor();
  final sec = ((minutes - whole) * 60).round().clamp(0, 59);
  return '$whole:${sec.toString().padLeft(2, '0')}';
}

String formatDurationMinutes(double minutes) {
  final totalSeconds = (minutes * 60).round();
  final hours = totalSeconds ~/ 3600;
  final mins = (totalSeconds % 3600) ~/ 60;
  final secs = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

double? normalizePaceToPerKmMinutes({
  required double? inputMinutes,
  required String fromUnit,
}) {
  if (inputMinutes == null || inputMinutes <= 0) return null;
  return fromUnit == 'min/mi' ? (inputMinutes / _kmPerMile) : inputMinutes;
}

List<PaceCheckpoint> buildGoalCheckpointPlan({
  required double goalDurationMinutes,
  required double goalDistanceKm,
}) {
  const checkpoints = <double>[0.25, 0.50, 0.75, 1.0];
  return checkpoints
      .map((fraction) {
        final km = goalDistanceKm * fraction;
        final minutesAtCheckpoint = goalDurationMinutes * fraction;
        final kmLabel = km >= 10
            ? km.toStringAsFixed(1)
            : km.toStringAsFixed(2);
        return PaceCheckpoint(
          label: '${(fraction * 100).round()}% • ${kmLabel}km',
          minutes: minutesAtCheckpoint,
        );
      })
      .toList(growable: false);
}

List<PaceDistanceTarget> paceProjectionTargetsForMode(PaceActivityMode mode) {
  return mode == PaceActivityMode.rowing
      ? _rowingPaceTargets
      : _runningPaceTargets;
}

List<PaceDistanceTarget> paceGoalTargetsForMode(PaceActivityMode mode) {
  return mode == PaceActivityMode.rowing
      ? _rowingPaceTargets
      : _runningPaceTargets;
}

List<String> paceBuilderDistanceUnits(PaceActivityMode mode) {
  return mode == PaceActivityMode.rowing
      ? _rowingBuilderUnits
      : _runningBuilderUnits;
}

String paceBuilderDistanceHint(PaceActivityMode mode) {
  return mode == PaceActivityMode.rowing ? '2000' : '5';
}

double defaultPaceGoalDistanceKmForMode(PaceActivityMode mode) {
  return mode == PaceActivityMode.rowing ? 2.0 : 5.0;
}

PaceBuilderResult? computePaceBuilderResult({
  required double? distance,
  required String distanceUnit,
  required double? durationMinutes,
}) {
  if (distance == null || distance <= 0) return null;
  if (durationMinutes == null || durationMinutes <= 0) return null;
  final distanceKm = switch (distanceUnit) {
    'km' => distance,
    'mi' => distance * _kmPerMile,
    'm' => distance / 1000.0,
    _ => distance,
  };
  if (distanceKm <= 0) return null;
  final perKmMinutes = durationMinutes / distanceKm;
  return PaceBuilderResult(
    distanceKm: distanceKm,
    perKmMinutes: perKmMinutes,
    perMiMinutes: perKmMinutes * _kmPerMile,
    split500Minutes: perKmMinutes / 2.0,
  );
}

PaceGoalResult? computePaceGoalResult({
  required double? goalDurationMinutes,
  required double goalDistanceKm,
}) {
  if (goalDurationMinutes == null || goalDurationMinutes <= 0) return null;
  if (goalDistanceKm <= 0) return null;
  final perKmMinutes = goalDurationMinutes / goalDistanceKm;
  return PaceGoalResult(
    perKmMinutes: perKmMinutes,
    perMiMinutes: perKmMinutes * _kmPerMile,
    split500Minutes: perKmMinutes / 2.0,
    checkpoints: buildGoalCheckpointPlan(
      goalDurationMinutes: goalDurationMinutes,
      goalDistanceKm: goalDistanceKm,
    ),
  );
}

EnergySnapshot? computeEnergySnapshot({
  required double? weightRaw,
  required String weightUnit,
  required String activityLevel,
}) {
  if (weightRaw == null || weightRaw <= 0) return null;
  final weightKg = weightUnit == 'lb' ? weightRaw * _kgPerLb : weightRaw;
  final activityFactor = switch (activityLevel) {
    'light' => 0.95,
    'high' => 1.22,
    _ => 1.08,
  };
  final maintenanceCalories = weightKg * 33.0 * activityFactor;
  return EnergySnapshot(
    weightKg: weightKg,
    activityFactor: activityFactor,
    maintenanceCalories: maintenanceCalories,
    maintenanceKilojoules: maintenanceCalories * 4.184,
    cutCalories: math.max(1000.0, maintenanceCalories - 350.0),
    gainCalories: maintenanceCalories + 250.0,
  );
}
