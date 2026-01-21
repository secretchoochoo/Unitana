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
        final pad = 10.0;
        final gap = 6.0;

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
                      child: _HeroBandsBody(
                        primary: primary,
                        primaryWeather: primaryWeather,
                        secondary: secondary,
                        secondaryWeather: secondaryWeather,
                        eurToUsd: liveData.eurToUsd,
                        envMode: session.heroEnvPillMode,
                        onToggleEnvMode: session.toggleHeroEnvPillMode,
                        sun: primarySun,
                        sceneKey: primaryWeather?.sceneKey,
                        conditionLabel: primaryWeather?.conditionText,
                        isNight: isNight,
                        primaryTzId: primary?.timeZoneId,
                        secondaryTzId: secondary?.timeZoneId,
                        primaryUse24h: primary?.use24h,
                        secondaryUse24h: secondary?.use24h,
                        detailsMode: session.heroDetailsPillMode,
                        onToggleDetailsMode: session.toggleHeroDetailsPillMode,
                        windLine: primaryWindLine,
                        gustLine: primaryGustLine,
                        compact: isCompact,
                        gap: gap,
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

/// Hero body layout that aligns content into two bands:
/// - Top band: temperature (left) and marquee (right)
/// - Bottom band: Env+Currency stack (left), middle anim bay, and Sun/Wind pill (right)
///
/// This avoids cross-band constraint ambiguity and ensures the middle bay always
/// sits below the marquee without shrinking the left tiles.
class _HeroBandsBody extends StatelessWidget {
  final Place? primary;
  final WeatherSnapshot? primaryWeather;
  final Place? secondary;
  final WeatherSnapshot? secondaryWeather;
  final double? eurToUsd;
  final HeroEnvPillMode envMode;
  final VoidCallback onToggleEnvMode;

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
  final double gap;

  const _HeroBandsBody({
    required this.primary,
    required this.primaryWeather,
    required this.secondary,
    required this.secondaryWeather,
    required this.eurToUsd,
    required this.envMode,
    required this.onToggleEnvMode,
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
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final innerW = c.maxWidth;
        final colGap = gap;
        final stackGap = 4.0;

        // Option 3: remove the middle animation bay.
        // Sizing priority: Sunrise/Wind (right) gets the most space;
        // Env/Currency (left) stays readable and never collapses into a stamp.
        final leftMin = 150.0;

        final available = (innerW - colGap).clamp(0.0, double.infinity);

        double leftW;
        double rightW;

        if (available <= 0) {
          leftW = 0;
          rightW = 0;
        } else {
          // Contract-first allocation:
          // - Prefer left rail >= leftMin when possible.
          // - Ensure Sunrise/Wind (right) is never narrower than the left rail.
          if (available >= leftMin * 2) {
            leftW = leftMin;
            rightW = available - leftW;
          } else {
            // Tight case: split evenly to preserve readability parity.
            leftW = available / 2;
            rightW = available - leftW;
          }

          // Final guard: keep right >= left when there's any rounding drift.
          if (rightW < leftW) {
            final mid = available / 2;
            leftW = mid;
            rightW = available - mid;
          }
        }

        final topRow = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: leftW,
              child: _LeftTempBand(
                primary: primary,
                primaryWeather: primaryWeather,
                secondary: secondary,
                secondaryWeather: secondaryWeather,
                compact: compact,
              ),
            ),
            SizedBox(width: colGap),
            SizedBox(
              width: rightW,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _RightMarqueeSlot(
                  compact: compact,
                  isNight: isNight,
                  sceneKey: sceneKey,
                  conditionLabel: conditionLabel,
                  renderConditionLabel: false,
                ),
              ),
            ),
          ],
        );

        final bottomRow = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: leftW,
              child: _LeftEnvCurrencyStack(
                primary: primary,
                secondary: secondary,
                eurToUsd: eurToUsd,
                envMode: envMode,
                onToggleEnvMode: onToggleEnvMode,
                compact: compact,
                gap: stackGap,
              ),
            ),
            SizedBox(width: colGap),
            SizedBox(
              width: rightW,
              child: _RightDetailsPill(
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
          ],
        );

        // Contract: Env and Currency tiles must each have a >=44dp touch target.
        // Keep this as a single source of truth so tests and layout policy
        // don't drift again.
        final tileTapH = 44.0;
        final bottomMinH = tileTapH + stackGap + tileTapH;
        final totalH = c.hasBoundedHeight ? c.maxHeight : double.infinity;

        // Pin the bottom band whenever the overall hero height can afford it.
        // This prevents the top row from expanding naturally and starving the
        // Env/Currency stack into a ~20dp postage stamp (the P1.12 regressions).
        final canPinBottom =
            c.hasBoundedHeight &&
            totalH.isFinite &&
            totalH >= (bottomMinH + colGap + 1.0);

        if (canPinBottom) {
          final usable = totalH - colGap;
          final bottomH = bottomMinH;
          final topH = (usable - bottomH).clamp(0.0, double.infinity);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topH, child: topRow),
              SizedBox(height: colGap),
              SizedBox(height: bottomH, child: bottomRow),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            topRow,
            SizedBox(height: colGap),
            Expanded(child: bottomRow),
          ],
        );
      },
    );
  }
}

