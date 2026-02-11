import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'hero_alive_marquee.dart';
import 'pulse_swap_icon.dart';

import '../../../models/place.dart';
import '../../../data/cities.dart' show kCurrencySymbols;
import '../../../data/country_currency_map.dart';
import '../../../theme/theme_extensions.dart';
import '../../../theme/dracula_palette.dart';
import '../../../utils/timezone_utils.dart';
import '../models/dashboard_copy.dart';
import '../models/dashboard_live_data.dart';
import '../models/dashboard_session_controller.dart';

class PlacesHeroV2 extends StatelessWidget {
  final Place? home;
  final Place? destination;
  final DashboardSessionController session;
  final DashboardLiveDataController liveData;

  // When false, widget subtree omits deterministic ValueKeys used by tests.
  //
  // Wizard previews sometimes render multiple hero widgets on a single
  // screen, so disabling test keys avoids collisions while keeping the
  // dashboard tests stable.
  final bool includeTestKeys;

  const PlacesHeroV2({
    super.key,
    this.includeTestKeys = true,
    required this.home,
    required this.destination,
    required this.session,
    required this.liveData,
  });

  @override
  Widget build(BuildContext context) {
    // This widget is composed by the dashboard board and is passed the
    // already-instantiated controllers.
    //
    // Contract: PlacesHeroV2 should not require Provider wiring.
    final session = this.session;
    final liveData = this.liveData;

    // React to session/live updates (clock override, refreshes, etc).
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[session, liveData]),
      builder: (context, _) {
        final primary = session.reality == DashboardReality.home
            ? home
            : destination;
        final secondary = session.reality == DashboardReality.home
            ? destination
            : home;

        final nowUtc = liveData.nowUtc;

        final primaryZone = primary == null
            ? null
            : TimezoneUtils.nowInZone(primary.timeZoneId, nowUtc: nowUtc);

        // Delta hours is computed inside the clock header block where it is
        // rendered. Keeping it here created an unused_local_variable warning.

        final primaryWeather = primary == null
            ? null
            : liveData.weatherFor(primary);
        final primaryEmergency = primary == null
            ? const WeatherEmergencyAssessment(
                severity: WeatherEmergencySeverity.none,
                reasonKey: 'none',
                source: 'fallback',
              )
            : liveData.emergencyFor(primary);
        final primarySun = primary == null ? null : liveData.sunFor(primary);

        // Night heuristic: allow dev override first, else prefer sun info, else fallback to hour-based.
        final debugOverride = liveData.debugWeatherOverride;
        bool? forcedIsNight;
        if (debugOverride is WeatherDebugOverrideCoarse) {
          forcedIsNight = debugOverride.isNightOverride;
        } else if (debugOverride is WeatherDebugOverrideWeatherApi) {
          forcedIsNight = debugOverride.isNight;
        }

        bool isNightFromSun() {
          final sun = primarySun;
          if (sun == null) {
            final h = primaryZone?.local.hour ?? DateTime.now().hour;
            return h < 6 || h >= 20;
          }
          final now = primaryZone?.local ?? DateTime.now();
          final pTz = primary?.timeZoneId;
          if (pTz == null) {
            return false;
          }
          final sunriseLocal = TimezoneUtils.nowInZone(
            pTz,
            nowUtc: sun.sunriseUtc,
          ).local;
          final sunsetLocal = TimezoneUtils.nowInZone(
            pTz,
            nowUtc: sun.sunsetUtc,
          ).local;
          return now.isBefore(sunriseLocal) || now.isAfter(sunsetLocal);
        }

        final isNight = forcedIsNight ?? isNightFromSun();

        final cs = Theme.of(context).colorScheme;
        final layout = Theme.of(context).extension<UnitanaLayoutTokens>();
        final radius = layout?.radiusCard ?? 20.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact =
                constraints.maxHeight < 280 || constraints.maxWidth < 320;

            // Compact surfaces (e.g., 320×568 tests) are extremely tight.
            // Keep these values whole-numbered to avoid sub-pixel rounding
            // overflows in widget tests.
            final padH = isCompact ? 9.0 : 10.0;
            // Pack E kickoff: reclaim a little vertical budget from chrome so
            // the marquee can use more of the hero body space on phones.
            final padV = isCompact ? 0.0 : 8.0;
            final gap = isCompact ? 4.0 : 5.0;

            final hero = Container(
              padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.light
                      ? cs.outlineVariant.withAlpha(205)
                      : DraculaPalette.currentLine.withAlpha(115),
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
                    includeTestKeys: includeTestKeys,
                  ),
                  SizedBox(height: gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ClocksHeaderBlock(
                          primary: primary,
                          secondary: secondary,
                          primaryTzId: primary?.timeZoneId,
                          secondaryTzId: secondary?.timeZoneId,
                          nowUtc: liveData.nowUtc,
                          compact: isCompact,
                          includeTestKeys: includeTestKeys,
                        ),
                        SizedBox(height: gap),
                        Expanded(
                          child: _HeroBandsBody(
                            primary: primary,
                            primaryWeather: primaryWeather,
                            secondary: secondary,
                            primaryEnv: primary == null
                                ? null
                                : liveData.envFor(primary),
                            liveData: liveData,
                            envMode: session.heroEnvPillMode,
                            onToggleEnvMode: session.toggleHeroEnvPillMode,
                            sun: primarySun,
                            sceneKey: primaryWeather?.sceneKey,
                            conditionLabel: primaryWeather?.conditionText,
                            emergency: primaryEmergency,
                            isNight: isNight,
                            primaryTzId: primary?.timeZoneId,
                            secondaryTzId: secondary?.timeZoneId,
                            primaryUse24h: primary?.use24h,
                            secondaryUse24h: secondary?.use24h,
                            detailsMode: session.heroDetailsPillMode,
                            onToggleDetailsMode:
                                session.toggleHeroDetailsPillMode,
                            compact: isCompact,
                            gap: gap,
                            includeTestKeys: includeTestKeys,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            final needsHeightBound =
                !constraints.hasBoundedHeight ||
                constraints.maxHeight.isInfinite;
            if (needsHeightBound) {
              final w = constraints.maxWidth;
              final fallbackHeight = w < 360
                  ? 260.0
                  : (w < 420 ? 282.0 : 312.0);
              return SizedBox(height: fallbackHeight, child: hero);
            }
            return hero;
          },
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
  final bool includeTestKeys;

  const _SegmentedRealityToggle({
    required this.home,
    required this.destination,
    required this.selected,
    required this.onChanged,
    this.compact = false,
    this.includeTestKeys = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();
    final r = (layout?.radiusButton ?? 16.0) - 6;

    final setCityLabel = DashboardCopy.dashboardSetCityCta(context);
    final leftLabel =
        '${_flagEmojiFromIso2(destination?.countryCode)} ${destination?.cityName ?? setCityLabel}';
    final rightLabel =
        '${_flagEmojiFromIso2(home?.countryCode)} ${home?.cityName ?? setCityLabel}';

    return Container(
      height: compact ? 40 : 44,
      decoration: BoxDecoration(
        color: cs.surface.withAlpha(40),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: cs.outlineVariant.withAlpha(160), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: KeyedSubtree(
              key: const ValueKey('places_hero_segment_dest'),
              child: _SegmentButton(
                key: includeTestKeys
                    ? const ValueKey('places_hero_segment_destination')
                    : null,
                text: leftLabel,
                selected: selected == DashboardReality.destination,
                alignment: Alignment.center,
                compact: compact,
                onTap: () => onChanged(DashboardReality.destination),
              ),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              key: includeTestKeys
                  ? const ValueKey('places_hero_segment_home')
                  : null,
              text: rightLabel,
              selected: selected == DashboardReality.home,
              alignment: Alignment.center,
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
          textAlign: alignment == Alignment.center
              ? TextAlign.center
              : (alignment == Alignment.centerRight
                    ? TextAlign.right
                    : TextAlign.left),
          style:
              ((compact
                              ? Theme.of(context).textTheme.titleSmall
                              : Theme.of(context).textTheme.titleMedium)
                          ?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ) ??
                      const TextStyle())
                  .merge(GoogleFonts.robotoSlab()),
        ),
      ),
    );
  }
}

class _AqiDot extends StatelessWidget {
  const _AqiDot({required this.color, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
  final Place? primary;
  final Place? secondary;
  final String? primaryTzId;
  final String? secondaryTzId;
  final DateTime nowUtc;
  final bool compact;
  final bool includeTestKeys;

  const _ClocksHeaderBlock({
    required this.primary,
    required this.secondary,
    required this.primaryTzId,
    required this.secondaryTzId,
    required this.nowUtc,
    required this.compact,
    this.includeTestKeys = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = primary;
    final s = secondary;

    final pTz = primaryTzId ?? 'UTC';
    final sTz = secondaryTzId ?? 'UTC';

    final primaryNow = TimezoneUtils.nowInZone(pTz, nowUtc: nowUtc);
    final secondaryNow = TimezoneUtils.nowInZone(sTz, nowUtc: nowUtc);

    final deltaHours = TimezoneUtils.deltaHours(primaryNow, secondaryNow);
    final String? deltaLabel = (deltaHours == 0)
        ? null
        : TimezoneUtils.formatDeltaLabel(deltaHours);

    final pad = EdgeInsets.only(top: compact ? 6 : 6, bottom: compact ? 6 : 6);

    final primaryClock =
        '${TimezoneUtils.formatClock(primaryNow, use24h: p?.use24h ?? true)} ${primaryNow.abbreviation}';
    final secondaryClock =
        '${TimezoneUtils.formatClock(secondaryNow, use24h: s?.use24h ?? true)} ${secondaryNow.abbreviation}';

    final primaryDate = TimezoneUtils.formatShortDate(primaryNow);
    final secondaryDate = TimezoneUtils.formatShortDate(secondaryNow);

    final bool sameDate = primaryDate == secondaryDate;

    final String timeLineCore = '$primaryClock • $secondaryClock';
    final String dateLine = sameDate
        ? primaryDate
        : '$primaryDate • $secondaryDate';

    final TextStyle baseTimeStyle =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 16);
    final TextStyle baseDateStyle =
        Theme.of(context).textTheme.labelMedium ??
        const TextStyle(fontSize: 13);

    final TextStyle timeStyle = baseTimeStyle.copyWith(
      fontWeight: FontWeight.w800,
      color: cs.onSurface.withAlpha(235),
      letterSpacing: 0.2,
    );

    final TextStyle dateStyle = baseDateStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurface.withAlpha(175),
      letterSpacing: 0.1,
    );

    final TextStyle deltaStyle = timeStyle.copyWith(
      color: Theme.of(context).brightness == Brightness.light
          ? cs.primary.withAlpha(225)
          : DraculaPalette.cyan.withAlpha(235),
    );

    return Padding(
      padding: pad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            key: includeTestKeys
                ? const ValueKey('places_hero_clock_detail')
                : null,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: timeStyle,
              children: [
                TextSpan(text: timeLineCore),
                if (deltaLabel != null) const TextSpan(text: ' • '),
                if (deltaLabel != null)
                  TextSpan(text: deltaLabel, style: deltaStyle),
              ],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            dateLine,
            key: includeTestKeys
                ? const ValueKey('places_hero_clock_date')
                : null,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: dateStyle,
          ),
        ],
      ),
    );
  }
}

class _HeroBandsBody extends StatelessWidget {
  final Place? primary;
  final WeatherSnapshot? primaryWeather;
  final Place? secondary;
  final EnvSnapshot? primaryEnv;
  final DashboardLiveDataController liveData;
  final HeroEnvPillMode envMode;
  final VoidCallback onToggleEnvMode;

