import 'package:flutter/foundation.dart';

import '../../../data/city_picker_engine.dart';
import '../../../models/place.dart';
import '../../../utils/timezone_utils.dart';
import 'dashboard_session_controller.dart';
import 'time_zone_catalog.dart';

@immutable
class TimeToolDefaults {
  final String fromZoneId;
  final String toZoneId;
  final String fromDisplayLabel;
  final String toDisplayLabel;

  const TimeToolDefaults({
    required this.fromZoneId,
    required this.toZoneId,
    required this.fromDisplayLabel,
    required this.toDisplayLabel,
  });
}

@immutable
class TimeZoneConversionOutput {
  final String inputLabel;
  final String outputLabel;

  const TimeZoneConversionOutput({
    required this.inputLabel,
    required this.outputLabel,
  });
}

const Map<String, List<String>> _tzAbbrevAliases = <String, List<String>>{
  'UTC': <String>['UTC'],
  'GMT': <String>['UTC', 'Europe/London'],
  'EST': <String>['America/New_York'],
  'EDT': <String>['America/New_York'],
  'CST': <String>['America/Chicago'],
  'CDT': <String>['America/Chicago'],
  'MST': <String>['America/Denver'],
  'MDT': <String>['America/Denver'],
  'PST': <String>['America/Los_Angeles'],
  'PDT': <String>['America/Los_Angeles'],
  'CET': <String>['Europe/Paris', 'Europe/Berlin', 'Europe/Madrid'],
  'CEST': <String>['Europe/Paris', 'Europe/Berlin', 'Europe/Madrid'],
  'IST': <String>['Asia/Kolkata'],
  'JST': <String>['Asia/Tokyo'],
};

String displayLabelForZone(String zoneId, List<TimeZoneOption> options) {
  final match = options.where((o) => o.id == zoneId);
  if (match.isNotEmpty) return match.first.label;
  return zoneId;
}

String formatLocalDateTime(DateTime dt) {
  final yyyy = dt.year.toString().padLeft(4, '0');
  final mm = dt.month.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd $hh:$min';
}

DateTime? parseLocalDateTime(String raw) {
  final trimmed = raw.trim();
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{1,2}):(\d{2})$',
  ).firstMatch(trimmed);
  if (match == null) return null;
  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  final hour = int.tryParse(match.group(4)!);
  final minute = int.tryParse(match.group(5)!);
  if (year == null ||
      month == null ||
      day == null ||
      hour == null ||
      minute == null) {
    return null;
  }
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  final dt = DateTime(year, month, day, hour, minute);
  if (dt.year != year ||
      dt.month != month ||
      dt.day != day ||
      dt.hour != hour ||
      dt.minute != minute) {
    return null;
  }
  return dt;
}

String? rebaseTimeConverterInput({
  required String rawInput,
  required String oldFromZoneId,
  required String newFromZoneId,
}) {
  final parsed = parseLocalDateTime(rawInput);
  if (parsed == null) return null;
  final utc = TimezoneUtils.localToUtc(oldFromZoneId, parsed);
  final rebased = TimezoneUtils.nowInZone(newFromZoneId, nowUtc: utc).local;
  return formatLocalDateTime(rebased);
}

TimeZoneConversionOutput? convertTimeZoneInput({
  required String rawInput,
  required String fromZoneId,
  required String toZoneId,
  required bool use24h,
}) {
  final localInput = parseLocalDateTime(rawInput);
  if (localInput == null) return null;
  final utc = TimezoneUtils.localToUtc(fromZoneId, localInput);
  final toLocal = TimezoneUtils.nowInZone(toZoneId, nowUtc: utc).local;
  final outputClock = use24h
      ? TimezoneUtils.formatClock(
          ZoneTime(local: toLocal, offsetHours: 0, abbreviation: ''),
          use24h: true,
        )
      : TimezoneUtils.formatClock(
          ZoneTime(local: toLocal, offsetHours: 0, abbreviation: ''),
          use24h: false,
        );
  final outputDate = formatLocalDateTime(
    DateTime(
      toLocal.year,
      toLocal.month,
      toLocal.day,
      toLocal.hour,
      toLocal.minute,
    ),
  ).substring(0, 10);
  return TimeZoneConversionOutput(
    inputLabel: formatLocalDateTime(localInput),
    outputLabel: '$outputDate $outputClock',
  );
}

List<String> aliasZonesForQuery(String rawQuery) {
  final token = rawQuery.trim().toUpperCase();
  return _tzAbbrevAliases[token] ?? const <String>[];
}

