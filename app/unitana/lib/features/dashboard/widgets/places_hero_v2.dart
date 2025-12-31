import 'package:flutter/material.dart';

import '../../../models/place.dart';
import '../../../theme/theme_extensions.dart';
import '../../../utils/timezone_utils.dart';
import '../models/dashboard_live_data.dart';
import '../models/dashboard_session_controller.dart';

class PlacesHeroV2 extends StatelessWidget {
  final Place? home;
  final Place? destination;
  final DashboardSessionController session;
  final DashboardLiveDataController liveData;

  const PlacesHeroV2({
    super.key,
    required this.home,
    required this.destination,
    required this.session,
    required this.liveData,
  });

  @override
  Widget build(BuildContext context) {
    final primary = session.reality == DashboardReality.home
        ? home
        : destination;
    final secondary = session.reality == DashboardReality.home
        ? destination
        : home;

    final allPlaces = <Place>[
      if (home != null) home!,
      if (destination != null) destination!,
    ];
    liveData.ensureSeeded(allPlaces);

    final primaryWeather = liveData.weatherFor(primary);
    final secondaryWeather = liveData.weatherFor(secondary);

    final primaryZone = primary == null
        ? null
        : TimezoneUtils.nowInZone(primary.timeZoneId);
    final secondaryZone = secondary == null
        ? null
        : TimezoneUtils.nowInZone(secondary.timeZoneId);

    final delta = (primaryZone != null && secondaryZone != null)
        ? TimezoneUtils.deltaHours(primaryZone, secondaryZone)
        : null;

    final cs = Theme.of(context).colorScheme;
    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();
    // Keep this widget aligned with the existing layout token set.
    final radius = layout?.radiusCard ?? 20.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxHeight < 280 || constraints.maxWidth < 320;
        final pad = isCompact ? 10.0 : 14.0;
        final gap = isCompact ? 6.0 : 10.0;
        final sideWidth = isCompact ? 112.0 : 130.0;

        return Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(55),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: cs.outlineVariant.withAlpha(179),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SegmentedRealityToggle(
                home: home,
                destination: destination,
                selected: session.reality,
                onChanged: session.setReality,
                compact: isCompact,
              ),
              SizedBox(height: gap),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _LeftPrimaryBlock(
                        place: primary,
                        zone: primaryZone,
                        weather: primaryWeather,
                        liveData: liveData,
                        places: allPlaces,
                        secondaryPlace: secondary,
                        secondaryWeather: secondaryWeather,
                        compact: isCompact,
                      ),
                    ),
                    SizedBox(width: gap),
                    SizedBox(
                      width: sideWidth,
                      child: _RightSecondaryBlock(
                        place: secondary,
                        zone: secondaryZone,
                        deltaHours: delta,
                        weather: secondaryWeather,
                        compact: isCompact,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SegmentedRealityToggle extends StatelessWidget {
  final Place? home;
  final Place? destination;
  final DashboardReality selected;
  final ValueChanged<DashboardReality> onChanged;
  final bool compact;

  const _SegmentedRealityToggle({
    required this.home,
    required this.destination,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();
    final r = (layout?.radiusButton ?? 16.0) - 6;

    final leftLabel =
        '${_flagEmojiFromIso2(destination?.countryCode)} ${destination?.cityName ?? 'Destination'}';
    final rightLabel =
        '${_flagEmojiFromIso2(home?.countryCode)} ${home?.cityName ?? 'Home'}';

    return Container(
      height: compact ? 40 : 46,
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(40),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: cs.outlineVariant.withAlpha(160), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              key: const ValueKey('places_hero_segment_destination'),
              text: leftLabel,
              selected: selected == DashboardReality.destination,
              alignment: Alignment.centerLeft,
              compact: compact,
              onTap: () => onChanged(DashboardReality.destination),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              key: const ValueKey('places_hero_segment_home'),
              text: rightLabel,
              selected: selected == DashboardReality.home,
              alignment: Alignment.centerRight,
              compact: compact,
              onTap: () => onChanged(DashboardReality.home),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String text;
  final bool selected;
  final Alignment alignment;
  final bool compact;
  final VoidCallback onTap;

  const _SegmentButton({
    super.key,
    required this.text,
    required this.selected,
    required this.alignment,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();
    final r = (layout?.radiusButton ?? 16.0) - 7;

    return InkWell(
      borderRadius: BorderRadius.circular(r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
        alignment: alignment,
        decoration: BoxDecoration(
          color: selected ? cs.primary.withAlpha(55) : Colors.transparent,
          borderRadius: BorderRadius.circular(r),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignment == Alignment.centerRight
              ? TextAlign.right
              : TextAlign.left,
          style:
              (compact
                      ? Theme.of(context).textTheme.titleSmall
                      : Theme.of(context).textTheme.titleMedium)
                  ?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
        ),
      ),
    );
  }
}

enum _HeroMenuAction { refreshAll }

class _LeftPrimaryBlock extends StatelessWidget {
  final Place? place;
  final ZoneTime? zone;
  final WeatherSnapshot? weather;
  final DashboardLiveDataController liveData;
  final List<Place> places;
  final Place? secondaryPlace;
  final WeatherSnapshot? secondaryWeather;
  final bool compact;

  const _LeftPrimaryBlock({
    required this.place,
    required this.zone,
    required this.weather,
    required this.liveData,
    required this.places,
    required this.secondaryPlace,
    required this.secondaryWeather,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveCompact =
            compact ||
            constraints.maxHeight < 240 ||
            constraints.maxWidth < 260;

        final cs = Theme.of(context).colorScheme;
        final muted = cs.onSurface.withAlpha(170);
        final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: cs.onSurface.withAlpha(210),
          fontWeight: FontWeight.w600,
        );

        final timeText = (place == null || zone == null)
            ? '--'
            : '${TimezoneUtils.formatClock(zone!, use24h: place!.use24h)} '
                  '${zone!.abbreviation} · ${TimezoneUtils.formatShortDate(zone!)}';

        final primaryTemp = (place == null || weather == null)
            ? '--'
            : _formatTemp(place!, weather!);

        if (effectiveCompact) {
          final headline = place?.cityName ?? 'No place selected';
          final secondaryTemp =
              (secondaryPlace == null || secondaryWeather == null)
              ? ''
              : _formatTemp(secondaryPlace!, secondaryWeather!);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    key: const ValueKey('places_hero_refresh_all'),
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      liveData.refreshAll(places: places);
                    },
                    iconSize: 18,
                    tooltip: 'Refresh all',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          headline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: muted,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_HeroMenuAction>(
                    key: const ValueKey('places_hero_overflow_menu'),
                    tooltip: 'More',
                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                    onSelected: (action) {
                      switch (action) {
                        case _HeroMenuAction.refreshAll:
                          liveData.refreshAll(places: places);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _HeroMenuAction.refreshAll,
                        child: Text('Refresh all'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PartlyCloudyIcon(
                    size: 26,
                    muted: cs.onSurface.withAlpha(200),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            primaryTemp,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                          ),
                          if (secondaryTemp.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              secondaryTemp,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        final secondaryTemp =
            (secondaryPlace == null || secondaryWeather == null)
            ? ''
            : _formatTemp(secondaryPlace!, secondaryWeather!);

        final windLines = (place == null || weather == null)
            ? null
            : _windLines(place!, weather!);

        final currencyLines = _currencyLines(
          primary: place,
          secondary: secondaryPlace,
          eurToUsd: liveData.eurToUsd,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: cs.onSurface.withAlpha(190),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(timeText, style: titleStyle)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              key: const ValueKey('hero_primary_temp'),
              primaryTemp,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            if (secondaryTemp.isNotEmpty)
              Text(
                key: const ValueKey('hero_secondary_temp'),
                secondaryTemp,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: cs.onSurface.withAlpha(170),
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 10),
            if (windLines != null)
              Row(
                children: [
                  Icon(
                    Icons.air_rounded,
                    size: 18,
                    color: cs.onSurface.withAlpha(190),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          windLines.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: cs.onSurface.withAlpha(200),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          windLines.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: cs.onSurface.withAlpha(170),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.currency_exchange_rounded,
                  size: 18,
                  color: cs.onSurface.withAlpha(190),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyLines.$1,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: cs.onSurface.withAlpha(200),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyLines.$2,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withAlpha(170),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _RightSecondaryBlock extends StatelessWidget {
  final Place? place;
  final ZoneTime? zone;
  final int? deltaHours;
  final WeatherSnapshot? weather;
  final bool compact;

  const _RightSecondaryBlock({
    required this.place,
    required this.zone,
    required this.deltaHours,
    required this.weather,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withAlpha(170);

    final timeText = (place == null || zone == null)
        ? '--'
        : '${TimezoneUtils.formatClock(zone!, use24h: place!.use24h)} '
              '${zone!.abbreviation} · ${TimezoneUtils.formatShortDate(zone!)} '
              '${deltaHours == null ? '' : TimezoneUtils.formatDeltaLabel(deltaHours!)}';

    final tempText = (place == null || weather == null)
        ? ''
        : _formatTemp(place!, weather!);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              timeText.trim(),
              textAlign: TextAlign.right,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (weather != null)
                _PartlyCloudyIcon(size: 28, muted: cs.onSurface.withAlpha(200)),
              if (weather != null) const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tempText,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          timeText.trim(),
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        if (tempText.isNotEmpty)
          Text(
            tempText,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: _PartlyCloudyIcon(
            size: 40,
            muted: cs.onSurface.withAlpha(190),
          ),
        ),
      ],
    );
  }
}

class _PartlyCloudyIcon extends StatelessWidget {
  final double size;
  final Color muted;

  const _PartlyCloudyIcon({required this.size, required this.muted});

  @override
  Widget build(BuildContext context) {
    // Simple composed icon: sun behind cloud. No text.
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 4,
            child: Icon(
              Icons.wb_sunny_rounded,
              size: size * 0.55,
              color: muted,
            ),
          ),
          Positioned(
            left: 8,
            top: 12,
            child: Icon(Icons.cloud_rounded, size: size * 0.72, color: muted),
          ),
        ],
      ),
    );
  }
}

String _formatTemp(Place place, WeatherSnapshot w) {
  final degree = String.fromCharCode(0x00B0);
  final metric = place.unitSystem == 'metric';
  if (metric) {
    return '${w.temperatureC.round()}${degree}C';
  }
  final f = (w.temperatureC * 9 / 5) + 32;
  return '${f.round()}${degree}F';
}

/// Returns `(primary, secondary)` wind lines.
///
/// Primary follows the active unit system for the current reality; secondary
/// shows the other unit system as a compact reference.

/// Converts kilometers per hour to miles per hour.
///
/// Kept as a file-level helper so it can be reused anywhere in this widget without
/// needing a BuildContext.
double _kmhToMph(num kmh) => kmh.toDouble() * 0.621371;

(String, String) _windLines(Place place, WeatherSnapshot w) {
  final metricActive = place.unitSystem == 'metric';

  final windKmh = w.windKmh.round();
  final gustKmh = w.gustKmh.round();
  final windMph = _kmhToMph(w.windKmh).round();
  final gustMph = _kmhToMph(w.gustKmh).round();

  final kmhLine = 'Wind $windKmh km/h, gust $gustKmh km/h';
  final mphLine = 'Wind $windMph mph, gust $gustMph mph';

  return metricActive ? (kmhLine, mphLine) : (mphLine, kmhLine);
}

(String, String) _currencyLines({
  required Place? primary,
  required Place? secondary,
  required double eurToUsd,
}) {
  // Default to EUR/USD. If we can infer, flip direction.
  final primaryCurrency = _currencyForCountry(primary?.countryCode);
  final secondaryCurrency = _currencyForCountry(secondary?.countryCode);

  final amount = 10.0;
  if (primaryCurrency == 'EUR' && secondaryCurrency == 'USD') {
    final approx = amount * eurToUsd;
    return (
      '${_symbol('EUR')}${amount.toStringAsFixed(0)} ≈ ${_symbol('USD')}${approx.toStringAsFixed(0)}',
      '1 EUR ≈ ${eurToUsd.toStringAsFixed(2)} USD',
    );
  }
  if (primaryCurrency == 'USD' && secondaryCurrency == 'EUR') {
    final usdToEur = 1.0 / eurToUsd;
    final approx = amount * usdToEur;
    return (
      '${_symbol('USD')}${amount.toStringAsFixed(0)} ≈ ${_symbol('EUR')}${approx.toStringAsFixed(0)}',
      '1 USD ≈ ${usdToEur.toStringAsFixed(2)} EUR',
    );
  }

  // Fallback:
  return (
    '${_symbol(primaryCurrency)}10 ≈ ${_symbol(secondaryCurrency)}11',
    'Rates refresh on tap',
  );
}

String _currencyForCountry(String? countryCode) {
  switch (countryCode) {
    case 'US':
      return 'USD';
    case 'PT':
    case 'DE':
    case 'FR':
    case 'ES':
    case 'IT':
      return 'EUR';
    case 'GB':
      return 'GBP';
    case 'CA':
      return 'CAD';
    default:
      return 'USD';
  }
}

String _symbol(String code) {
  return switch (code) {
    'USD' => r'$',
    'CAD' => r'CA$',
    'EUR' => String.fromCharCode(0x20AC),
    'GBP' => String.fromCharCode(0x00A3),
    _ => code,
  };
}

String _flagEmojiFromIso2(String? iso2) {
  final code = (iso2 ?? '').trim().toUpperCase();
  if (code.length != 2) return '🌐';
  final a = code.codeUnitAt(0);
  final b = code.codeUnitAt(1);
  if (a < 65 || a > 90 || b < 65 || b > 90) return '🌐';
  return String.fromCharCodes(<int>[0x1F1E6 + (a - 65), 0x1F1E6 + (b - 65)]);
}
