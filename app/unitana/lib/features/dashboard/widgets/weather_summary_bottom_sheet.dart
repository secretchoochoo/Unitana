import 'package:flutter/material.dart';

import '../../../models/place.dart';
import '../../../theme/dracula_palette.dart';
import '../../../utils/timezone_utils.dart';

import '../models/dashboard_live_data.dart';

/// Lightweight, provider-agnostic weather details sheet.
///
/// Contract:
/// - Purely presentational (no network calls).
/// - Device clock remains source of truth; timezone IDs are display-only.
/// - Safe in hermetic/demo mode (shows placeholders when data is missing).
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final refreshedAt = liveData.lastRefreshedAt;
    final refreshedLabel = refreshedAt == null
        ? 'Not updated yet'
        : 'Updated ${_relativeAge(now: DateTime.now(), then: refreshedAt)}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          key: const ValueKey('weather_summary_sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Weather',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
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
            const SizedBox(height: 12),
            _placeCard(context, place: destination, label: 'Destination'),
            const SizedBox(height: 10),
            _placeCard(context, place: home, label: 'Home'),
            const SizedBox(height: 12),
            Text(
              'Provider-agnostic: data comes from your selected backend.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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

    String sunCell(DateTime? utc) {
      if (utc == null) return '--:--';
      final zt = TimezoneUtils.nowInZone(place.timeZoneId, nowUtc: utc);
      return TimezoneUtils.formatClock(zt, use24h: place.use24h);
    }

    final sunrise = sunCell(sun?.sunriseUtc);
    final sunset = sunCell(sun?.sunsetUtc);

    final flag = _flagEmoji(place.countryCode);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
            const SizedBox(height: 10),
            _iconTable(
              context,
              headers: const ['☀️', '🌙'],
              values: [sunrise, sunset],
            ),
            const SizedBox(height: 8),
            _iconTable(
              context,
              headers: const ['🌬️', '💨'],
              values: [windPrimary, gustPrimary],
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withAlpha(160)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _relativeAge({required DateTime now, required DateTime then}) {
    final diff = now.difference(then);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inMinutes == 1) return '1 minute ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours == 1) return '1 hour ago';
    return '${diff.inHours} hours ago';
  }

  static String _flagEmoji(String countryCode) {
    final cc = countryCode.toUpperCase();
    if (cc.length != 2) return '🏳️';
    final a = cc.codeUnitAt(0);
    final b = cc.codeUnitAt(1);
    // Regional indicator symbols start at 0x1F1E6 for 'A'.
    const base = 0x1F1E6;
    final first = base + (a - 65);
    final second = base + (b - 65);
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}