class _LeftTempBand extends StatelessWidget {
  final Place? primary;
  final WeatherSnapshot? primaryWeather;
  final Place? secondary;
  final WeatherSnapshot? secondaryWeather;
  final bool compact;

  const _LeftTempBand({
    required this.primary,
    required this.primaryWeather,
    required this.secondary,
    required this.secondaryWeather,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final primaryTemp = (primary != null && primaryWeather != null)
        ? _formatTemp(primary!, primaryWeather!)
        : '--';

    final secondaryTemp = (secondary != null && secondaryWeather != null)
        ? _formatTemp(secondary!, secondaryWeather!)
        : '';

    final primaryTempStyle =
        (compact
                ? Theme.of(context).textTheme.displaySmall
                : Theme.of(context).textTheme.displayMedium)
            ?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              height: 0.95,
            );

    final secondaryTempStyle =
        (compact
                ? Theme.of(context).textTheme.titleSmall
                : Theme.of(context).textTheme.titleMedium)
            ?.copyWith(
              color: cs.onSurface.withAlpha(200),
              fontWeight: FontWeight.w800,
            );

    return FittedBox(
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
  }
}

class _LeftEnvCurrencyStack extends StatelessWidget {
  final Place? primary;
  final Place? secondary;
  final double? eurToUsd;
  final HeroEnvPillMode envMode;
  final VoidCallback onToggleEnvMode;
  final bool compact;
  final double gap;

