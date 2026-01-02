import 'package:flutter/material.dart';

import 'hero_alive_marquee.dart';

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

    final primarySun = liveData.sunFor(primary);

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
        final sideWidth = isCompact ? 160.0 : 196.0;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ClocksHeaderBlock(
                      primaryPlace: primary,
                      primaryZone: primaryZone,
                      secondaryPlace: secondary,
                      secondaryZone: secondaryZone,
                      deltaHours: delta,
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
                              weather: primaryWeather,
                              secondaryPlace: secondary,
                              secondaryWeather: secondaryWeather,
                              eurToUsd: liveData.eurToUsd,
                              compact: isCompact,
                            ),
                          ),
                          SizedBox(width: gap),
                          SizedBox(
                            width: sideWidth,
                            child: _RightSunRail(
                              sun: primarySun,
                              primaryTzId: primary?.timeZoneId,
                              secondaryTzId: secondary?.timeZoneId,
                              compact: isCompact,
                            ),
                          ),
                        ],
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

class _ScaleDownText extends StatelessWidget {
  const _ScaleDownText(
    this.text, {
    required this.style,
    this.alignment = Alignment.centerLeft,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final TextStyle? style;
  final Alignment alignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        text,
        textAlign: textAlign,
        style: style,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

class _ScaleDownRichText extends StatelessWidget {
  const _ScaleDownRichText({required this.span, this.textKey});

  final InlineSpan span;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: RichText(
        key: textKey,
        textAlign: TextAlign.left,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        text: span,
      ),
    );
  }
}

class _ClocksHeaderBlock extends StatelessWidget {
  final Place? primaryPlace;
  final ZoneTime? primaryZone;
  final Place? secondaryPlace;
  final ZoneTime? secondaryZone;
  final int? deltaHours;
  final bool compact;