  final SunTimesSnapshot? sun;
  final SceneKey? sceneKey;
  final String? conditionLabel;
  final WeatherEmergencyAssessment emergency;
  final bool isNight;
  final String? primaryTzId;
  final String? secondaryTzId;
  final bool? primaryUse24h;
  final bool? secondaryUse24h;
  final HeroDetailsPillMode detailsMode;
  final VoidCallback onToggleDetailsMode;

  final bool compact;
  final double gap;
  final bool includeTestKeys;

  const _HeroBandsBody({
    required this.primary,
    required this.primaryWeather,
    required this.secondary,
    required this.primaryEnv,
    required this.liveData,
    required this.envMode,
    required this.onToggleEnvMode,
    required this.sun,
    required this.sceneKey,
    required this.conditionLabel,
    required this.emergency,
    required this.isNight,
    required this.primaryTzId,
    required this.secondaryTzId,
    required this.primaryUse24h,
    required this.secondaryUse24h,
    required this.detailsMode,
    required this.onToggleDetailsMode,
    required this.compact,
    required this.gap,
    this.includeTestKeys = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final innerW = c.maxWidth;
        final colGap = gap;
        final stackGap = compact ? 4.0 : 2.0;

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
                compact: compact,
                includeTestKeys: includeTestKeys,
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
                  emergency: emergency,
                  includeTestKeys: includeTestKeys,
                  renderConditionLabel: false,
                ),
              ),
            ),
          ],
        );

        final bottomRow = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: leftW,
              child: _LeftEnvCurrencyStack(
                primary: primary,
                secondary: secondary,
                primaryEnv: primaryEnv,
                liveData: liveData,
                envMode: envMode,
                onToggleEnvMode: onToggleEnvMode,
                compact: compact,
                gap: stackGap,
                includeTestKeys: includeTestKeys,
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
                primaryPlace: primary,
                primaryWeather: primaryWeather,
                compact: compact,
                includeTestKeys: includeTestKeys,
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
            children: [
              SizedBox(height: topH, child: topRow),
              SizedBox(height: colGap),
              SizedBox(height: bottomH, child: bottomRow),
            ],
          );
        }

        if (!c.hasBoundedHeight) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              topRow,
              SizedBox(height: colGap),
              SizedBox(height: bottomMinH, child: bottomRow),
            ],
          );
        }

        return Column(
          children: [
            Expanded(child: topRow),
            SizedBox(height: colGap),
            SizedBox(height: bottomMinH, child: bottomRow),
          ],
        );
      },
    );
  }
}

