import 'package:flutter/material.dart';

import '../../../models/place.dart';
import '../../../utils/timezone_utils.dart';
import '../models/dashboard_copy.dart';
import '../models/dashboard_session_controller.dart';
import '../models/flight_time_estimator.dart';
import '../models/jet_lag_planner.dart';
import '../models/place_geo_lookup.dart';
import '../models/time_zone_catalog.dart';
import 'tool_time_surface.dart';

@immutable
class ToolTimeWorkspace extends StatelessWidget {
  final String toolId;
  final Place? home;
  final Place? destination;
  final bool prefer24h;
  final bool isJetLagDeltaTool;
  final bool isWorldClockMapTool;
  final bool isTimeZoneConverterTool;
  final bool showAddWidget;
  final String fromZoneId;
  final String toZoneId;
  final String? fromDisplayLabelOverride;
  final String? toDisplayLabelOverride;
  final List<TimeZoneOption> options;
  final List<ConversionRecord> history;
  final TextEditingController timeConvertController;
  final String? resultLine;
  final int jetLagBedtimeMinutes;
  final int jetLagWakeMinutes;
  final bool jetLagOverlapExpanded;
  final bool jetLagTipsAutoRotateEnabled;
  final int jetLagTipIndex;
  final ToolTimeSurfaceTheme theme;
  final VoidCallback onPickFromZone;
  final VoidCallback onPickToZone;
  final VoidCallback onSwapZones;
  final VoidCallback? onAddWidget;
  final VoidCallback onRunConversion;
  final VoidCallback? onClearHistory;
  final VoidCallback onPickBedtime;
  final VoidCallback onPickWakeTime;
  final VoidCallback? onExpandOverlap;