List<TimeZoneCityOption> featuredTimeZoneCityOptions({
  required List<TimeZoneCityOption> cityOptions,
  required Place? home,
  required Place? destination,
  int limit = 24,
}) {
  if (cityOptions.isEmpty) return const <TimeZoneCityOption>[];
  return TimeZoneCatalog.mainstreamCityOptionsFromAll(
    all: cityOptions,
    home: home,
    destination: destination,
    limit: limit,
  );
}

List<TimeZoneCityOption> searchTimeZoneCityOptions({
  required String rawQuery,
  required List<TimeZoneCityOption> featured,
  required List<CityPickerEngineEntry<TimeZoneCityOption>> allEntries,
  required List<CityPickerEngineEntry<TimeZoneCityOption>> featuredEntries,
  required Place? home,
  required Place? destination,
}) {
  final normalized = CityPickerEngine.normalizeQuery(rawQuery);
  if (normalized.isEmpty) return featured;
  final aliasZones = aliasZonesForQuery(rawQuery).toSet();
  final preferredZones = <String>{
    if (home != null) home.timeZoneId,
    if (destination != null) destination.timeZoneId,
  };
  final sourceEntries = normalized.length < 3 ? featuredEntries : allEntries;
  return CityPickerEngine.searchEntries(
    entries: sourceEntries,
    queryRaw: rawQuery,
    preferredTimeZoneIds: preferredZones,
    aliasTimeZoneIds: aliasZones,
    maxCandidates: 260,
    maxResults: 40,
    shortQueryAllowsTimeZonePrefix: true,
    dedupeByTimeZone: true,
    dedupeByCityCountry: true,
    allowTimeZoneOnlyMatches: true,
    deprioritizeTimeZoneOnlyMatches: true,
  ).map((entry) => entry.value).toList(growable: false);
}

List<TimeZoneOption> searchTimeZoneOptions({
  required String rawQuery,
  required List<CityPickerEngineEntry<TimeZoneOption>> entries,
  required Place? home,
  required Place? destination,
}) {
  final query = rawQuery.trim();
  if (query.isEmpty) return const <TimeZoneOption>[];
  final aliasZones = aliasZonesForQuery(query).toSet();
  final preferredZones = <String>{
    if (home != null) home.timeZoneId,
    if (destination != null) destination.timeZoneId,
  };
  return CityPickerEngine.searchEntries(
    entries: entries,
    queryRaw: query,
    preferredTimeZoneIds: preferredZones,
    aliasTimeZoneIds: aliasZones,
    maxCandidates: 180,
    maxResults: 12,
    shortQueryAllowsTimeZonePrefix: true,
    dedupeByTimeZone: false,
    allowTimeZoneOnlyMatches: true,
    deprioritizeTimeZoneOnlyMatches: false,
  ).map((entry) => entry.value).toList(growable: false);
}

TimeToolDefaults resolveTimeToolDefaults({
  required List<TimeZoneOption> options,
  required Place? home,
  required Place? destination,
  required DashboardReality reality,
  required TimeZoneWidgetSelection? savedSelection,
  required bool isJetLagTool,
}) {
  final fallback = options.isEmpty ? 'UTC' : options.first.id;
  final validZoneIds = options.map((o) => o.id).toSet();

  if (savedSelection != null &&
      validZoneIds.contains(savedSelection.fromZoneId) &&
      validZoneIds.contains(savedSelection.toZoneId) &&
      savedSelection.fromZoneId != savedSelection.toZoneId) {
    return TimeToolDefaults(
      fromZoneId: savedSelection.fromZoneId,
      toZoneId: savedSelection.toZoneId,
      fromDisplayLabel: displayLabelForZone(savedSelection.fromZoneId, options),
      toDisplayLabel: displayLabelForZone(savedSelection.toZoneId, options),
    );
  }

  var fromZoneId = fallback;
  var toZoneId = fallback;

  if (isJetLagTool) {
    fromZoneId = home?.timeZoneId ?? fallback;
    toZoneId = destination?.timeZoneId ?? fallback;
  } else if (reality == DashboardReality.destination) {
    fromZoneId = destination?.timeZoneId ?? fallback;
    toZoneId = home?.timeZoneId ?? fallback;
  } else {
    fromZoneId = home?.timeZoneId ?? fallback;
    toZoneId = destination?.timeZoneId ?? fallback;
  }

  if (fromZoneId == toZoneId) {
    toZoneId = options.where((o) => o.id != fromZoneId).isNotEmpty
        ? options.firstWhere((o) => o.id != fromZoneId).id
        : 'UTC';
  }

  return TimeToolDefaults(
    fromZoneId: fromZoneId,
    toZoneId: toZoneId,
    fromDisplayLabel: displayLabelForZone(fromZoneId, options),
    toDisplayLabel: displayLabelForZone(toZoneId, options),
  );
}