  const _ClocksHeaderBlock({
    required this.primaryPlace,
    required this.primaryZone,
    required this.secondaryPlace,
    required this.secondaryZone,
    required this.deltaHours,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withAlpha(170);

    final primaryName = _placeLabel(primaryPlace);
    final secondaryName = _placeLabel(secondaryPlace);

    String headerLine = 'No place selected';
    String detailLine = '--';

    if (primaryPlace != null && primaryZone != null) {
      final primaryClock = TimezoneUtils.formatClock(
        primaryZone!,
        use24h: primaryPlace!.use24h,
      );

      if (secondaryPlace != null &&
          secondaryZone != null &&
          deltaHours != null) {
        final secondaryClock = TimezoneUtils.formatClock(
          secondaryZone!,
          use24h: secondaryPlace!.use24h,
        );

        headerLine =
            '$primaryName • $secondaryName ${TimezoneUtils.formatDeltaLabel(deltaHours!)}';

        detailLine =
            '$primaryClock ${primaryZone!.abbreviation} • $secondaryClock ${secondaryZone!.abbreviation} (${_formatWeekdayDate(primaryZone!)})';
      } else {
        headerLine = primaryName;
        detailLine = '$primaryClock ${primaryZone!.abbreviation}';
      }
    }

    final contextStyle =
        (compact
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.titleLarge)
            ?.copyWith(
              color: cs.onSurface.withAlpha(230),
              fontWeight: FontWeight.w800,
            );

    final timeStyle =
        (compact
                ? Theme.of(context).textTheme.labelLarge
                : Theme.of(context).textTheme.titleMedium)
            ?.copyWith(color: muted, fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ScaleDownText(
          headerLine,
          style: contextStyle,
          alignment: Alignment.center,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        _ScaleDownText(
          detailLine,
          style: timeStyle,
          alignment: Alignment.center,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LeftPrimaryBlock extends StatelessWidget {
  final Place? place;
  final WeatherSnapshot? weather;
  final Place? secondaryPlace;
  final WeatherSnapshot? secondaryWeather;
  final double eurToUsd;
  final bool compact;

  const _LeftPrimaryBlock({
    required this.place,
    required this.weather,
    required this.secondaryPlace,
    required this.secondaryWeather,
    required this.eurToUsd,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withAlpha(170);

    final primaryTemp = (place == null || weather == null)
        ? '--'
        : _formatTemp(place!, weather!);

    final secondaryTemp = (secondaryPlace == null || secondaryWeather == null)
        ? ''
        : _formatTemp(secondaryPlace!, secondaryWeather!);

    final (windLine, gustLine) = (place != null)
        ? _windLines(place!, weather)
        : ('Wind --', 'Gust --');

    final currencyLines = _currencyLines(
      primary: place,
      secondary: secondaryPlace,
      eurToUsd: eurToUsd,
    );

    final windStyle =
        (compact
                ? Theme.of(context).textTheme.bodySmall
                : Theme.of(context).textTheme.bodyMedium)
            ?.copyWith(
              color: cs.onSurface.withAlpha(215),
              fontWeight: FontWeight.w600,
            );

    final rateStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: cs.onSurface.withAlpha(155),
      fontWeight: FontWeight.w500,
    );

    final labelStyle =
        (compact
                ? Theme.of(context).textTheme.bodySmall
                : Theme.of(context).textTheme.bodyMedium)
            ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w800);

    InlineSpan labeledLineSpan(
      String line, {
      required TextStyle? baseStyle,
      required TextStyle? labelStyle,
    }) {
      final trimmed = line.trim();
      final firstSpace = trimmed.indexOf(' ');
      final label = firstSpace <= 0
          ? trimmed
          : trimmed.substring(0, firstSpace);
      final rest = firstSpace <= 0 ? '' : trimmed.substring(firstSpace);
      return TextSpan(
        children: [
          TextSpan(text: label, style: labelStyle),
          if (rest.isNotEmpty) TextSpan(text: rest, style: baseStyle),
        ],
      );
    }

    InlineSpan rateLineSpan(
      String line, {
      required TextStyle? baseStyle,
      required TextStyle? labelStyle,
    }) {
      final trimmed = line.trim();
      const prefix = 'Rate:';
      if (trimmed.startsWith(prefix)) {
        final rest = trimmed.substring(prefix.length);
        return TextSpan(
          children: [
            TextSpan(text: prefix, style: labelStyle),
            TextSpan(text: rest, style: baseStyle),
          ],
        );
      }
      return TextSpan(text: trimmed, style: baseStyle);
    }

    final primaryTempStyle =
        (compact
                ? Theme.of(context).textTheme.headlineMedium
                : Theme.of(context).textTheme.displayMedium)
            ?.copyWith(fontWeight: FontWeight.w800, height: 1.0);

    final secondaryTempStyle =
        (compact
                ? Theme.of(context).textTheme.labelMedium
                : Theme.of(context).textTheme.titleMedium)
            ?.copyWith(color: muted, fontWeight: FontWeight.w700);

    Widget tempRow() => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            key: const ValueKey('hero_primary_temp'),
            primaryTemp,
            style: primaryTempStyle,
          ),
          if (secondaryTemp.isNotEmpty) ...[
            const SizedBox(width: 8),
            Padding(
              padding: EdgeInsets.only(bottom: compact ? 5 : 10),
              child: Text(
                key: const ValueKey('hero_secondary_temp'),
                secondaryTemp,
                style: secondaryTempStyle,
              ),
            ),
          ],
        ],
      ),
    );

    Widget windBlock({required double gap}) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScaleDownRichText(
          span: labeledLineSpan(
            windLine,
            baseStyle: windStyle,
            labelStyle: labelStyle,
          ),
          textKey: const ValueKey('hero_wind_line'),
        ),
        SizedBox(height: gap),
        _ScaleDownRichText(
          span: labeledLineSpan(
            gustLine,
            baseStyle: windStyle,
            labelStyle: labelStyle,
          ),
          textKey: const ValueKey('hero_gust_line'),
        ),
      ],
    );

