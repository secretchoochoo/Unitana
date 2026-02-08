import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Timezone helpers backed by IANA data via the `timezone` package.
@immutable
class ZoneTime {
  final DateTime local;
  final int offsetMinutes;
  final String abbreviation;

  const ZoneTime({
    required this.local,
    int? offsetHours,
    int? offsetMinutes,
    required this.abbreviation,
  }) : offsetMinutes = offsetMinutes ?? ((offsetHours ?? 0) * 60);

  int get offsetHours => offsetMinutes ~/ 60;
}

class TimezoneUtils {
  static bool _tzReady = false;

  static void _ensureTzReady() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    _tzReady = true;
  }

  static bool isKnownTimeZoneId(String tzId) {
    final normalized = tzId.trim();
    if (normalized.isEmpty) return false;
    if (normalized.toUpperCase() == 'UTC') return true;
    _ensureTzReady();
    try {
      tz.getLocation(normalized);
      return true;
    } catch (_) {
      return false;
    }
  }

  static ZoneTime nowInZone(
    String tzId, {
    DateTime? nowUtc,
    bool fallbackToUtcOnUnknown = true,
  }) {
    _ensureTzReady();
    final normalized = tzId.trim();
    final utc = (nowUtc ?? DateTime.now().toUtc());
    if (normalized.toUpperCase() == 'UTC') {
      return ZoneTime(local: utc, offsetMinutes: 0, abbreviation: 'UTC');
    }

    try {
      final location = tz.getLocation(normalized);
      final local = tz.TZDateTime.from(utc, location);
      return ZoneTime(
        local: local,
        offsetMinutes: local.timeZoneOffset.inMinutes,
        abbreviation: local.timeZoneName,
      );
    } catch (_) {
      if (!fallbackToUtcOnUnknown) {
        throw ArgumentError.value(tzId, 'tzId', 'Unknown timezone ID');
      }
      return ZoneTime(local: utc, offsetMinutes: 0, abbreviation: 'UTC');
    }
  }

  /// Convert a wall-clock local time in the given timezone into UTC.
  ///
  /// This is a lightweight helper for demo data and avoids introducing a
  /// full timezone database. It converges in a couple of iterations for
  /// whole-hour offsets and DST boundaries.
  static DateTime localToUtc(
    String tzId,
    DateTime local, {
    bool fallbackToUtcOnUnknown = true,
  }) {
    _ensureTzReady();
    final normalized = tzId.trim();
    if (normalized.toUpperCase() == 'UTC') {
      return DateTime.utc(
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
        local.second,
        local.millisecond,
        local.microsecond,
      );
    }
    try {
      final location = tz.getLocation(normalized);
      final zoned = tz.TZDateTime(
        location,
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
        local.second,
        local.millisecond,
        local.microsecond,
      );
      return zoned.toUtc();
    } catch (_) {
      if (!fallbackToUtcOnUnknown) {
        throw ArgumentError.value(tzId, 'tzId', 'Unknown timezone ID');
      }
      return DateTime.utc(
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
        local.second,
        local.millisecond,
        local.microsecond,
      );
    }
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
    return ((a.offsetMinutes - b.offsetMinutes) / 60).round();
  }

  static String formatDeltaLabel(int deltaHours) {
    if (deltaHours == 0) return '0h';
    final sign = deltaHours > 0 ? '+' : '';
    return '$sign${deltaHours}h';
  }
}
