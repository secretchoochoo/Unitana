import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/place.dart';
import '../../../theme/dracula_palette.dart';
import '../../../utils/timezone_utils.dart';

import '../models/dashboard_copy.dart';
import '../models/freshness_copy.dart';
import '../models/dashboard_live_data.dart';

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
            ? DashboardCopy.notUpdated
            : DashboardCopy.updated(
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
                            DashboardCopy.weatherTitle,
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
                          message: DashboardCopy.refreshWeatherTooltip,
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
                          message: DashboardCopy.closeWeatherTooltip,
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
                _placeCard(
                  context,
                  place: destination,
                  label: DashboardCopy.destinationLabel,
                ),
                const SizedBox(height: 6),
                _placeCard(
                  context,
                  place: home,
                  label: DashboardCopy.homeLabel,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeCard(
    BuildContext context, {
    required Place? place,
    required String label,
  }) {
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
            '$label: Not set',
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

    final condition = (weather?.conditionText ?? '—').trim();

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
      if (value <= 50) return 'Good';
      if (value <= 100) return 'Moderate';
      if (value <= 150) return 'Unhealthy (Sensitive)';
      if (value <= 200) return 'Unhealthy';
      if (value <= 300) return 'Very Unhealthy';
      return 'Hazardous';
    }

    final aqiText = aqi == null ? '—' : '$aqi (${aqiBand(aqi)})';
    String pollenLabel(double value) {
      String band;
      if (value < 1.0) {
        band = 'Low';
      } else if (value < 2.5) {
        band = 'Moderate';
      } else if (value < 3.5) {
        band = 'High';
      } else {
        band = 'Very High';
      }
      return '${value.toStringAsFixed(1)}/5 ($band)';
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

    return DecoratedBox(
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
            Row(
              children: [
                Text(flag, style: theme.textTheme.titleLarge),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$label  ·  ${place.cityName}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        condition,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tempPrimary,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: DraculaPalette.green,
                      ),
                    ),
                    Text(
                      tempSecondary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            _iconTable(
              context,
              headers: const ['☀️ Sunrise', '🌙 Sunset'],
              values: [sunrise, sunset],
              secondaryValues: [sunriseAlt, sunsetAlt],
            ),
            const SizedBox(height: 4),
            _iconTable(
              context,
              headers: const ['🌬️ Wind', '💨 Gust'],
              values: [windPrimary, gustPrimary],
              secondaryValues: [windSecondary, gustSecondary],
            ),
            const SizedBox(height: 4),
            _iconTable(
              context,
              headers: const ['🌫️ AQI (US)', '🌼 Pollen (0-5)'],
              values: [aqiText, pollenText],
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
      fontWeight: FontWeight.w900,
      color: cs.onSurface,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: cs.onSurface.withAlpha(230),
    );
    final secondaryStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurfaceVariant.withAlpha(220),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withAlpha(160)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    const SizedBox(height: 4),
                    Text(
                      values[i],
                      style: valueStyle,
                      textAlign: TextAlign.center,
                    ),
                    if (secondaryValues != null) ...[
                      const SizedBox(height: 2),
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