  const ToolTimeWorkspace({
    super.key,
    required this.toolId,
    required this.home,
    required this.destination,
    required this.prefer24h,
    required this.isJetLagDeltaTool,
    required this.isWorldClockMapTool,
    required this.isTimeZoneConverterTool,
    required this.showAddWidget,
    required this.fromZoneId,
    required this.toZoneId,
    required this.fromDisplayLabelOverride,
    required this.toDisplayLabelOverride,
    required this.options,
    required this.history,
    required this.timeConvertController,
    required this.resultLine,
    required this.jetLagBedtimeMinutes,
    required this.jetLagWakeMinutes,
    required this.jetLagOverlapExpanded,
    required this.jetLagTipsAutoRotateEnabled,
    required this.jetLagTipIndex,
    required this.theme,
    required this.onPickFromZone,
    required this.onPickToZone,
    required this.onSwapZones,
    required this.onAddWidget,
    required this.onRunConversion,
    required this.onClearHistory,
    required this.onPickBedtime,
    required this.onPickWakeTime,
    required this.onExpandOverlap,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    String labelFor(String id) => options
        .firstWhere(
          (option) => option.id == id,
          orElse: () => (id: id, label: id, subtitle: null),
        )
        .label;

    final fromDisplayLabel = fromDisplayLabelOverride ?? labelFor(fromZoneId);
    final toDisplayLabel = toDisplayLabelOverride ?? labelFor(toZoneId);

    final nowUtc = DateTime.now().toUtc();
    final fromNow = TimezoneUtils.nowInZone(fromZoneId, nowUtc: nowUtc);
    final toNow = TimezoneUtils.nowInZone(toZoneId, nowUtc: nowUtc);
    final jetLagPlan = JetLagPlanner.planFromZoneTimes(
      fromNow: fromNow,
      toNow: toNow,
    );

    String clock(ZoneTime zoneTime) {
      return TimezoneUtils.formatClock(zoneTime, use24h: prefer24h);
    }

    String zoneMeta(ZoneTime zoneTime) {
      final minutes = zoneTime.offsetMinutes;
      final sign = minutes >= 0 ? '+' : '-';
      final abs = minutes.abs();
      final hh = (abs ~/ 60).toString().padLeft(2, '0');
      final mm = (abs % 60).toString().padLeft(2, '0');
      return 'UTC$sign$hh:$mm ${zoneTime.abbreviation}';
    }

    final deltaMetricLabel = jetLagPlan.deltaLabelForUi;
    final homeGeo = PlaceGeoLookup.forPlace(home);
    final destinationGeo = PlaceGeoLookup.forPlace(destination);
    final flightEstimate = FlightTimeEstimator.estimate(
      fromLat: homeGeo?.lat,
      fromLon: homeGeo?.lon,
      toLat: destinationGeo?.lat,
      toLon: destinationGeo?.lon,
    );
    final fromLabelRaw = _cleanDisplayLabel(
      fromDisplayLabel,
      labelFor(fromZoneId),
    );
    final toLabelRaw = _cleanDisplayLabel(toDisplayLabel, labelFor(toZoneId));
    final fromCity = _cityNameFromLabel(fromLabelRaw, labelFor(fromZoneId));
    final toCity = _cityNameFromLabel(toLabelRaw, labelFor(toZoneId));
    final fromCountryCode = _countryCodeFromLabel(fromLabelRaw);
    final toCountryCode = _countryCodeFromLabel(toLabelRaw);
    final fromFlag = _countryFlag(fromCountryCode);
    final toFlag = _countryFlag(toCountryCode);
    final fromPrefix = fromFlag.isEmpty ? '' : '$fromFlag ';
    final toPrefix = toFlag.isEmpty ? '' : '$toFlag ';

    final sections = <Widget>[];

    if (isJetLagDeltaTool ||
        (!isWorldClockMapTool && !isTimeZoneConverterTool)) {
      final dateImpact = JetLagPlanner.dateImpactLabel(
        fromLocal: fromNow.local,
        toLocal: toNow.local,
      );
      final directionCompact = DashboardCopy.timeDirection(
        context: context,
        direction: jetLagPlan.direction,
      );
      final dateImpactCompactRaw = dateImpact
          .replaceFirst('Destination is ', '')
          .replaceFirst('calendar ', '');
      final dateImpactCompact = DashboardCopy.dateImpactTitleCase(
        dateImpactCompactRaw,
      );
      sections.add(
        ToolTimeFactsCard(
          title: DashboardCopy.factsTitle(
            context,
            isJetLagTool: isJetLagDeltaTool,
          ),
          showDualAnalogClocks: !isJetLagDeltaTool && !isTimeZoneConverterTool,
          fromCity: fromCity,
          toCity: toCity,
          fromPrefix: fromPrefix,
          toPrefix: toPrefix,
          fromLocalTime: fromNow.local,
          toLocalTime: toNow.local,
          fromDigitalHud: '${clock(fromNow)} ${fromNow.abbreviation}',
          toDigitalHud: '${clock(toNow)} ${toNow.abbreviation}',
          fromClockLine: '${clock(fromNow)} (${zoneMeta(fromNow)})',
          toClockLine: '${clock(toNow)} (${zoneMeta(toNow)})',
          offsetLabel: DashboardCopy.timeFactsOffsetLabel(context),
          offsetValue: isJetLagDeltaTool
              ? '$toPrefix$toCity vs $fromPrefix$fromCity: $deltaMetricLabel · $directionCompact'
              : '$toPrefix$toCity vs $fromPrefix$fromCity: $deltaMetricLabel',
          dateLabel: isJetLagDeltaTool
              ? DashboardCopy.timeFactsDateLabel(context)
              : null,
          dateValue: isJetLagDeltaTool ? dateImpactCompact : null,
          flightLabel: isJetLagDeltaTool && flightEstimate != null
              ? DashboardCopy.timeFactsFlightLabel(context)
              : null,
          flightValue: isJetLagDeltaTool && flightEstimate != null
              ? flightEstimate.factsLabel.replaceFirst(
                  'Estimated flight time: ',
                  '',
                )
              : null,
          theme: theme,
        ),
      );
    }

    if (isJetLagDeltaTool) {
      final showOverlapHints = true;
      final gateOverlap = jetLagPlan.absDeltaHours <= 3;
      final showOverlapDetails =
          showOverlapHints && (!gateOverlap || jetLagOverlapExpanded);
      final targetBedtime = _jetLagShiftedMinutes(
        baseMinutes: jetLagBedtimeMinutes,
        plan: jetLagPlan,
      );
      final targetWake = _jetLagShiftedMinutes(
        baseMinutes: jetLagWakeMinutes,
        plan: jetLagPlan,
      );
      final tonightSleep = jetLagPlan.isNoShift
          ? _formatMinutesOfDay(jetLagBedtimeMinutes, use24h: prefer24h)
          : _formatMinutesOfDay(targetBedtime, use24h: prefer24h);
      final tonightWake = jetLagPlan.isNoShift
          ? _formatMinutesOfDay(jetLagWakeMinutes, use24h: prefer24h)
          : _formatMinutesOfDay(targetWake, use24h: prefer24h);
      final baselineSleep = _formatMinutesOfDay(
        jetLagBedtimeMinutes,
        use24h: prefer24h,
      );
      final baselineWake = _formatMinutesOfDay(
        jetLagWakeMinutes,
        use24h: prefer24h,
      );

      String overlapFor({required int destHour, required int destMinute}) {
        final destLocal = DateTime(
          toNow.local.year,
          toNow.local.month,
          toNow.local.day,
          destHour,
          destMinute,
        );
        final asUtc = TimezoneUtils.localToUtc(toZoneId, destLocal);
        final homeAtThatTime = TimezoneUtils.nowInZone(
          fromZoneId,
          nowUtc: asUtc,
        );
        return TimezoneUtils.formatClock(homeAtThatTime, use24h: prefer24h);
      }

      final overlapMorning = overlapFor(destHour: 9, destMinute: 0);
      final overlapEvening = overlapFor(destHour: 20, destMinute: 0);
      final tipPool = DashboardCopy.jetLagTips(
        plan: jetLagPlan,
        destinationLabel: labelFor(toZoneId),
      );
      final tipIndex = jetLagTipsAutoRotateEnabled
          ? jetLagTipIndex % tipPool.length
          : 0;
      final tipText = tipPool[tipIndex];
      final fromCityPlan = home?.cityName ?? labelFor(fromZoneId);
      final toCityPlan = destination?.cityName ?? labelFor(toZoneId);

      sections.add(
        ToolJetLagPlannerCard(
          title: DashboardCopy.jetLagPlanTitle(context),
          offsetLabel: DashboardCopy.timeFactsOffsetLabel(context),
          bandLabelTitle: DashboardCopy.jetLagBandLabel(context),
          dailyShiftLabelTitle: DashboardCopy.jetLagDailyShiftLabel(context),
          deltaMetricLabel: deltaMetricLabel,
          bandLabel: jetLagPlan.bandLabel,
          adjustmentDays: jetLagPlan.adjustmentDays,
          dailyShiftLabel: jetLagPlan.dailyShiftLabel,
          bedtimeButtonLabel: DashboardCopy.jetLagBedtimeButton(
            context,
            _formatMinutesOfDay(jetLagBedtimeMinutes, use24h: prefer24h),
          ),
          wakeButtonLabel: DashboardCopy.jetLagWakeButton(
            context,
            _formatMinutesOfDay(jetLagWakeMinutes, use24h: prefer24h),
          ),
          tonightTargetLabel: DashboardCopy.jetLagTonightTargetLabel(context),
          tonightScheduleText:
              '${DashboardCopy.jetLagSleepPrefix(context)}$tonightSleep${DashboardCopy.jetLagWakePrefix(context)}$tonightWake',
          baselineLabel: !jetLagPlan.isNoShift
              ? DashboardCopy.jetLagBaselineLabel(context)
              : null,
          baselineScheduleText: !jetLagPlan.isNoShift
              ? '${DashboardCopy.jetLagSleepPrefix(context)}$baselineSleep${DashboardCopy.jetLagWakePrefix(context)}$baselineWake'
              : null,
          quickTipsTitle: DashboardCopy.quickTipsTitle(context),
          tipText: tipText,
          tipKeySuffix: tipIndex,
          callWindowsTitle: DashboardCopy.callWindowsTitle(context),
          showOverlapHints: showOverlapHints,
          showOverlapDetails: showOverlapDetails,
          showOverlapExpandCta: gateOverlap && !jetLagOverlapExpanded,
          showCallWindowsLabel: DashboardCopy.showCallWindowsCta(context),
          overlapIntro: DashboardCopy.overlapIntro(context),
          overlapMorningLine: _styledCallWindowLine(
            context,
            line: DashboardCopy.jetLagCallWindowMorning(
              context,
              toCity: toCityPlan,
              overlapMorning: overlapMorning,
              fromCity: fromCityPlan,
            ),
            planToCity: toCityPlan,
            planFromCity: fromCityPlan,
          ),
          overlapEveningLine: _styledCallWindowLine(
            context,
            line: DashboardCopy.jetLagCallWindowEvening(
              context,
              toCity: toCityPlan,
              overlapEvening: overlapEvening,
              fromCity: fromCityPlan,
            ),
            planToCity: toCityPlan,
            planFromCity: fromCityPlan,
          ),
          theme: theme,
          onPickBedtime: onPickBedtime,
          onPickWakeTime: onPickWakeTime,
          onExpandOverlap: gateOverlap && !jetLagOverlapExpanded
              ? onExpandOverlap
              : null,
        ),
      );
    }

    if (isWorldClockMapTool) {
      final worldFromCity = _cityFromLabel(
        fromDisplayLabel,
        labelFor(fromZoneId),
      );
      final worldToCity = _cityFromLabel(toDisplayLabel, labelFor(toZoneId));
      final fromOffsetHours = fromNow.offsetMinutes / 60.0;
      final toOffsetHours = toNow.offsetMinutes / 60.0;
      final deltaHours = ((toNow.offsetMinutes - fromNow.offsetMinutes) / 60.0)
          .toStringAsFixed(1);
      final sameZone = fromNow.offsetMinutes == toNow.offsetMinutes;
      sections.add(
        ToolWorldTimeMapCard(
          title: DashboardCopy.worldTimeZonesTitle(context),
          summary: sameZone
              ? DashboardCopy.worldTimeSameZoneSummary(
                  context,
                  fromCity: worldFromCity,
                  toCity: worldToCity,
                )
              : DashboardCopy.worldTimeOffsetSummary(
                  context,
                  fromCity: worldFromCity,
                  toCity: worldToCity,
                  deltaHours:
                      '${deltaHours.startsWith('-') ? '' : '+'}$deltaHours',
                ),
          fromCity: worldFromCity,
          toCity: worldToCity,
          fromOffsetHours: fromOffsetHours,
          toOffsetHours: toOffsetHours,
          theme: theme,
        ),
      );
    }

    if (isTimeZoneConverterTool) {
      sections.add(
        ToolTimeConverterSection(
          toolId: toolId,
          title: DashboardCopy.convertLocalTimeTitle(context),
          helperText: DashboardCopy.convertLocalTimeHelper(
            context,
            fromDisplayLabel,
          ),
          inputHint: DashboardCopy.timeConverterInputHint(context),
          convertLabel: DashboardCopy.convertTimeCta(context),
          resultPlaceholderInput: DashboardCopy.resultPlaceholderInput(context),
          resultPlaceholderOutput: DashboardCopy.resultPlaceholderOutput(
            context,
          ),
          controller: timeConvertController,
          resultLine: resultLine,
          theme: theme,
          onRunConversion: onRunConversion,
        ),
      );
      sections.add(
        ToolTimeHistorySection(
          history: history,
          historyTitle: DashboardCopy.historyTitle(context),
          clearLabel: DashboardCopy.clearCta(context),
          emptyHistoryLabel: DashboardCopy.historyEmptyLabel(context),
          theme: theme,
          onClear: history.isEmpty ? null : onClearHistory,
        ),
      );
    }

    return ToolTimeSurface(
      toolId: toolId,
      fromZoneTitle: DashboardCopy.timeFromZoneTitle(
        context,
        isJetLagTool: isJetLagDeltaTool,
      ),
      fromDisplayLabel: fromDisplayLabel,
      toZoneTitle: DashboardCopy.timeToZoneTitle(
        context,
        isJetLagTool: isJetLagDeltaTool,
      ),
      toDisplayLabel: toDisplayLabel,
      showAddWidget: showAddWidget,
      addWidgetLabel: DashboardCopy.addWidgetCta(context),
      swapLabel: DashboardCopy.swapCta(context),
      theme: theme,
      onPickFromZone: onPickFromZone,
      onPickToZone: onPickToZone,
      onSwapZones: onSwapZones,
      onAddWidget: onAddWidget,
      sections: sections,
    );
  }

  int _normalizeMinutesOfDay(int minutes) {
    var out = minutes % (24 * 60);
    if (out < 0) out += 24 * 60;
    return out;
  }

  String _formatMinutesOfDay(int minutes, {required bool use24h}) {
    final norm = _normalizeMinutesOfDay(minutes);
    final hh = norm ~/ 60;
    final mm = (norm % 60).toString().padLeft(2, '0');
    if (use24h) {
      return '${hh.toString().padLeft(2, '0')}:$mm';
    }
    final isPm = hh >= 12;
    var h12 = hh % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:$mm ${isPm ? 'PM' : 'AM'}';
  }

  int _jetLagShiftedMinutes({
    required int baseMinutes,
    required JetLagPlan plan,
  }) {
    if (plan.isNoShift) return baseMinutes;
    final delta = plan.direction == JetLagDirection.eastbound
        ? -plan.dailyShiftMinutes
        : plan.dailyShiftMinutes;
    return _normalizeMinutesOfDay(baseMinutes + delta);
  }

  String _countryFlag(String countryCode) {
    final cc = countryCode.trim().toUpperCase();
    if (cc.length != 2) return '';
    final first = cc.codeUnitAt(0);
    final second = cc.codeUnitAt(1);
    if (first < 65 || first > 90 || second < 65 || second > 90) return '';
    return String.fromCharCodes(<int>[first + 127397, second + 127397]);
  }

  String _cleanDisplayLabel(String raw, String fallback) {
    final cleaned = raw
        .replaceFirst(RegExp(r'^\s*(Home|Destination)\s*·\s*'), '')
        .trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }

  String _countryCodeFromLabel(String label) {
    final parts = label.split(',');
    if (parts.length < 2) return '';
    final tail = parts.last.trim();
    if (RegExp(r'^[A-Za-z]{2}$').hasMatch(tail)) return tail.toUpperCase();
    return '';
  }

  String _cityNameFromLabel(String label, String fallback) {
    final pieces = label.split(',');
    final city = pieces.first.trim();
    return city.isEmpty ? fallback : city;
  }

  String _cityFromLabel(String raw, String fallback) {
    final cleaned = raw
        .replaceFirst(RegExp(r'^\s*(Home|Destination)\s*·\s*'), '')
        .trim();
    final comma = cleaned.indexOf(',');
    if (comma <= 0) return cleaned.isEmpty ? fallback : cleaned;
    final city = cleaned.substring(0, comma).trim();
    return city.isEmpty ? fallback : city;
  }

  InlineSpan _styledCallWindowLine(
    BuildContext context, {
    required String line,
    required String planToCity,
    required String planFromCity,
  }) {
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.textPrimary.withAlpha(235),
    );
    final toCityStyle = baseStyle?.copyWith(
      color: theme.warningTone.withAlpha(242),
      fontWeight: FontWeight.w800,
    );
    final fromCityStyle = baseStyle?.copyWith(
      color: theme.infoTone.withAlpha(238),
      fontWeight: FontWeight.w800,
    );
    final timeStyle = baseStyle?.copyWith(
      color: theme.textPrimary.withAlpha(248),
      fontWeight: FontWeight.w900,
    );
    final timeMatches = RegExp(r'\b\d{1,2}:\d{2}\b').allMatches(line).toList();
    final spans = <InlineSpan>[];
    var cursor = 0;
    while (cursor < line.length) {
      final toMatchAt = planToCity.isEmpty
          ? -1
          : line.indexOf(planToCity, cursor);
      final fromMatchAt = planFromCity.isEmpty
          ? -1
          : line.indexOf(planFromCity, cursor);
      var timeMatchAt = -1;
      Match? nextTimeMatch;
      for (final match in timeMatches) {
        if (match.start >= cursor) {
          timeMatchAt = match.start;
          nextTimeMatch = match;
          break;
        }
      }
      final hasToMatch = toMatchAt >= 0;
      final hasFromMatch = fromMatchAt >= 0;
      final hasTimeMatch = timeMatchAt >= 0 && nextTimeMatch != null;
      if (!hasToMatch && !hasFromMatch && !hasTimeMatch) {
        spans.add(TextSpan(text: line.substring(cursor), style: baseStyle));
        break;
      }
      var matchStart = -1;
      var matchToken = '';
      var matchStyle = baseStyle;
      if (hasTimeMatch &&
          (!hasToMatch || timeMatchAt <= toMatchAt) &&
          (!hasFromMatch || timeMatchAt <= fromMatchAt)) {
        matchStart = timeMatchAt;
        matchToken = nextTimeMatch.group(0) ?? '';
        matchStyle = timeStyle;
      } else if (hasToMatch && (!hasFromMatch || toMatchAt <= fromMatchAt)) {
        matchStart = toMatchAt;
        matchToken = planToCity;
        matchStyle = toCityStyle;
      } else if (hasFromMatch) {
        matchStart = fromMatchAt;
        matchToken = planFromCity;
        matchStyle = fromCityStyle;
      }
      if (matchStart > cursor) {
        spans.add(
          TextSpan(text: line.substring(cursor, matchStart), style: baseStyle),
        );
      }
      spans.add(TextSpan(text: matchToken, style: matchStyle));
      cursor = matchStart + matchToken.length;
    }
    return TextSpan(children: spans, style: baseStyle);
  }
}
