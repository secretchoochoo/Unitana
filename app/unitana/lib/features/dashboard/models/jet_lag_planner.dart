import '../../../utils/timezone_utils.dart';

enum JetLagDirection { none, eastbound, westbound }

enum JetLagBand { minimal, mild, moderate, high, extreme }

class JetLagPlan {
  final int deltaHours;
  final int adjustmentDays;
  final JetLagDirection direction;
  final JetLagBand band;

  const JetLagPlan({
    required this.deltaHours,
    required this.adjustmentDays,
    required this.direction,
    required this.band,
  });

  bool get isNoShift => deltaHours == 0;

  int get absDeltaHours => deltaHours.abs();

  bool get showOverlapHints => absDeltaHours >= 2;

  String get bandLabel => switch (band) {
    JetLagBand.minimal => 'Minimal',
    JetLagBand.mild => 'Mild',
    JetLagBand.moderate => 'Moderate',
    JetLagBand.high => 'High',
    JetLagBand.extreme => 'Extreme',
  };

  String get directionLabel => switch (direction) {
    JetLagDirection.none => 'No shift',
    JetLagDirection.eastbound => 'Eastbound (destination ahead)',
    JetLagDirection.westbound => 'Westbound (destination behind)',
  };

  String get directionShortLabel => switch (direction) {
    JetLagDirection.none => 'Same zone',
    JetLagDirection.eastbound => 'Eastbound',
    JetLagDirection.westbound => 'Westbound',
  };

  String get deltaLabelRaw => TimezoneUtils.formatDeltaLabel(deltaHours);

  String get deltaLabelForUi => isNoShift ? 'same zone (0h)' : deltaLabelRaw;

  String get tilePrimaryLabel =>
      isNoShift ? 'Same zone' : '$deltaLabelRaw $directionShortLabel';

  String get tileSecondaryLabel => isNoShift
      ? 'No adjustment needed'
      : '$bandLabel • ~${adjustmentDays}d adapt';

  String get adjustmentEstimateLabel => isNoShift
      ? 'Adjustment estimate: no adjustment needed'
      : 'Adjustment estimate: ~$adjustmentDays day${adjustmentDays == 1 ? '' : 's'}';

  int get dailyShiftMinutes {
    if (isNoShift) return 0;
    return absDeltaHours >= 6 ? 90 : 60;
  }

  String get dailyShiftLabel =>
      isNoShift ? 'No shift needed' : '~$dailyShiftMinutes min/day';

  String directionGuidance({required String destinationLabel}) {
    switch (direction) {
      case JetLagDirection.none:
        return 'No zone shift. Keep your normal sleep schedule.';
      case JetLagDirection.eastbound:
        return '$destinationLabel is ahead. Shift bedtime earlier by ~60-90 min/day.';
      case JetLagDirection.westbound:
        return '$destinationLabel is behind. Shift bedtime later by ~60-90 min/day.';
    }
  }
}

class JetLagPlanner {
  static JetLagPlan planFromZoneTimes({
    required ZoneTime fromNow,
    required ZoneTime toNow,
  }) {
    final delta = TimezoneUtils.deltaHours(toNow, fromNow);
    final absDelta = delta.abs();
    final daysToAdjust = absDelta <= 1
        ? 1
        : (absDelta / 1.5).ceil().clamp(2, 10);

    final band = _bandForDelta(absDelta);

    final direction = delta == 0
        ? JetLagDirection.none
        : (delta > 0 ? JetLagDirection.eastbound : JetLagDirection.westbound);

    return JetLagPlan(
      deltaHours: delta,
      adjustmentDays: daysToAdjust,
      direction: direction,
      band: band,
    );
  }

  static String dateImpactLabel({
    required DateTime fromLocal,
    required DateTime toLocal,
  }) {
    final fromDate = DateTime(fromLocal.year, fromLocal.month, fromLocal.day);
    final toDate = DateTime(toLocal.year, toLocal.month, toLocal.day);
    final dayDelta = toDate.difference(fromDate).inDays;

    if (dayDelta == 0) return 'Same calendar day';
    if (dayDelta > 0) {
      return dayDelta == 1
          ? 'Destination is next calendar day'
          : 'Destination is +$dayDelta calendar days';
    }
    final absDays = dayDelta.abs();
    return absDays == 1
        ? 'Destination is previous calendar day'
        : 'Destination is -$absDays calendar days';
  }

  static JetLagBand _bandForDelta(int absDelta) {
    if (absDelta <= 1) return JetLagBand.minimal;
    if (absDelta <= 3) return JetLagBand.mild;
    if (absDelta <= 6) return JetLagBand.moderate;
    if (absDelta <= 9) return JetLagBand.high;
    return JetLagBand.extreme;
  }
}