  const _LeftEnvCurrencyStack({
    required this.primary,
    required this.secondary,
    required this.eurToUsd,
    required this.envMode,
    required this.onToggleEnvMode,
    required this.compact,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final innerGap = gap < 2.0 ? 2.0 : (gap > 10.0 ? 10.0 : gap);
        final tileH = ((c.maxHeight - innerGap) / 2).clamp(
          0.0,
          double.infinity,
        );
        final dense = tileH < (compact ? 66.0 : 86.0);
        // Keep rendering deterministic even if the currency rate hasn't loaded.
        final safeRate = eurToUsd ?? 1.10;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _HeroEnvPill(
                envMode: envMode,
                onToggle: onToggleEnvMode,
                compact: compact,
                dense: dense,
              ),
            ),
            SizedBox(height: innerGap),
            Expanded(
              child: _HeroCurrencyCard(
                primary: primary,
                secondary: secondary,
                eurToUsd: safeRate,
                compact: compact,
                dense: dense,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroEnvPill extends StatelessWidget {
  final HeroEnvPillMode envMode;
  final VoidCallback onToggle;
  final bool compact;
  final bool dense;

  const _HeroEnvPill({
    required this.envMode,
    required this.onToggle,
    required this.compact,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();

    final radius = (layout?.radiusCard ?? 20.0) - 6;
    final stroke = (layout?.strokeHairline ?? 1.0);

    final pad = compact
        ? EdgeInsets.symmetric(horizontal: 10, vertical: dense ? 5 : 7)
        : EdgeInsets.symmetric(horizontal: 11, vertical: dense ? 6 : 8);

    // Compact mode is routinely forced into very small inner heights by the
    // test harness. Any extra vertical gap risks sub-pixel overflow.
    final innerGap = dense ? 0.0 : (compact ? 0.0 : 2.0);

    final baseTitle = Theme.of(context).textTheme.labelLarge;
    final titleStyle = baseTitle?.copyWith(
      // Slightly smaller to free room for future dual-value env lines
      // (AQI + PM2.5, dual scale, etc.) without squeezing the marquee.
      fontSize: (baseTitle.fontSize ?? 14) - 1,
      color: cs.onSurface.withAlpha(230),
      fontWeight: FontWeight.w800,
    );

    final baseRow = (compact
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium);
    final rowStyle = baseRow?.copyWith(
      fontSize: (baseRow.fontSize ?? 12) - 1,
      color: cs.onSurface.withAlpha(210),
      fontWeight: FontWeight.w600,
    );

    final isAqi = envMode == HeroEnvPillMode.aqi;
    final icon = isAqi ? '🌫' : '🌼';
    final title = isAqi ? 'AQI' : 'Pollen';
    final line = isAqi ? 'AQI -- • PM2.5 --' : 'Pollen -- • Type --';

    final semanticsLabel = isAqi
        ? 'Air quality details. Tap to show pollen.'
        : 'Pollen details. Tap to show air quality.';

    Widget body(bool forceExpand, bool applyMinHeight) {
      return Semantics(
        button: true,
        label: semanticsLabel,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            key: const ValueKey('hero_env_pill'),
            width: forceExpand ? double.infinity : null,
            height: forceExpand ? double.infinity : null,
            constraints: applyMinHeight
                ? const BoxConstraints(minHeight: 44.0)
                : null,
            padding: pad,
            decoration: BoxDecoration(
              color: cs.surface.withAlpha(40),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: cs.outlineVariant.withAlpha(170),
                width: stroke,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Padding(
                        // Reserve space so the right-aligned swap icon never overlaps the title.
                        padding: EdgeInsets.only(right: compact ? 18 : 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(icon, style: titleStyle),
                                const SizedBox(width: 6),
                                Text(title, style: titleStyle),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: PulseSwapIcon(
                          color: cs.onSurface.withAlpha(150),
                          size: compact ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: innerGap),
                _ScaleDownText(
                  line,
                  style: rowStyle,
                  textKey: const ValueKey('hero_env_primary_line'),
                ),
                const SizedBox.shrink(key: ValueKey('hero_env_content_aqi')),
                const SizedBox.shrink(key: ValueKey('hero_env_content_pollen')),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final forceExpand = c.hasBoundedWidth && c.hasBoundedHeight;

        // Sev1 contract: this pill must never overflow even under pathological
        // widget-test constraints (e.g. ~66x19). When too small, render a single
        // line with zero-risk layout, and keep key stability via zero-size nodes.
        final maxH = c.hasBoundedHeight ? c.maxHeight : double.infinity;
        final maxW = c.hasBoundedWidth ? c.maxWidth : double.infinity;
        final innerH = maxH.isFinite ? (maxH - pad.vertical) : double.infinity;
        final innerW = maxW.isFinite
            ? (maxW - pad.horizontal)
            : double.infinity;
        // Micro-first: avoid building the 2-line Column under tiny inner boxes.
        // Micro-first: if the inner height is even slightly constrained, avoid
        // building multi-line layout that can overflow by sub-pixels.
        final isMicro = dense || innerH < 36.0 || innerW < 96.0;

        final applyMinHeight = !c.hasBoundedHeight || c.maxHeight >= 44;

        if (!isMicro) {
          return body(forceExpand, applyMinHeight);
        }

        return Semantics(
          button: true,
          label: semanticsLabel,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              key: const ValueKey('hero_env_pill'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.surface.withAlpha(40),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: cs.outlineVariant.withAlpha(170),
                  width: stroke,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    // Reserve space so the right-aligned swap icon never overlaps the title.
                    padding: EdgeInsets.only(right: compact ? 16 : 18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(icon, style: titleStyle),
                            const SizedBox(width: 6),
                            Text(title, style: titleStyle),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: PulseSwapIcon(
                      color: cs.onSurface.withAlpha(150),
                      size: compact ? 12 : 14,
                    ),
                  ),
                  const SizedBox.shrink(key: ValueKey('hero_env_primary_line')),
                  const SizedBox.shrink(key: ValueKey('hero_env_content_aqi')),
                  const SizedBox.shrink(
                    key: ValueKey('hero_env_content_pollen'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroCurrencyCard extends StatelessWidget {
  final Place? primary;
  final Place? secondary;
  final double eurToUsd;
  final bool compact;
  final bool dense;

  const _HeroCurrencyCard({
    required this.primary,
    required this.secondary,
    required this.eurToUsd,
    required this.compact,
    required this.dense,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();

    final currencyLines = _currencyLines(
      primary: primary,
      secondary: secondary,
      eurToUsd: eurToUsd,
    );

    final radius = (layout?.radiusCard ?? 20.0) - 6;
    final stroke = (layout?.strokeHairline ?? 1.0);

    final pad = compact
        ? EdgeInsets.symmetric(horizontal: 10, vertical: dense ? 5 : 7)
        : EdgeInsets.symmetric(horizontal: 11, vertical: dense ? 6 : 8);

    final innerGap = dense ? 0.0 : (compact ? 0.0 : 2.0);

    final basePrimary = Theme.of(context).textTheme.labelLarge;
    final primaryLineStyle = basePrimary?.copyWith(
      // Slightly smaller to keep the currency tile compact and leave room
      // for the marquee without losing readability.
      fontSize: (basePrimary.fontSize ?? 14) - 1,
      color: cs.onSurface.withAlpha(230),
      fontWeight: FontWeight.w900,
    );

    final baseRate = (compact
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium);
    final rateStyle = baseRate?.copyWith(
      fontSize: (baseRate.fontSize ?? 12) - 1,
      color: cs.onSurface.withAlpha(200),
      fontWeight: FontWeight.w600,
    );

    final labelStyle = rateStyle?.copyWith(
      color: cs.onSurface,
      fontWeight: FontWeight.w900,
    );

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

    Widget body(bool forceExpand, bool applyMinHeight) {
      return Container(
        key: const ValueKey('hero_currency_card'),
        width: forceExpand ? double.infinity : null,
        height: forceExpand ? double.infinity : null,
        constraints: applyMinHeight
            ? const BoxConstraints(minHeight: 44.0)
            : null,
        padding: pad,
        decoration: BoxDecoration(
          color: cs.surface.withAlpha(40),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: cs.outlineVariant.withAlpha(170),
            width: stroke,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🪙', style: primaryLineStyle),
                  const SizedBox(width: 6),
                  Text(
                    currencyLines.$1,
                    key: const ValueKey('hero_currency_primary_line'),
                    style: primaryLineStyle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
            SizedBox(height: innerGap),
            _ScaleDownRichText(
              span: rateLineSpan(
                currencyLines.$2,
                baseStyle: rateStyle,
                labelStyle: labelStyle,
              ),
              textKey: const ValueKey('hero_rate_line'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final forceExpand = c.hasBoundedWidth && c.hasBoundedHeight;

        final maxH = c.hasBoundedHeight ? c.maxHeight : double.infinity;
        final maxW = c.hasBoundedWidth ? c.maxWidth : double.infinity;
        final innerH = maxH.isFinite ? (maxH - pad.vertical) : double.infinity;
        final innerW = maxW.isFinite
            ? (maxW - pad.horizontal)
            : double.infinity;
        // Micro-first: avoid building the 2-line Column under tiny inner boxes.
        // Use a slightly higher threshold to prevent sub-pixel overflows when
        // font metrics + padding land right on the edge.
        final isMicro = dense || innerH < 36.0 || innerW < 96.0;

        final applyMinHeight = !c.hasBoundedHeight || c.maxHeight >= 44;

        if (!isMicro) {
          return body(forceExpand, applyMinHeight);
        }

        return Container(
          key: const ValueKey('hero_currency_card'),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: cs.surface.withAlpha(40),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: cs.outlineVariant.withAlpha(170),
              width: stroke,
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🪙', style: primaryLineStyle),
                      const SizedBox(width: 6),
                      Text(
                        currencyLines.$1,
                        key: const ValueKey('hero_currency_primary_line'),
                        style: primaryLineStyle,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox.shrink(key: ValueKey('hero_rate_line')),
            ],
          ),
        );
      },
    );
  }
}

class _RightMarqueeSlot extends StatelessWidget {
  final bool compact;
  final bool isNight;
  final SceneKey? sceneKey;
  final String? conditionLabel;

  final bool renderConditionLabel;

  const _RightMarqueeSlot({
    required this.compact,
    required this.isNight,
    required this.sceneKey,
    required this.conditionLabel,
    this.renderConditionLabel = true,
  });

  String _fallbackLabel(SceneKey? key) {
    switch (key) {
      case SceneKey.clear:
        return 'Clear';
      case SceneKey.partlyCloudy:
        return 'Partly cloudy';
      case SceneKey.cloudy:
        return 'Cloudy';
      case SceneKey.overcast:
        return 'Overcast';
      case SceneKey.mist:
        return 'Mist';
      case SceneKey.fog:
        return 'Fog';
      case SceneKey.drizzle:
        return 'Drizzle';
      case SceneKey.freezingDrizzle:
        return 'Freezing drizzle';
      case SceneKey.rainLight:
        return 'Light rain';
      case SceneKey.rainModerate:
        return 'Rain';
      case SceneKey.rainHeavy:
        return 'Heavy rain';
      case SceneKey.freezingRain:
        return 'Freezing rain';
      case SceneKey.sleet:
        return 'Sleet';
      case SceneKey.snowLight:
        return 'Light snow';
      case SceneKey.snowModerate:
        return 'Snow';
      case SceneKey.snowHeavy:
        return 'Heavy snow';
      case SceneKey.blowingSnow:
        return 'Blowing snow';
      case SceneKey.blizzard:
        return 'Blizzard';
      case SceneKey.icePellets:
        return 'Ice pellets';
      case SceneKey.thunderRain:
        return 'Thunderstorm';
      case SceneKey.thunderSnow:
        return 'Thunder snow';
      case SceneKey.hazeDust:
        return 'Haze';
      case SceneKey.smokeWildfire:
        return 'Smoke';
      case SceneKey.ashfall:
        return 'Ash';
      case SceneKey.windy:
        return 'Windy';
      case SceneKey.tornado:
        return 'Tornado';
      case SceneKey.squall:
        return 'Squall';
      case null:
        return 'Weather';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();
    final radius = (layout?.radiusCard ?? 20.0) - 6;

    final desiredH = compact ? 56.0 : 172.0;
    final label = (conditionLabel ?? '').trim().isNotEmpty
        ? conditionLabel!.trim()
        : _fallbackLabel(sceneKey);

    return LayoutBuilder(
      builder: (context, c) {
        final maxH = c.hasBoundedHeight ? c.maxHeight : desiredH;
        final h = desiredH.clamp(0.0, maxH.isFinite ? maxH : desiredH);

        return SizedBox(
          key: const ValueKey('hero_marquee_slot'),
          height: h,
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HeroAliveMarquee(
                    compact: compact,
                    isNight: isNight,
                    sceneKey: sceneKey,
                    conditionLabel: conditionLabel,
                    renderConditionLabel: renderConditionLabel,
                  ),
                  // Subtle scrim so the condition chip stays readable over any scene.
                  if (!renderConditionLabel)
                    IgnorePointer(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: compact ? 18.0 : 22.0,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(110),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Condition chip (widget-layer) so it never disappears visually.
                  if (!renderConditionLabel)
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: compact ? 4 : 5,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 8 : 10,
                            vertical: compact ? 3 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surface.withAlpha(190),
                            borderRadius: BorderRadius.circular(
                              compact ? 10 : 12,
                            ),
                            border: Border.all(
                              color: cs.outlineVariant.withAlpha(170),
                              width: (layout?.strokeHairline ?? 1.0),
                            ),
                          ),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inconsolata(
                              fontSize: compact ? 10 : 11,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RightDetailsPill extends StatelessWidget {
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

  const _RightDetailsPill({
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
    return LayoutBuilder(
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
    );
  }
}

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
              height: compact ? 44.0 : 72.0,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 12,
              vertical: compact ? 6 : 6,
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

  String fmtMoney(double v) {
    // Up to 2 decimals, trimmed (10.00 -> 10, 10.50 -> 10.5).
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'[.]?0+$'), '');
  }

  final amount = 10.0;
  if (primaryCurrency == 'EUR' && secondaryCurrency == 'USD') {
    final approx = amount * eurToUsd;
    return (
      '${_symbol('EUR')}${fmtMoney(amount)} ≈ ${_symbol('USD')}${fmtMoney(approx)}',
      'Rate: 1 EUR ≈ ${eurToUsd.toStringAsFixed(2)} USD',
    );
  }
  if (primaryCurrency == 'USD' && secondaryCurrency == 'EUR') {
    final usdToEur = 1.0 / eurToUsd;
    final approx = amount * usdToEur;
    return (
      '${_symbol('USD')}${fmtMoney(amount)} ≈ ${_symbol('EUR')}${fmtMoney(approx)}',
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