    Widget moneyBlock({required double gap}) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScaleDownText(
          currencyLines.$1,
          style:
              (compact
                      ? Theme.of(context).textTheme.bodySmall
                      : Theme.of(context).textTheme.bodyMedium)
                  ?.copyWith(
                    color: cs.onSurface.withAlpha(230),
                    fontWeight: FontWeight.w700,
                  ),
        ),
        SizedBox(height: gap),
        _ScaleDownRichText(
          span: rateLineSpan(
            currencyLines.$2,
            baseStyle: rateStyle,
            labelStyle: labelStyle,
          ),
          textKey: const ValueKey('hero_rate_line'),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        final smallH =
            bounded && constraints.maxHeight <= (compact ? 132 : 160);
        final gapAfterTemp = compact ? (smallH ? 8.0 : 10.0) : 14.0;
        final innerGap = compact ? (smallH ? 0.0 : 1.0) : 2.0;

        if (!bounded) {
          // Unbounded height is rare here; keep a simple flow layout.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tempRow(),
              SizedBox(height: gapAfterTemp),
              windBlock(gap: innerGap),
              SizedBox(height: compact ? 6 : 10),
              moneyBlock(gap: innerGap),
            ],
          );
        }

        // Bounded height: use flexible distribution to avoid tiny overflows
        // and keep wind/money blocks visually separated.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tempRow(),
            SizedBox(height: gapAfterTemp),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  windBlock(gap: innerGap),
                  moneyBlock(gap: innerGap),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RightSunRail extends StatelessWidget {
  final SunTimesSnapshot? sun;
  final String? primaryTzId;
  final String? secondaryTzId;
  final bool compact;

  const _RightSunRail({
    required this.sun,
    required this.primaryTzId,
    required this.secondaryTzId,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();
    final radius = (layout?.radiusCard ?? 20.0) - 6;
    final marqueeHeight = compact ? 44.0 : 52.0;

    return Column(
      key: const ValueKey('hero_right_rail'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          key: const ValueKey('hero_marquee_slot'),
          height: marqueeHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: cs.outlineVariant.withAlpha(170),
                width: (layout?.strokeHairline ?? 1.0),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: HeroAliveMarquee(compact: compact),
            ),
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              return Align(
                alignment: Alignment.bottomRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: c.maxWidth,
                    child: _SunTimesPill(
                      sun: sun,
                      primaryTzId: primaryTzId,
                      secondaryTzId: secondaryTzId,
                      compact: compact,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SunTimesPill extends StatelessWidget {
  final SunTimesSnapshot? sun;
  final String? primaryTzId;
  final String? secondaryTzId;
  final bool compact;

  const _SunTimesPill({
    required this.sun,
    required this.primaryTzId,
    required this.secondaryTzId,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();
    final r = (layout?.radiusCard ?? 20.0) - 6;

    final titleStyle =
        (compact
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.titleMedium)
            ?.copyWith(fontWeight: FontWeight.w800);

    final rowStyle =
        (compact
                ? Theme.of(context).textTheme.bodySmall
                : Theme.of(context).textTheme.bodyMedium)
            ?.copyWith(
              color: cs.onSurface.withAlpha(220),
              fontWeight: FontWeight.w600,
            );

    final labelStyle = rowStyle?.copyWith(
      color: cs.onSurface,
      fontWeight: FontWeight.w800,
    );

    InlineSpan labeledLineSpan(
      String line, {
      required TextStyle? baseStyle,
      required TextStyle? labelStyle,
    }) {
      final trimmed = line.trim();
      final firstSpace = trimmed.indexOf(' ');
      final label = firstSpace <= 0
          ? trimmed
          : trimmed.substring(0, firstSpace);
      final rest = firstSpace <= 0 ? '' : trimmed.substring(firstSpace);
      return TextSpan(
        children: [
          TextSpan(text: label, style: labelStyle),
          if (rest.isNotEmpty) TextSpan(text: rest, style: baseStyle),
        ],
      );
    }

    String rise = 'Sunrise --:--';
    String set = 'Sunset --:--';

    if (sun != null && primaryTzId != null && secondaryTzId != null) {
      final risePrimary = TimezoneUtils.nowInZone(
        primaryTzId!,
        nowUtc: sun!.sunriseUtc,
      );
      final riseSecondary = TimezoneUtils.nowInZone(
        secondaryTzId!,
        nowUtc: sun!.sunriseUtc,
      );

      final setPrimary = TimezoneUtils.nowInZone(
        primaryTzId!,
        nowUtc: sun!.sunsetUtc,
      );
      final setSecondary = TimezoneUtils.nowInZone(
        secondaryTzId!,
        nowUtc: sun!.sunsetUtc,
      );

      rise =
          'Sunrise ${_format24h(risePrimary)} ${risePrimary.abbreviation} • ${_format24h(riseSecondary)} ${riseSecondary.abbreviation}';
      set =
          'Sunset ${_format24h(setPrimary)} ${setPrimary.abbreviation} • ${_format24h(setSecondary)} ${setSecondary.abbreviation}';
    }

    return Container(
      key: const ValueKey('hero_sun_pill'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(35),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: cs.outlineVariant.withAlpha(170), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: _ScaleDownText(
              'Sunrise / Sunset',
              style: titleStyle,
              alignment: Alignment.center,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          _ScaleDownRichText(
            span: labeledLineSpan(
              rise,
              baseStyle: rowStyle,
              labelStyle: labelStyle,
            ),
            textKey: const ValueKey('hero_sunrise_row'),
          ),
          const SizedBox(height: 2),
          _ScaleDownRichText(
            span: labeledLineSpan(
              set,
              baseStyle: rowStyle,
              labelStyle: labelStyle,
            ),
            textKey: const ValueKey('hero_sunset_row'),
          ),
        ],
      ),
    );
  }
}

String _placeLabel(Place? p) {
  if (p == null) return '-';
  if (p.cityName.isNotEmpty) return p.cityName;
  if (p.name.isNotEmpty) return p.name;
  return '-';
}

String _formatWeekdayDate(ZoneTime zt) {
  const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final dt = zt.local;
  final wd = (dt.weekday >= 1 && dt.weekday <= 7)
      ? weekdays[dt.weekday - 1]
      : '';
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
  return '$wd ${dt.day} $mon';
}

String _format24h(ZoneTime zt) {
  final hh = zt.local.hour.toString().padLeft(2, '0');
  final mm = zt.local.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
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

/// Converts kilometers per hour to miles per hour.
///
/// Kept as a file-level helper so it can be reused anywhere in this widget without
/// needing a BuildContext.
double _kmhToMph(num kmh) => kmh.toDouble() * 0.621371;

(String, String) _windLines(Place place, WeatherSnapshot? w) {
  if (w == null) {
    return ('Wind - km/h (- mph)', 'Gust - km/h (- mph)');
  }

  final windKmh = w.windKmh.round();
  final gustKmh = w.gustKmh.round();
  final windMph = _kmhToMph(w.windKmh).round();
  final gustMph = _kmhToMph(w.gustKmh).round();

  final metricActive = place.unitSystem == 'metric';
  if (metricActive) {
    return (
      'Wind $windKmh km/h ($windMph mph)',
      'Gust $gustKmh km/h ($gustMph mph)',
    );
  }
  return (
    'Wind $windMph mph ($windKmh km/h)',
    'Gust $gustMph mph ($gustKmh km/h)',
  );
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
      'Rate: 1 EUR ≈ ${eurToUsd.toStringAsFixed(2)} USD',
    );
  }
  if (primaryCurrency == 'USD' && secondaryCurrency == 'EUR') {
    final usdToEur = 1.0 / eurToUsd;
    final approx = amount * usdToEur;
    return (
      '${_symbol('USD')}${amount.toStringAsFixed(0)} ≈ ${_symbol('EUR')}${approx.toStringAsFixed(0)}',
      'Rate: 1 USD ≈ ${usdToEur.toStringAsFixed(2)} EUR',
    );
  }

  // Fallback:
  return (
    '${_symbol(primaryCurrency)}10 ≈ ${_symbol(secondaryCurrency)}11',
    'Rate: -',
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