class _LeftTempBand extends StatelessWidget {
  final Place? primary;
  final WeatherSnapshot? primaryWeather;
  final bool compact;
  final bool includeTestKeys;

  const _LeftTempBand({
    required this.primary,
    required this.primaryWeather,
    required this.compact,
    this.includeTestKeys = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final primaryTemp = (primary != null && primaryWeather != null)
        ? _formatTemp(primary!, primaryWeather!)
        : (primary == null
              ? '--'
              : (primary!.unitSystem.toLowerCase() == 'imperial'
                    ? '--°F'
                    : '--°C'));

    final secondaryTemp = (primary != null && primaryWeather != null)
        ? _formatAltTemp(primary!, primaryWeather!)
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
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            key: includeTestKeys ? const ValueKey('hero_primary_temp') : null,
            primaryTemp,
            style: primaryTempStyle,
          ),
          if (secondaryTemp.isNotEmpty) ...[
            const SizedBox(width: 8),
            Padding(
              padding: EdgeInsets.only(bottom: compact ? 5 : 10),
              child: Text(
                key: includeTestKeys
                    ? const ValueKey('hero_secondary_temp')
                    : null,
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
  final EnvSnapshot? primaryEnv;
  final DashboardLiveDataController liveData;
  final HeroEnvPillMode envMode;
  final VoidCallback onToggleEnvMode;
  final bool compact;
  final double gap;
  final bool includeTestKeys;

  const _LeftEnvCurrencyStack({
    required this.primary,
    required this.secondary,
    required this.primaryEnv,
    required this.liveData,
    required this.envMode,
    required this.onToggleEnvMode,
    required this.compact,
    required this.gap,
    this.includeTestKeys = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Guardrail: avoid flex children when the incoming height is unbounded.
        // This can happen in sliver measurement paths and some widget-test setups.
        if (!c.hasBoundedHeight) {
          final innerGap = gap < 2.0 ? 2.0 : (gap > 10.0 ? 10.0 : gap);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44.0,
                child: _HeroEnvPill(
                  envMode: envMode,
                  onToggle: onToggleEnvMode,
                  primaryEnv: primaryEnv,
                  compact: compact,
                  dense: true,
                  includeTestKeys: includeTestKeys,
                ),
              ),
              SizedBox(height: innerGap),
              SizedBox(
                height: 44.0,
                child: _HeroCurrencyCard(
                  primary: primary,
                  secondary: secondary,
                  liveData: liveData,
                  compact: compact,
                  dense: true,
                  includeTestKeys: includeTestKeys,
                ),
              ),
            ],
          );
        }

        final innerGap = gap < 2.0 ? 2.0 : (gap > 10.0 ? 10.0 : gap);
        final tileH = ((c.maxHeight - innerGap) / 2).clamp(
          0.0,
          double.infinity,
        );
        final dense = tileH < (compact ? 66.0 : 86.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _HeroEnvPill(
                envMode: envMode,
                onToggle: onToggleEnvMode,
                primaryEnv: primaryEnv,
                compact: compact,
                dense: dense,
                includeTestKeys: includeTestKeys,
              ),
            ),
            SizedBox(height: innerGap),
            Expanded(
              child: _HeroCurrencyCard(
                primary: primary,
                secondary: secondary,
                liveData: liveData,
                compact: compact,
                dense: dense,
                includeTestKeys: includeTestKeys,
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
  final EnvSnapshot? primaryEnv;
  final bool compact;
  final bool dense;
  final bool includeTestKeys;

  const _HeroEnvPill({
    required this.envMode,
    required this.onToggle,
    required this.primaryEnv,
    required this.compact,
    required this.dense,
    this.includeTestKeys = true,
  });

  static String _fmtInt(int? v) => v == null ? '--' : v.toString();

  static String _fmt1(double? v) {
    if (v == null) return '--';
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();

    final radius = (layout?.radiusCard ?? 20.0) - 6;
    final stroke = (layout?.strokeHairline ?? 1.0);

    final pad = compact
        ? EdgeInsets.symmetric(horizontal: 10, vertical: dense ? 5 : 7)
        : EdgeInsets.symmetric(horizontal: 11, vertical: dense ? 6 : 8);

    final baseRow = (compact
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium);
    final rowStyle = (baseRow ?? const TextStyle()).copyWith(
      // Slightly smaller to preserve headroom in narrow cases (JPY, long city
      // pairs) without forcing micro mode.
      fontSize: (baseRow?.fontSize ?? 12) - 1,
      color: cs.onSurface.withAlpha(210),
      // Env reads better when it isn't shouting, and it visually centers more
      // cleanly against the swap icon when line metrics are tighter.
      fontWeight: FontWeight.w500,
      height: 1.0,
    );

    final labelStyle = rowStyle.copyWith(
      fontWeight: FontWeight.w900,
      color: cs.onSurface.withAlpha(235),
    );

    final unitHintStyle = rowStyle.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: (rowStyle.fontSize ?? 12) - 1,
      color: cs.onSurface.withAlpha(165),
    );

    final envStrut = StrutStyle(
      fontSize: rowStyle.fontSize,
      height: 1.0,
      forceStrutHeight: true,
    );

    final isAqi = envMode == HeroEnvPillMode.aqi;
    final label = DashboardCopy.heroEnvLabel(context, isAqi: isAqi);

    Color aqiColor(int? v) {
      if (v == null) return cs.onSurface.withAlpha(120);
      if (v <= 50) return const Color(0xFF00E400); // Good
      if (v <= 100) return const Color(0xFFFFFF00); // Moderate
      if (v <= 150) return const Color(0xFFFF7E00); // USG
      if (v <= 200) return const Color(0xFFFF0000); // Unhealthy
      if (v <= 300) return const Color(0xFF8F3F97); // Very Unhealthy
      return const Color(0xFF7E0023); // Hazardous
    }

    String aqiBandShort(int? v) {
      if (v == null) return '—';
      if (v <= 50) {
        return DashboardCopy.heroEnvBandShort(
          context,
          isAqi: true,
          bandKey: 'good',
        );
      }
      if (v <= 100) {
        return DashboardCopy.heroEnvBandShort(
          context,
          isAqi: true,
          bandKey: 'moderate',
        );
      }
      if (v <= 150) {
        return DashboardCopy.heroEnvBandShort(
          context,
          isAqi: true,
          bandKey: 'usg',
        );
      }
      if (v <= 200) {
        return DashboardCopy.heroEnvBandShort(
          context,
          isAqi: true,
          bandKey: 'unhealthy',
        );
      }
      if (v <= 300) {
        return DashboardCopy.heroEnvBandShort(
          context,
          isAqi: true,
          bandKey: 'veryUnhealthy',
        );
      }
      return DashboardCopy.heroEnvBandShort(
        context,
        isAqi: true,
        bandKey: 'hazardous',
      );
    }

    String pollenBandShort(double? v) {
      if (v == null) return '—';
      if (v <= 1.0) {
        return DashboardCopy.heroEnvBandShort(
          context,
          isAqi: false,
          bandKey: 'low',
        );
      }
      if (v <= 2.0) {
        return DashboardCopy.heroEnvBandShort(
          context,
          isAqi: false,
          bandKey: 'medium',
        );
      }
      if (v <= 3.0) {
        return DashboardCopy.heroEnvBandShort(
          context,
          isAqi: false,
          bandKey: 'high',
        );
      }
      return DashboardCopy.heroEnvBandShort(
        context,
        isAqi: false,
        bandKey: 'veryHigh',
      );
    }

    // Env values are location metrics, not unit conversions. Per hero semantics,
    // show the selected (primary) city only, and let the hero toggle switch the
    // underlying city context.
    final aqi = primaryEnv?.usAqi;
    final pollen = primaryEnv?.pollenIndex;
    final valueText = isAqi ? _fmtInt(aqi) : _fmt1(pollen);

    final semanticsLabel = DashboardCopy.heroEnvSemantics(
      context,
      isAqi: isAqi,
    );

    Widget body(bool forceExpand, bool applyMinHeight) {
      return Semantics(
        button: true,
        label: semanticsLabel,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            key: includeTestKeys ? const ValueKey('hero_env_pill') : null,
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  // Reserve space so the right-aligned swap icon never overlaps the text.
                  padding: EdgeInsets.only(right: compact ? 18 : 20),
                  child: Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: compact ? 12 : 13,
                            child: Center(
                              child: isAqi
                                  ? _AqiDot(
                                      color: aqiColor(aqi),
                                      size: compact ? 9 : 10,
                                    )
                                  : Text(
                                      '🌼',
                                      style: rowStyle,
                                      strutStyle: envStrut,
                                      textHeightBehavior:
                                          const TextHeightBehavior(
                                            applyHeightToFirstAscent: false,
                                            applyHeightToLastDescent: false,
                                          ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          RichText(
                            key: includeTestKeys
                                ? const ValueKey('hero_env_primary_line')
                                : null,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            text: TextSpan(
                              style: rowStyle,
                              children: [
                                TextSpan(text: label, style: labelStyle),
                                if (!isAqi)
                                  TextSpan(
                                    text: DashboardCopy.heroEnvIndexSuffix(
                                      context,
                                    ),
                                    style: unitHintStyle,
                                  ),
                                TextSpan(text: ' $valueText'),
                                if (!compact)
                                  TextSpan(
                                    text: isAqi
                                        ? ' • ${aqiBandShort(aqi)}'
                                        : ' • ${pollenBandShort(pollen)}',
                                    style: unitHintStyle,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PulseSwapIcon(
                      color: cs.onSurface.withAlpha(150),
                      size: compact ? 14 : 16,
                    ),
                  ),
                ),
                SizedBox.shrink(
                  key: includeTestKeys
                      ? const ValueKey('hero_env_content_aqi')
                      : null,
                ),
                SizedBox.shrink(
                  key: includeTestKeys
                      ? const ValueKey('hero_env_content_pollen')
                      : null,
                ),
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
              key: includeTestKeys ? const ValueKey('hero_env_pill') : null,
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
                fit: StackFit.expand,
                children: [
                  Padding(
                    // Reserve space so the right-aligned swap icon never overlaps the text.
                    padding: EdgeInsets.only(right: compact ? 16 : 18),
                    child: Align(
                      alignment: Alignment.center,
                      child: _ScaleDownRichText(
                        textKey: includeTestKeys
                            ? const ValueKey('hero_env_primary_line')
                            : null,
                        alignment: Alignment.center,
                        textAlign: TextAlign.left,
                        span: TextSpan(
                          style: rowStyle,
                          children: [
                            if (isAqi)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: _AqiDot(
                                    color: aqiColor(aqi),
                                    size: compact ? 8 : 9,
                                  ),
                                ),
                              )
                            else
                              const TextSpan(text: '🌼 '),
                            TextSpan(text: label, style: labelStyle),
                            if (!isAqi)
                              TextSpan(
                                text: DashboardCopy.heroEnvIndexSuffix(context),
                                style: unitHintStyle,
                              ),
                            TextSpan(text: ' $valueText'),
                            if (!compact)
                              TextSpan(
                                text: isAqi
                                    ? ' • ${aqiBandShort(aqi)}'
                                    : ' • ${pollenBandShort(pollen)}',
                                style: unitHintStyle,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PulseSwapIcon(
                        color: cs.onSurface.withAlpha(150),
                        size: compact ? 12 : 14,
                      ),
                    ),
                  ),
                  SizedBox.shrink(
                    key: includeTestKeys
                        ? const ValueKey('hero_env_content_aqi')
                        : null,
                  ),
                  SizedBox.shrink(
                    key: includeTestKeys
                        ? const ValueKey('hero_env_content_pollen')
                        : null,
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
  final DashboardLiveDataController liveData;
  final bool compact;
  final bool dense;
  final bool includeTestKeys;

  const _HeroCurrencyCard({
    required this.primary,
    required this.secondary,
    required this.liveData,
    required this.compact,
    required this.dense,
    this.includeTestKeys = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();

    final currencyLines = _currencyLines(
      context: context,
      primary: primary,
      secondary: secondary,
      pairRate: (primary == null || secondary == null)
          ? null
          : liveData.currencyRate(
              fromCode: _currencyCodeForPlace(primary),
              toCode: _currencyCodeForPlace(secondary),
            ),
    );

    final radius = (layout?.radiusCard ?? 20.0) - 6;
    final stroke = (layout?.strokeHairline ?? 1.0);

    final pad = compact
        ? EdgeInsets.symmetric(horizontal: 10, vertical: dense ? 5 : 7)
        : EdgeInsets.symmetric(horizontal: 11, vertical: dense ? 6 : 8);

    final innerGap = dense ? 0.0 : (compact ? 0.0 : 2.0);

    final basePrimary = Theme.of(context).textTheme.labelLarge;
    final primaryLineStyle = basePrimary?.copyWith(
      // Currency can grow dramatically (JPY, KRW, VND). Keep the default a bit
      // smaller so we scale less often, preserving clarity.
      // Slightly larger for readability; this line is often glanced at quickly.
      fontSize: (basePrimary.fontSize ?? 14) - (compact ? 2 : 1),
      color: cs.onSurface.withAlpha(230),
      // Match Env: avoid ultra-bold numerals (they feel cramped at JPY-scale).
      fontWeight: FontWeight.w500,
      height: 1.0,
    );

    final currencyStrut = StrutStyle(
      fontSize: primaryLineStyle?.fontSize,
      height: 1.0,
      forceStrutHeight: true,
    );

    final baseRate = (compact
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium);
    final rateStyle = baseRate?.copyWith(
      fontSize: (baseRate.fontSize ?? 12) - 1,
      color: cs.onSurface.withAlpha(200),
      fontWeight: FontWeight.w500,
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
      final prefix = DashboardCopy.heroCurrencyRatePrefix(context);
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

    InlineSpan currencyPrimarySpan(
      String line, {
      required TextStyle? baseStyle,
      required TextStyle? symbolStyle,
    }) {
      final trimmed = line.trim();
      final parts = trimmed.split('≈');
      if (parts.length == 2) {
        final left = parts[0].trim();
        final right = parts[1].trim();

        String sym(String s) =>
            s.isNotEmpty && !RegExp(r'[0-9\-]').hasMatch(s[0]) ? s[0] : '';
        String rest(String s) => sym(s).isEmpty ? s : s.substring(1);

        final lSym = sym(left);
        final rSym = sym(right);

        return TextSpan(
          style: baseStyle,
          children: [
            if (lSym.isNotEmpty) TextSpan(text: lSym, style: symbolStyle),
            TextSpan(text: rest(left), style: baseStyle),
            const TextSpan(text: ' ≈ '),
            if (rSym.isNotEmpty) TextSpan(text: rSym, style: symbolStyle),
            TextSpan(text: rest(right), style: baseStyle),
          ],
        );
      }
      return TextSpan(text: trimmed, style: baseStyle);
    }

    Widget body(bool forceExpand, bool applyMinHeight) {
      return Container(
        key: includeTestKeys ? const ValueKey('hero_currency_card') : null,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🪙',
                    style: primaryLineStyle,
                    strutStyle: currencyStrut,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                  ),
                  const SizedBox(width: 6),
                  RichText(
                    key: includeTestKeys
                        ? const ValueKey('hero_currency_primary_line')
                        : null,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    text: currencyPrimarySpan(
                      currencyLines.$1,
                      baseStyle: primaryLineStyle,
                      symbolStyle: primaryLineStyle?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface.withAlpha(245),
                      ),
                    ),
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
              textKey: includeTestKeys
                  ? const ValueKey('hero_rate_line')
                  : null,
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
          key: includeTestKeys ? const ValueKey('hero_currency_card') : null,
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
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🪙',
                        style: primaryLineStyle,
                        strutStyle: currencyStrut,
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currencyLines.$1,
                        key: includeTestKeys
                            ? const ValueKey('hero_currency_primary_line')
                            : null,
                        style: primaryLineStyle,
                        strutStyle: currencyStrut,
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
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
  final WeatherEmergencyAssessment emergency;
  final bool includeTestKeys;

  final bool renderConditionLabel;

  const _RightMarqueeSlot({
    required this.compact,
    required this.isNight,
    required this.sceneKey,
    required this.conditionLabel,
    required this.emergency,
    this.includeTestKeys = true,
    this.renderConditionLabel = true,
  });

  Color _alertTone(BuildContext context, WeatherEmergencySeverity severity) {
    final cs = Theme.of(context).colorScheme;
    switch (severity) {
      case WeatherEmergencySeverity.emergency:
        return Colors.redAccent.shade700;
      case WeatherEmergencySeverity.warning:
        return Colors.deepOrangeAccent.shade400;
      case WeatherEmergencySeverity.watch:
        return cs.secondary;
      case WeatherEmergencySeverity.advisory:
        return cs.primary;
      case WeatherEmergencySeverity.none:
        return cs.outlineVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final layout = Theme.of(context).extension<UnitanaLayoutTokens>();
    final radius = (layout?.radiusCard ?? 20.0) - 6;

    // Marquee sizing policy (P1.16a): fill the available top-row budget when it
    // is bounded by the hero layout. This makes the animation feel intentional
    // (not a small stamp) while keeping micro/test harness constraints safe.
    final desiredH = compact ? 56.0 : 172.0;
    final label = DashboardCopy.weatherConditionLabel(
      context,
      sceneKey: sceneKey,
      rawText: conditionLabel,
    );

    return LayoutBuilder(
      builder: (context, c) {
        // If the hero has explicitly allocated height for the top row, take it.
        // Otherwise, fall back to a conservative fixed height so unbounded
        // layouts don't explode in size.
        final double h;
        if (c.hasBoundedHeight && c.maxHeight.isFinite) {
          h = c.maxHeight.clamp(0.0, double.infinity);
        } else {
          h = desiredH;
        }

        return SizedBox(
          key: includeTestKeys ? const ValueKey('hero_marquee_slot') : null,
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
                  if (emergency.isActive)
                    IgnorePointer(
                      child: Container(
                        color: _alertTone(
                          context,
                          emergency.severity,
                        ).withAlpha(20),
                      ),
                    ),
                  HeroAliveMarquee(
                    includeTestKeys: includeTestKeys,
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
                  if (emergency.isActive)
                    Positioned(
                      top: compact ? 4 : 6,
                      right: compact ? 4 : 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _alertTone(
                            context,
                            emergency.severity,
                          ).withAlpha(210),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 6 : 8,
                            vertical: compact ? 2 : 3,
                          ),
                          child: Text(
                            DashboardCopy.weatherEmergencyShortLabel(
                              context,
                              severity: emergency.severity,
                            ),
                            style: GoogleFonts.inconsolata(
                              fontSize: compact ? 8 : 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
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
  final Place? primaryPlace;
  final WeatherSnapshot? primaryWeather;
  final bool compact;
  final bool includeTestKeys;

  const _RightDetailsPill({
    required this.sun,
    required this.primaryTzId,
    required this.secondaryTzId,
    required this.primaryUse24h,
    required this.secondaryUse24h,
    required this.detailsMode,
    required this.onToggleDetailsMode,
    required this.primaryPlace,
    required this.primaryWeather,
    required this.compact,
    this.includeTestKeys = true,
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
                primaryPlace: primaryPlace,
                primaryWeather: primaryWeather,
                compact: compact,
                includeTestKeys: includeTestKeys,
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
  final Place? primaryPlace;
  final WeatherSnapshot? primaryWeather;
  final bool compact;
  final bool includeTestKeys;

  const _SunTimesPill({
    required this.sun,
    required this.primaryTzId,
    required this.secondaryTzId,
    required this.primaryUse24h,
    required this.secondaryUse24h,
    required this.detailsMode,
    required this.onToggleDetailsMode,
    required this.primaryPlace,
    required this.primaryWeather,
    required this.compact,
    this.includeTestKeys = true,
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
            ?.copyWith(
              fontWeight: FontWeight.w800,
              // Slight downscale so the details header sits more in proportion
              // with surrounding hero typography.
              fontSize:
                  ((compact
                          ? Theme.of(context).textTheme.titleSmall?.fontSize
                          : Theme.of(
                              context,
                            ).textTheme.titleMedium?.fontSize) ??
                      (compact ? 14 : 16)) -
                  1.0,
            );

    final baseRow = (compact
        ? Theme.of(context).textTheme.bodySmall
        : Theme.of(context).textTheme.bodyMedium);
    final rowStyle = (baseRow ?? const TextStyle()).copyWith(
      color: cs.onSurface.withAlpha(220),
      fontWeight: FontWeight.w600,
      // Slight downscale for visual parity against adjacent AQI/currency text.
      fontSize: ((baseRow?.fontSize ?? (compact ? 12 : 14)) - 0.8),
      // Tighten line height slightly so the sun/wind detail content fits
      // inside the fixed-height details region without overflow.
      height: 1.05,
    );

    String rise = '🌅 --:--';
    String set = '🌇 --:--';

    if (sun == null && primaryTzId != null && secondaryTzId != null) {
      final pZ = TimezoneUtils.nowInZone(primaryTzId!);
      final sZ = TimezoneUtils.nowInZone(secondaryTzId!);
      rise = '🌅 --:-- ${pZ.abbreviation} (--:-- ${sZ.abbreviation})';
      set = '🌇 --:-- ${pZ.abbreviation} (--:-- ${sZ.abbreviation})';
    }

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

      // Hero semantics: this pill teaches time zones, not two separate city events.
      // Use the selected city's clock preference for both values so the row reads
      // as a single statement with a parenthetical conversion.
      final use24 = primaryUse24h ?? true;

      final riseP = TimezoneUtils.formatClock(risePrimary, use24h: use24);
      final riseS = TimezoneUtils.formatClock(riseSecondary, use24h: use24);
      rise =
          '🌅 $riseP ${risePrimary.abbreviation} ($riseS ${riseSecondary.abbreviation})';

      final setP = TimezoneUtils.formatClock(setPrimary, use24h: use24);
      final setS = TimezoneUtils.formatClock(setSecondary, use24h: use24);
      set =
          '🌇 $setP ${setPrimary.abbreviation} ($setS ${setSecondary.abbreviation})';
    }

    final isWind = detailsMode == HeroDetailsPillMode.wind;
    final semanticsLabel = DashboardCopy.heroDetailsSemantics(
      context,
      isWind: isWind,
    );

    Widget titleRow(String icon, String text) {
      final hasIcon = icon.trim().isNotEmpty;
      return SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasIcon) ...[
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
                        key: includeTestKeys
                            ? ValueKey<String>('hero_details_icon_$icon')
                            : null,
                        style: titleStyle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
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
        key: includeTestKeys
            ? const ValueKey('hero_details_sun_content')
            : null,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: compact ? 0 : 2),
          _ScaleDownRichText(
            span: TextSpan(text: rise, style: rowStyle),
            textKey: includeTestKeys
                ? const ValueKey('hero_sunrise_row')
                : null,
            alignment: Alignment.center,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: compact ? 0 : 1),
          _ScaleDownRichText(
            span: TextSpan(text: set, style: rowStyle),
            textKey: includeTestKeys ? const ValueKey('hero_sunset_row') : null,
            alignment: Alignment.center,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    Widget windContent() {
      // Wind/gust are not unit conversions; they are two related readings.
      // Use iconography to differentiate the two lines without extra labels.
      final useImperial =
          (primaryPlace?.unitSystem.toLowerCase() ?? 'metric') == 'imperial';

      InlineSpan measureSpan(double? kmh) {
        final row = _windMeasureRow(kmh, useImperial: useImperial);
        final secondaryStyle = rowStyle.copyWith(
          fontSize: (rowStyle.fontSize ?? 14) * (compact ? 0.72 : 0.78),
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withAlpha(170),
        );
        return TextSpan(
          children: [
            TextSpan(text: row.primary, style: rowStyle),
            if (row.secondary != null)
              TextSpan(text: ' • ${row.secondary}', style: secondaryStyle),
          ],
        );
      }

      Widget windLine({
        required String icon,
        required double? kmh,
        required Key? textKey,
      }) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                child: Text(icon, textAlign: TextAlign.center, style: rowStyle),
              ),
              const SizedBox(width: 6),
              RichText(
                key: textKey,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                text: measureSpan(kmh),
              ),
            ],
          ),
        );
      }

      return Column(
        key: includeTestKeys
            ? const ValueKey('hero_details_wind_content')
            : null,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: compact ? 0 : 2),
          windLine(
            icon: '🌬',
            kmh: primaryWeather?.windKmh,
            textKey: includeTestKeys ? const ValueKey('hero_wind_row') : null,
          ),
          SizedBox(height: compact ? 0 : 1),
          windLine(
            icon: '💨',
            kmh: primaryWeather?.gustKmh,
            textKey: includeTestKeys ? const ValueKey('hero_gust_row') : null,
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
            key: includeTestKeys ? const ValueKey('hero_sun_pill') : null,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Contract: title row is text-only; emoji/iconography lives
                    // on the data rows so the hierarchy reads cleanly.
                    titleRow(
                      '',
                      DashboardCopy.heroDetailsTitle(context, isWind: isWind),
                    ),
                    SizedBox(height: compact ? 2 : 3),
                    if (isWind) windContent() else sunContent(),
                  ],
                );

                return Align(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
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

// --- Small shared helpers ---

String _flagEmojiFromIso2(String? iso2) {
  final code = (iso2 ?? '').trim().toUpperCase();
  if (code.length != 2) return '🏳️';
  final a = code.codeUnitAt(0);
  final b = code.codeUnitAt(1);
  if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
  // Regional indicator symbols start at 0x1F1E6 ('A').
  final first = 0x1F1E6 + (a - 65);
  final second = 0x1F1E6 + (b - 65);
  return String.fromCharCode(first) + String.fromCharCode(second);
}

String _formatTemp(Place place, WeatherSnapshot weather) {
  final c = weather.temperatureC.round();
  final useImperial = place.unitSystem.toLowerCase() == 'imperial';
  if (useImperial) {
    final f = (c * 9 / 5 + 32).round();
    return '$f°F';
  }
  return '$c°C';
}

String _formatAltTemp(Place place, WeatherSnapshot weather) {
  final c = weather.temperatureC.round();
  final useImperial = place.unitSystem.toLowerCase() == 'imperial';
  if (useImperial) {
    return '$c°C';
  }
  final f = (c * 9 / 5 + 32).round();
  return '$f°F';
}

@immutable
class _WindMeasureRow {
  final String primary;
  final String? secondary;
  const _WindMeasureRow({required this.primary, required this.secondary});
}

String _fmtOneDecimal(double value) {
  final rounded = value.toStringAsFixed(1);
  if (rounded.endsWith('.0')) {
    return rounded.substring(0, rounded.length - 2);
  }
  return rounded;
}

_WindMeasureRow _windMeasureRow(double? kmh, {required bool useImperial}) {
  if (kmh == null) {
    return const _WindMeasureRow(primary: '—', secondary: null);
  }

  final mph = kmh * 0.621371;
  if (useImperial) {
    final primary = '${mph.round()} mph';
    final secondary = '${_fmtOneDecimal(kmh)} km/h';
    return _WindMeasureRow(primary: primary, secondary: secondary);
  }

  final primary = '${kmh.round()} km/h';
  final secondary = '${_fmtOneDecimal(mph)} mph';
  return _WindMeasureRow(primary: primary, secondary: secondary);
}

String _currencyCodeForPlace(Place? place) {
  return currencyCodeForCountryCode(place?.countryCode);
}

String _currencySymbol(String code) {
  final normalized = code.trim().toUpperCase();
  return kCurrencySymbols[normalized] ?? normalized;
}

bool _currencyUsesSuffixSymbol(String code) {
  switch (code.trim().toUpperCase()) {
    case 'AED':
    case 'BHD':
    case 'DZD':
    case 'IQD':
    case 'IRR':
    case 'JOD':
    case 'KWD':
    case 'MAD':
    case 'OMR':
    case 'QAR':
    case 'SAR':
    case 'TND':
      return true;
    default:
      return false;
  }
}

String _formattedCurrencyToken(String code, double amount) {
  final symbol = _currencySymbol(code);
  final digits = _fmtCurrencyAmount(amount);
  final token = _currencyUsesSuffixSymbol(code)
      ? '$digits$symbol'
      : '$symbol$digits';
  // Isolate each token to avoid mixed RTL/LTR reordering artifacts.
  return '\u2066$token\u2069';
}

(String, String) _currencyLines({
  required BuildContext context,
  required Place? primary,
  required Place? secondary,
  required double? pairRate,
}) {
  final from = _currencyCodeForPlace(primary);
  final to = _currencyCodeForPlace(secondary);

  if (from.toUpperCase() == to.toUpperCase()) {
    return (
      '${_formattedCurrencyToken(from, 1)}≈${_formattedCurrencyToken(from, 1)}',
      DashboardCopy.heroCurrencyRateSameCurrency(context),
    );
  }

  if (pairRate == null || pairRate <= 0) {
    final left = _formattedCurrencyToken(from, 1);
    final right = '\u2066${_currencySymbol(to)}—\u2069';
    return ('$left≈$right', DashboardCopy.heroCurrencyRateUnavailable(context));
  }

  final base = _displayBaseAmountForPair(pairRate);
  final converted = base * pairRate;
  final left = _formattedCurrencyToken(from, base);
  final right = _formattedCurrencyToken(to, converted);
  final leftRate = _formattedCurrencyToken(from, 1);
  final rightRate = _formattedCurrencyToken(to, pairRate);

  return (
    '$left≈$right',
    DashboardCopy.heroCurrencyRatePair(
      context,
      leftRate: leftRate,
      rightRate: rightRate,
    ),
  );
}

double _displayBaseAmountForPair(double pairRate) {
  if (pairRate < 0.0002) return 10000;
  if (pairRate < 0.002) return 1000;
  if (pairRate < 0.02) return 100;
  if (pairRate < 0.2) return 10;
  return 1;
}

String _fmtCurrencyAmount(double value) {
  if (value >= 100) return value.toStringAsFixed(0);
  if (value >= 10) return value.toStringAsFixed(1);
  if (value >= 1) return value.toStringAsFixed(2);
  if (value >= 0.1) return value.toStringAsFixed(2);
  return value.toStringAsFixed(3);
}
