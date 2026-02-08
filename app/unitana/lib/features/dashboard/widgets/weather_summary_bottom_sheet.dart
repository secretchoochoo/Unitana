import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/place.dart';
import '../../../theme/dracula_palette.dart';
import '../../../utils/timezone_utils.dart';

import '../models/dashboard_copy.dart';
import '../models/freshness_copy.dart';
import '../models/dashboard_live_data.dart';
import 'hero_alive_marquee.dart';
import 'pulse_swap_icon.dart';

class WeatherSummaryBottomSheet extends StatelessWidget {
  final DashboardLiveDataController liveData;
  final Place? home;
  final Place? destination;

  const WeatherSummaryBottomSheet({
    super.key,
    required this.liveData,
    required this.home,
    required this.destination,
  });

  static Future<void> show(
    BuildContext context, {
    required DashboardLiveDataController liveData,
    required Place? home,
    required Place? destination,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => WeatherSummaryBottomSheet(
        liveData: liveData,
        home: home,
        destination: destination,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: liveData,
      builder: (context, _) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;

        final refreshedAt = liveData.lastRefreshedAt;
        final staleSuffix = DashboardCopy.weatherStaleSuffix(
          isStale:
              liveData.isStale && !liveData.isRefreshing && refreshedAt != null,
        );
        final refreshedLabelBase = refreshedAt == null
            ? DashboardCopy.notUpdated(context)
            : DashboardCopy.updated(
                context,
                FreshnessCopy.relativeAgeShort(
                  now: DateTime.now(),
                  then: refreshedAt,
                ),
              );
        final refreshedLabel = '$refreshedLabelBase$staleSuffix';

        final places = <Place>[
          if (destination != null) destination!,
          if (home != null) home!,
        ];

        Future<void> refreshNow() async {
          if (liveData.isRefreshing || places.isEmpty) return;
          await liveData.refreshAll(places: places);
        }

        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.94,
            alignment: Alignment.bottomCenter,
            child: ListView(
              key: const ValueKey('weather_summary_sheet'),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 96),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DashboardCopy.weatherTitle(context),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.robotoSlab(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            refreshedLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: DashboardCopy.refreshWeatherTooltip(context),
                          child: OutlinedButton(
                            key: const ValueKey('weather_summary_refresh'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(44, 34),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide(
                                color: DraculaPalette.comment.withAlpha(160),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: liveData.isRefreshing
                                ? null
                                : refreshNow,
                            child: Icon(
                              liveData.isRefreshing
                                  ? Icons.hourglass_top_rounded
                                  : Icons.refresh_rounded,
                              size: 18,
                              color: DraculaPalette.foreground.withAlpha(220),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: DashboardCopy.closeWeatherTooltip(context),
                          child: OutlinedButton(
                            key: const ValueKey('weather_summary_close'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(44, 34),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide(
                                color: DraculaPalette.comment.withAlpha(160),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: DraculaPalette.foreground.withAlpha(220),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _placeCard(context, place: destination),
                const SizedBox(height: 6),
                _placeCard(context, place: home),
              ],
            ),
          ),
        );
      },
    );
  }

  String _dualTempLabel(double c, {required bool preferMetric}) {
    final f = (c * 9 / 5) + 32;
    if (preferMetric) {
      return '${c.round()}°C/${f.round()}°F';
    }
    return '${f.round()}°F/${c.round()}°C';
  }

  String _weekdayLabel(DateTime local) {
    const names = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final idx = local.weekday - 1;
    if (idx < 0 || idx >= names.length) return '—';
    return names[idx];
  }

  bool _isNightForPlace(Place place, {required SunTimesSnapshot? sun}) {
    final nowUtc = liveData.nowUtc;
    if (sun != null) {
      final now = TimezoneUtils.nowInZone(
        place.timeZoneId,
        nowUtc: nowUtc,
      ).local;
      final sunriseLocal = TimezoneUtils.nowInZone(
        place.timeZoneId,
        nowUtc: sun.sunriseUtc,
      ).local;
      final sunsetLocal = TimezoneUtils.nowInZone(
        place.timeZoneId,
        nowUtc: sun.sunsetUtc,
      ).local;
      return now.isBefore(sunriseLocal) || now.isAfter(sunsetLocal);
    }
    final hour = TimezoneUtils.nowInZone(
      place.timeZoneId,
      nowUtc: nowUtc,
    ).local.hour;
    return hour < 6 || hour >= 20;
  }

  Widget _placeCard(BuildContext context, {required Place? place}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (place == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            DashboardCopy.weatherCityNotSet(context),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final weather = liveData.weatherFor(place);
    final sun = liveData.sunFor(place);
    final env = liveData.envFor(place);

    final preferMetric = (place.unitSystem == 'metric');
    final tempC = weather?.temperatureC;
    final tempF = tempC == null ? null : (tempC * 9 / 5) + 32;
    final tempPrimary = tempC == null
        ? '—'
        : preferMetric
        ? '${tempC.round()}°C'
        : '${tempF!.round()}°F';
    final tempSecondary = tempC == null
        ? '—'
        : preferMetric
        ? '${tempF!.round()}°F'
        : '${tempC.round()}°C';

    final condition = DashboardCopy.weatherConditionLabel(
      context,
      sceneKey: weather?.sceneKey,
      rawText: weather?.conditionText,
    );

    final windKmh = weather?.windKmh;
    final gustKmh = weather?.gustKmh;

    double? toMph(double? kmh) => kmh == null ? null : (kmh * 0.621371);

    final windPrimary = windKmh == null
        ? '—'
        : preferMetric
        ? '${windKmh.round()} km/h'
        : '${toMph(windKmh)!.round()} mph';
    final gustPrimary = gustKmh == null
        ? '—'
        : preferMetric
        ? '${gustKmh.round()} km/h'
        : '${toMph(gustKmh)!.round()} mph';
    final windSecondary = windKmh == null
        ? '—'
        : preferMetric
        ? '${toMph(windKmh)!.round()} mph'
        : '${windKmh.round()} km/h';
    final gustSecondary = gustKmh == null
        ? '—'
        : preferMetric
        ? '${toMph(gustKmh)!.round()} mph'
        : '${gustKmh.round()} km/h';

    final aqi = env?.usAqi;
    final pollen = env?.pollenIndex;
    String aqiBand(int value) {
      if (value <= 50) return DashboardCopy.weatherAqiBand(context, 'good');
      if (value <= 100) {
        return DashboardCopy.weatherAqiBand(context, 'moderate');
      }
      if (value <= 150) {
        return DashboardCopy.weatherAqiBand(context, 'unhealthySensitive');
      }
      if (value <= 200) {
        return DashboardCopy.weatherAqiBand(context, 'unhealthy');
      }
      if (value <= 300) {
        return DashboardCopy.weatherAqiBand(context, 'veryUnhealthy');
      }
      return DashboardCopy.weatherAqiBand(context, 'hazardous');
    }

    final aqiText = aqi == null ? '—' : '$aqi (${aqiBand(aqi)})';
    String pollenLabel(double value) {
      String band;
      if (value < 1.0) {
        band = DashboardCopy.weatherPollenBand(context, 'low');
      } else if (value < 2.5) {
        band = DashboardCopy.weatherPollenBand(context, 'moderate');
      } else if (value < 3.5) {
        band = DashboardCopy.weatherPollenBand(context, 'high');
      } else {
        band = DashboardCopy.weatherPollenBand(context, 'veryHigh');
      }
      return '${value.toStringAsFixed(1)} ($band)';
    }

    final pollenText = pollen == null ? '—' : pollenLabel(pollen);

    String sunCell(DateTime? utc, bool use24h) {
      if (utc == null) return '--:--';
      final zt = TimezoneUtils.nowInZone(place.timeZoneId, nowUtc: utc);
      return TimezoneUtils.formatClock(zt, use24h: use24h);
    }

    final sunrise = sunCell(sun?.sunriseUtc, place.use24h);
    final sunset = sunCell(sun?.sunsetUtc, place.use24h);
    final sunriseAlt = sunCell(sun?.sunriseUtc, !place.use24h);
    final sunsetAlt = sunCell(sun?.sunsetUtc, !place.use24h);

    final flag = _flagEmoji(place.countryCode);
    final localNow = TimezoneUtils.nowInZone(
      place.timeZoneId,
      nowUtc: liveData.nowUtc,
    );
    final forecast = liveData.forecastFor(place);
    final hourly = (forecast?.hourly ?? const <HourlyForecastPoint>[])
        .where((h) => !h.timeUtc.isBefore(liveData.nowUtc))
        .take(6)
        .toList();
    final daily = (forecast?.daily ?? const <DailyForecastPoint>[])
        .take(7)
        .toList();
    final bannerDaily = daily.isEmpty ? null : daily.first;
    final bannerHigh = bannerDaily == null
        ? '—'
        : _dualTempLabel(
            bannerDaily.maxTemperatureC,
            preferMetric: preferMetric,
          );
    final bannerLow = bannerDaily == null
        ? '—'
        : _dualTempLabel(
            bannerDaily.minTemperatureC,
            preferMetric: preferMetric,
          );

    return DecoratedBox(
      key: ValueKey('weather_summary_place_card_${place.id}'),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: <Color>[
                    DraculaPalette.cyan.withAlpha(46),
                    DraculaPalette.purple.withAlpha(56),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: cs.outlineVariant.withAlpha(140)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTight = constraints.maxWidth < 340;
                    return Row(
                      children: [
                        SizedBox(
                          width: isTight ? 98 : 116,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              key: ValueKey(
                                'weather_summary_card_scene_${place.id}',
                              ),
                              height: isTight ? 56 : 64,
                              child: HeroAliveMarquee(
                                includeTestKeys: false,
                                compact: true,
                                isNight: _isNightForPlace(place, sun: sun),
                                sceneKey: weather?.sceneKey,
                                conditionLabel: condition,
                                renderConditionLabel: false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$flag ${place.cityName}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              Text(
                                '${TimezoneUtils.formatShortDate(localNow)} • ${TimezoneUtils.formatClock(localNow, use24h: place.use24h)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$tempPrimary  ·  $tempSecondary',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: DraculaPalette.green,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                condition,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          key: ValueKey(
                            'weather_summary_banner_hilo_${place.id}',
                          ),
                          width: isTight ? 80 : 94,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: cs.surface.withAlpha(40),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: cs.outlineVariant.withAlpha(140),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DashboardCopy.weatherBannerHighLow(context),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: isTight ? 9 : 10,
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '↑ $bannerHigh',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: isTight ? 9 : 10,
                                              color: DraculaPalette.orange,
                                              fontWeight: FontWeight.w900,
                                            ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '↓ $bannerLow',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: isTight ? 9 : 10,
                                              color: DraculaPalette.cyan,
                                              fontWeight: FontWeight.w900,
                                            ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 5),
            _iconTable(
              context,
              headers: <String>[
                DashboardCopy.weatherHeaderSunrise(context),
                DashboardCopy.weatherHeaderSunset(context),
              ],
              values: [sunrise, sunset],
              secondaryValues: [sunriseAlt, sunsetAlt],
            ),
            const SizedBox(height: 3),
            _iconTable(
              context,
              headers: <String>[
                DashboardCopy.weatherHeaderWind(context),
                DashboardCopy.weatherHeaderGust(context),
              ],
              values: [windPrimary, gustPrimary],
              secondaryValues: [windSecondary, gustSecondary],
            ),
            const SizedBox(height: 3),
            _iconTable(
              context,
              headers: <String>[
                DashboardCopy.weatherHeaderAqi(context),
                DashboardCopy.weatherHeaderPollen(context),
              ],
              values: [aqiText, pollenText],
            ),
            const SizedBox(height: 5),
            _ForecastToggleBarPanel(
              place: place,
              hourly: hourly,
              daily: daily,
              weekdayLabel: _weekdayLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconTable(
    BuildContext context, {
    required List<String> headers,
    required List<String> values,
    List<String>? secondaryValues,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final headerStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: cs.onSurface.withAlpha(230),
    );
    final secondaryStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.onSurfaceVariant.withAlpha(220),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withAlpha(160)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          children: [
            for (var i = 0; i < headers.length; i++)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      headers[i],
                      style: headerStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      values[i],
                      style: valueStyle,
                      textAlign: TextAlign.center,
                    ),
                    if (secondaryValues != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        secondaryValues[i],
                        style: secondaryStyle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _flagEmoji(String countryCode) {
    final cc = countryCode.toUpperCase();
    if (cc.length != 2) return '🏳️';
    final a = cc.codeUnitAt(0);
    final b = cc.codeUnitAt(1);
    const base = 0x1F1E6;
    final first = base + (a - 65);
    final second = base + (b - 65);
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}

class _ForecastToggleBarPanel extends StatefulWidget {
  final Place place;
  final List<HourlyForecastPoint> hourly;
  final List<DailyForecastPoint> daily;
  final String Function(DateTime local) weekdayLabel;

  const _ForecastToggleBarPanel({
    required this.place,
    required this.hourly,
    required this.daily,
    required this.weekdayLabel,
  });

  @override
  State<_ForecastToggleBarPanel> createState() =>
      _ForecastToggleBarPanelState();
}

class _ForecastToggleBarPanelState extends State<_ForecastToggleBarPanel> {
  bool _showDaily = false;

  void _toggleMode() {
    setState(() {
      _showDaily = !_showDaily;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasHourly = widget.hourly.isNotEmpty;
    final hasDaily = widget.daily.isNotEmpty;
    final hasAny = hasHourly || hasDaily;
    final showDaily = hasDaily && (!hasHourly || _showDaily);
    final label = DashboardCopy.weatherForecastModeLabel(
      context,
      daily: showDaily,
    );

    final bars = showDaily
        ? widget.daily
              .map(
                (d) => _TempBarDatum(
                  label: widget.weekdayLabel(
                    TimezoneUtils.nowInZone(
                      widget.place.timeZoneId,
                      nowUtc: d.dayUtc,
                    ).local,
                  ),
                  temperatureC: d.maxTemperatureC,
                ),
              )
              .toList()
        : widget.hourly
              .map(
                (h) => _TempBarDatum(
                  label: TimezoneUtils.formatClock(
                    TimezoneUtils.nowInZone(
                      widget.place.timeZoneId,
                      nowUtc: h.timeUtc,
                    ),
                    use24h: widget.place.use24h,
                  ),
                  temperatureC: h.temperatureC,
                ),
              )
              .toList();

    return InkWell(
      key: ValueKey('weather_summary_forecast_panel_${widget.place.id}'),
      borderRadius: BorderRadius.circular(10),
      onTap: hasHourly && hasDaily ? _toggleMode : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withAlpha(160)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      key: ValueKey(
                        'weather_summary_forecast_mode_${widget.place.id}_${showDaily ? 'daily' : 'hourly'}',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: DraculaPalette.yellow,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DashboardCopy.weatherForecastUnitsLegend(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: DashboardCopy.weatherForecastSwapTooltip(context),
                    child: GestureDetector(
                      key: ValueKey(
                        'weather_summary_forecast_swap_${widget.place.id}',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTap: hasHourly && hasDaily ? _toggleMode : null,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: Center(
                          child: PulseSwapIcon(
                            color: DraculaPalette.cyan.withAlpha(220),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (!hasAny)
                Text(
                  DashboardCopy.weatherForecastUnavailable(context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                SizedBox(
                  key: ValueKey(
                    'weather_summary_forecast_chart_${widget.place.id}',
                  ),
                  height: 120,
                  child: _TempBarGraph(
                    bars: bars,
                    graphKey: showDaily
                        ? ValueKey('weather_summary_daily_${widget.place.id}')
                        : ValueKey('weather_summary_hourly_${widget.place.id}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TempBarDatum {
  final String label;
  final double temperatureC;

  const _TempBarDatum({required this.label, required this.temperatureC});
}

class _TempBarGraph extends StatelessWidget {
  final List<_TempBarDatum> bars;
  final Key graphKey;

  const _TempBarGraph({required this.bars, required this.graphKey});

  String _fLabel(double c) => '${((c * 9 / 5) + 32).round()}°F';
  String _cLabel(double c) => '${c.round()}°C';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final minC = bars.fold<double>(bars.first.temperatureC, (a, b) {
      return math.min(a, b.temperatureC);
    });
    final maxC = bars.fold<double>(bars.first.temperatureC, (a, b) {
      return math.max(a, b.temperatureC);
    });
    final range = math.max(1.0, maxC - minC);

    return Row(
      key: graphKey,
      children: [
        SizedBox(
          width: 44,
          child: _AxisLabels(
            top: _cLabel(maxC),
            bottom: _cLabel(minC),
            color: DraculaPalette.cyan,
          ),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface.withAlpha(18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final item in bars)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: LinearGradient(
                                      colors: [
                                        DraculaPalette.purple.withAlpha(220),
                                        DraculaPalette.pink.withAlpha(220),
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                  child: SizedBox(
                                    height:
                                        12 +
                                        (((item.temperatureC - minC) / range) *
                                            64),
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (final item in bars)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Text(
                              item.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: _AxisLabels(
            top: _fLabel(maxC),
            bottom: _fLabel(minC),
            color: DraculaPalette.orange,
          ),
        ),
      ],
    );
  }
}

class _AxisLabels extends StatelessWidget {
  final String top;
  final String bottom;
  final Color color;

  const _AxisLabels({
    required this.top,
    required this.bottom,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          top,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        Text(
          bottom,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
