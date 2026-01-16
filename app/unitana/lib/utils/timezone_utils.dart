import 'package:flutter/foundation.dart';

/// Lightweight timezone helpers for the two canonical Unitana places.
///
/// We intentionally avoid pulling in a full timezone database package for the
/// dashboard hero. Instead we implement DST rules for:
/// - America/Denver (US rules, 2007+)
/// - Europe/Lisbon (EU rules)
///
/// If additional timezones are required, expand this file carefully and add
/// focused unit tests.
@immutable
class ZoneTime {
  final DateTime local;
  final int offsetHours;
  final String abbreviation;

  const ZoneTime({
    required this.local,
    required this.offsetHours,
    required this.abbreviation,
  });
}

class TimezoneUtils {
  static ZoneTime nowInZone(String tzId, {DateTime? nowUtc}) {
    final utc = (nowUtc ?? DateTime.now().toUtc());
    final zone = _zoneInfo(tzId, utc);
    final local = utc.add(Duration(hours: zone.$1));
    return ZoneTime(local: local, offsetHours: zone.$1, abbreviation: zone.$2);
  }

  /// Convert a wall-clock local time in the given timezone into UTC.
  ///
  /// This is a lightweight helper for demo data and avoids introducing a
  /// full timezone database. It converges in a couple of iterations for
  /// whole-hour offsets and DST boundaries.
  static DateTime localToUtc(String tzId, DateTime local) {
    var guessUtc = DateTime.utc(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
      local.microsecond,
    );

    for (var i = 0; i < 2; i++) {
      final zt = nowInZone(tzId, nowUtc: guessUtc);
      final error = zt.local.difference(local);
      if (error.inMinutes == 0) break;
      guessUtc = guessUtc.subtract(error);
    }
    return guessUtc;
  }

  static String formatClock(ZoneTime zt, {required bool use24h}) {
    final dt = zt.local;
    final hh = dt.hour;
    final mm = dt.minute.toString().padLeft(2, '0');
    if (use24h) {
      final h2 = hh.toString().padLeft(2, '0');
      return '$h2:$mm';
    }

    final isPm = hh >= 12;
    var h12 = hh % 12;
    if (h12 == 0) h12 = 12;
    final meridiem = isPm ? 'PM' : 'AM';
    return '$h12:$mm $meridiem';
  }

  /// `30 Dec` style date intended for compact dashboard display.
  static String formatShortDate(ZoneTime zt) {
    final dt = zt.local;
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final mon = (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : '';
    return '${dt.day} $mon';
  }

  static int deltaHours(ZoneTime a, ZoneTime b) {
    return a.offsetHours - b.offsetHours;
  }

  static String formatDeltaLabel(int deltaHours) {
    if (deltaHours == 0) return '0h';
    final sign = deltaHours > 0 ? '+' : '';
    return '$sign${deltaHours}h';
  }

  static (int, String) _zoneInfo(String tzId, DateTime utc) {
    switch (tzId) {
      case 'America/Denver':
        return _denver(utc);
      case 'Europe/Lisbon':
        return _lisbon(utc);
      default:
        // Fall back to a stable UTC display so we never crash the dashboard.
        return (0, 'UTC');
    }
  }

  /// Denver: MST (UTC-7) or MDT (UTC-6).
  /// US DST: starts second Sunday in March at 2:00 local, ends first Sunday in
  /// November at 2:00 local.
  static (int, String) _denver(DateTime utc) {
    final year = utc.year;
    final dstStartLocal = _nthWeekdayOfMonth(
      year,
      3,
      DateTime.sunday,
      2,
      hour: 2,
      baseOffsetHours: -7,
    );

    final dstEndLocal = _nthWeekdayOfMonth(
      year,
      11,
      DateTime.sunday,
      1,
      hour: 2,
      baseOffsetHours: -6,
    );

    final localAssumingStd = utc.add(const Duration(hours: -7));
    final isDst =
        !localAssumingStd.isBefore(dstStartLocal) &&
        localAssumingStd.isBefore(dstEndLocal);

    if (isDst) return (-6, 'MDT');
    return (-7, 'MST');
  }

  /// Lisbon: WET (UTC+0) or WEST (UTC+1).
  /// EU DST: starts last Sunday in March at 1:00 UTC, ends last Sunday in
  /// October at 1:00 UTC.
  static (int, String) _lisbon(DateTime utc) {
    final year = utc.year;
    final startUtc = _lastWeekdayOfMonthUtc(year, 3, DateTime.sunday, hour: 1);
    final endUtc = _lastWeekdayOfMonthUtc(year, 10, DateTime.sunday, hour: 1);
    final isDst = !utc.isBefore(startUtc) && utc.isBefore(endUtc);
    if (isDst) return (1, 'WEST');
    return (0, 'WET');
  }

  static DateTime _nthWeekdayOfMonth(
    int year,
    int month,
    int weekday,
    int n, {
    required int hour,
    required int baseOffsetHours,
  }) {
    // Compute the nth weekday in local time (base offset), then attach hour.
    final firstLocal = DateTime.utc(
      year,
      month,
      1,
    ).add(Duration(hours: baseOffsetHours));

    final firstWeekdayDelta = (weekday - firstLocal.weekday + 7) % 7;
    final day = 1 + firstWeekdayDelta + (n - 1) * 7;
    return DateTime(year, month, day, hour, 0, 0);
  }

  static DateTime _lastWeekdayOfMonthUtc(
    int year,
    int month,
    int weekday, {
    required int hour,
  }) {
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    var dt = DateTime.utc(nextYear, nextMonth, 1, hour);
    dt = dt.subtract(const Duration(days: 1));
    while (dt.weekday != weekday) {
      dt = dt.subtract(const Duration(days: 1));
    }
    return DateTime.utc(dt.year, dt.month, dt.day, hour);
  }
}
