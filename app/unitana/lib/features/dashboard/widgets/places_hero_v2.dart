import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'hero_alive_marquee.dart';
import 'pulse_swap_icon.dart';

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

    final nowUtc = liveData.nowUtc;

    final primaryWeather = liveData.weatherFor(primary);
    final secondaryWeather = liveData.weatherFor(secondary);

    final primaryZone = primary == null
        ? null
        : TimezoneUtils.nowInZone(primary.timeZoneId, nowUtc: nowUtc);
    final secondaryZone = secondary == null
        ? null
        : TimezoneUtils.nowInZone(secondary.timeZoneId, nowUtc: nowUtc);

    final delta = (primaryZone != null && secondaryZone != null)
        ? TimezoneUtils.deltaHours(primaryZone, secondaryZone)
        : null;

    final primarySun = liveData.sunFor(primary);

    final (primaryWindLine, primaryGustLine) = primary == null
        ? ('Wind --', 'Gust --')
        : _windLines(primary, primaryWeather);

    final debugOverride = liveData.debugWeatherOverride;
    final bool? forcedIsNight =
        (debugOverride is WeatherDebugOverrideWeatherApi)
        ? debugOverride.isNight
        : (debugOverride is WeatherDebugOverrideCoarse)
        ? debugOverride.isNightOverride
        : null;

    bool isNightFromSun() {
      final sun = primarySun;
      if (sun != null) {
        return nowUtc.isBefore(sun.sunriseUtc) || nowUtc.isAfter(sun.sunsetUtc);
      }
      final local = primaryZone;
      if (local != null) {
        return local.local.hour < 6 || local.local.hour >= 18;
      }
      return false;
    }

    final bool isNight = forcedIsNight ?? isNightFromSun();

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
                              liveData: liveData,
                              sun: primarySun,
                              sceneKey: primaryWeather?.sceneKey,
                              conditionLabel: primaryWeather?.conditionText,
                              isNight: isNight,
                              primaryTzId: primary?.timeZoneId,
                              secondaryTzId: secondary?.timeZoneId,
                              primaryUse24h: primary?.use24h,
                              secondaryUse24h: secondary?.use24h,
                              detailsMode: session.heroDetailsPillMode,
                              onToggleDetailsMode:
                                  session.toggleHeroDetailsPillMode,
                              windLine: primaryWindLine,
                              gustLine: primaryGustLine,
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
          style: GoogleFonts.robotoSlab(
            textStyle:
                (compact
                        ? Theme.of(context).textTheme.titleSmall
                        : Theme.of(context).textTheme.titleMedium)
                    ?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
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
    this.textKey,
    this.alignment = Alignment.centerLeft,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final TextStyle? style;
  final Key? textKey;
  final Alignment alignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        text,
        key: textKey,
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
  const _ScaleDownRichText({
    required this.span,
    this.textKey,
    this.alignment = Alignment.centerLeft,
    this.textAlign = TextAlign.left,
  });

  final InlineSpan span;
  final Key? textKey;
  final Alignment alignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: RichText(
        key: textKey,
        textAlign: textAlign,
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

    InlineSpan headerSpan;
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

        detailLine =
            '$primaryClock ${primaryZone!.abbreviation} • $secondaryClock ${secondaryZone!.abbreviation} (${_formatWeekdayDate(primaryZone!)})';
      } else {
        detailLine = '$primaryClock ${primaryZone!.abbreviation}';
      }
    }

    final baseContextStyle =
        (compact
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.titleLarge)
            ?.copyWith(
              color: cs.onSurface.withAlpha(230),
              fontWeight: FontWeight.w800,
            );

    final cityStyle = GoogleFonts.robotoSlab(textStyle: baseContextStyle);

    headerSpan = TextSpan(text: 'No place selected', style: baseContextStyle);

    if (primaryPlace != null && primaryZone != null) {
      if (secondaryPlace != null &&
          secondaryZone != null &&
          deltaHours != null) {
        final deltaLabel = TimezoneUtils.formatDeltaLabel(deltaHours!);
        headerSpan = TextSpan(
          children: [
            TextSpan(text: primaryName, style: cityStyle),
            TextSpan(text: ' • ', style: baseContextStyle),
            TextSpan(text: secondaryName, style: cityStyle),
            TextSpan(text: ' $deltaLabel', style: baseContextStyle),
          ],
        );
      } else {
        headerSpan = TextSpan(text: primaryName, style: cityStyle);
      }
    }

    final timeStyle =
        (compact
                ? Theme.of(context).textTheme.labelLarge
                : Theme.of(context).textTheme.titleMedium)
            ?.copyWith(color: muted, fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ScaleDownRichText(
          textKey: const ValueKey('places_hero_clock_header'),
          span: headerSpan,
          alignment: Alignment.center,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        _ScaleDownText(
          detailLine,
          style: timeStyle,
          textKey: const ValueKey('places_hero_clock_detail'),
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
        // In very tight heights (small phones / landscape), the inner blocks
        // can overflow because Column children are unconstrained. In that case
        // we constrain each block and allow it to scale down as a whole.
        if (smallH) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tempRow(),
              SizedBox(height: gapAfterTemp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topLeft,
                          child: windBlock(gap: innerGap),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: moneyBlock(gap: innerGap),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

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
  final DashboardLiveDataController liveData;

  final SunTimesSnapshot? sun;
  final SceneKey? sceneKey;
  final String? conditionLabel;
  final bool isNight;
  final String? primaryTzId;
  final String? secondaryTzId;
  final bool? primaryUse24h;
  final bool? secondaryUse24h;
  final HeroDetailsPillMode detailsMode;
  final VoidCallback onToggleDetailsMode;
  final String windLine;
  final String gustLine;
  final bool compact;

  const _RightSunRail({
    required this.liveData,
    required this.sun,
    required this.sceneKey,
    required this.conditionLabel,
    required this.isNight,
    required this.primaryTzId,
    required this.secondaryTzId,
    required this.primaryUse24h,
    required this.secondaryUse24h,
    required this.detailsMode,
    required this.onToggleDetailsMode,
    required this.windLine,
    required this.gustLine,
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
              child: HeroAliveMarquee(
                compact: compact,
                isNight: isNight,
                sceneKey: sceneKey,
                conditionLabel: conditionLabel,
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
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
                      primaryUse24h: primaryUse24h,
                      secondaryUse24h: secondaryUse24h,
                      detailsMode: detailsMode,
                      onToggleDetailsMode: onToggleDetailsMode,
                      windLine: windLine,
                      gustLine: gustLine,
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

// Shared mini-pill used in both the expanded hero and the pinned overlay.
class _SunTimesPill extends StatelessWidget {
  final SunTimesSnapshot? sun;
  final String? primaryTzId;
  final String? secondaryTzId;
  final bool? primaryUse24h;
  final bool? secondaryUse24h;
  final HeroDetailsPillMode detailsMode;
  final VoidCallback onToggleDetailsMode;
  final String windLine;
  final String gustLine;
  final bool compact;

  const _SunTimesPill({
    required this.sun,
    required this.primaryTzId,
    required this.secondaryTzId,
    required this.primaryUse24h,
    required this.secondaryUse24h,
    required this.detailsMode,
    required this.onToggleDetailsMode,
    required this.windLine,
    required this.gustLine,
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
              // Tighten line height slightly so the sun/wind detail content fits
              // inside the fixed-height details region without overflow.
              height: 1.05,
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

      final use24Primary = primaryUse24h ?? true;
      final use24Secondary = secondaryUse24h ?? true;

      rise =
          'Sunrise ${TimezoneUtils.formatClock(risePrimary, use24h: use24Primary)} • ${TimezoneUtils.formatClock(riseSecondary, use24h: use24Secondary)}';
      set =
          'Sunset ${TimezoneUtils.formatClock(setPrimary, use24h: use24Primary)} • ${TimezoneUtils.formatClock(setSecondary, use24h: use24Secondary)}';
    }

    final isWind = detailsMode == HeroDetailsPillMode.wind;
    final semanticsLabel = isWind
        ? 'Wind details. Tap to show sunrise and sunset.'
        : 'Sunrise and sunset details. Tap to show wind.';

    Widget titleRow(String icon, String text) {
      return SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Text(
                      icon,
                      key: ValueKey<String>('hero_details_icon_$icon'),
                      style: titleStyle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(text, style: titleStyle),
              const SizedBox(width: 6),
              PulseSwapIcon(
                color: cs.onSurface.withAlpha(150),
                size: compact ? 14 : 16,
              ),
            ],
          ),
        ),
      );
    }

    Widget sunContent() {
      return Column(
        key: const ValueKey('hero_details_sun_content'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: compact ? 0 : 2),
          _ScaleDownRichText(
            span: labeledLineSpan(
              rise,
              baseStyle: rowStyle,
              labelStyle: labelStyle,
            ),
            textKey: const ValueKey('hero_sunrise_row'),
          ),
          SizedBox(height: compact ? 0 : 1),
          _ScaleDownRichText(
            span: labeledLineSpan(
              set,
              baseStyle: rowStyle,
              labelStyle: labelStyle,
            ),
            textKey: const ValueKey('hero_sunset_row'),
          ),
        ],
      );
    }

    Widget windContent() {
      return Column(
        key: const ValueKey('hero_details_wind_content'),
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: compact ? 0 : 2),
          Align(
            alignment: Alignment.center,
            child: _ScaleDownRichText(
              span: labeledLineSpan(
                windLine,
                baseStyle: rowStyle,
                labelStyle: labelStyle,
              ),
              textKey: const ValueKey('hero_wind_row'),
            ),
          ),
          SizedBox(height: compact ? 0 : 1),
          Align(
            alignment: Alignment.center,
            child: _ScaleDownRichText(
              span: labeledLineSpan(
                gustLine,
                baseStyle: rowStyle,
                labelStyle: labelStyle,
              ),
              textKey: const ValueKey('hero_gust_row'),
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      onTap: onToggleDetailsMode,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggleDetailsMode,
          borderRadius: BorderRadius.circular(r),
          child: Container(
            key: const ValueKey('hero_sun_pill'),
            constraints: BoxConstraints.tightFor(
              // Contract: identical pill bounds across modes to prevent any visual
              // jump and to keep pinned/mini layouts stable.
              height: compact ? 44.0 : 92.0,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 6 : 10,
            ),
            decoration: BoxDecoration(
              color: cs.surface.withAlpha(35),
              borderRadius: BorderRadius.circular(r),
              border: Border.all(
                color: cs.outlineVariant.withAlpha(170),
                width: 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final content = Column(
                  crossAxisAlignment: isWind
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    titleRow(
                      isWind ? '🌬' : '☀︎',
                      isWind ? 'Wind / Gust' : 'Sunrise / Sunset',
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) {
                        return FadeTransition(opacity: anim, child: child);
                      },
                      child: isWind ? windContent() : sunContent(),
                    ),
                  ],
                );

                return Align(
                  alignment: isWind ? Alignment.center : Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: isWind ? Alignment.center : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: c.maxWidth),
                      child: content,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

String _placeLabel(Place? p) {
  if (p == null) {
    return '-';
  }
  if (p.cityName.isNotEmpty) {
    return p.cityName;
  }
  if (p.name.isNotEmpty) {
    return p.name;
  }
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
    return ('-- km/h (-- mph)', '-- km/h (-- mph)');
  }

  final windKmh = w.windKmh.round();
  final gustKmh = w.gustKmh.round();
  final windMph = _kmhToMph(w.windKmh).round();
  final gustMph = _kmhToMph(w.gustKmh).round();

  final metricActive = place.unitSystem == 'metric';
  if (metricActive) {
    return ('$windKmh km/h ($windMph mph)', '$gustKmh km/h ($gustMph mph)');
  }
  return ('$windMph mph ($windKmh km/h)', '$gustMph mph ($gustKmh km/h)');
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
  if (code.length != 2) {
    return '🌐';
  }
  final a = code.codeUnitAt(0);
  final b = code.codeUnitAt(1);
  if (a < 65 || a > 90 || b < 65 || b > 90) {
    return '🌐';
  }
  return String.fromCharCodes(<int>[0x1F1E6 + (a - 65), 0x1F1E6 + (b - 65)]);
}
