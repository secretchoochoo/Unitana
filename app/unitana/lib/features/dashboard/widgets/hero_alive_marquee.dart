import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/dashboard_live_data.dart';

/// Paint-only, travel-neutral pixel scene that gently animates in runtime.
///
/// Test safety: when running under widget tests, the animation controller is
/// created but never started, so pumpAndSettle can complete.
class HeroAliveMarquee extends StatefulWidget {
  final bool compact;
  final bool isNight;
  final SceneKey? sceneKey;

  /// Optional explicit label to render at the bottom of the marquee.
  ///
  /// When null, the marquee uses a coarse label for [sceneKey].
  final String? conditionLabel;

  /// When false, the painter will not render an inline condition label.
  ///
  /// This is used when the marquee slot provides its own widget-layer label
  /// to guarantee readability without duplication.
  final bool renderConditionLabel;

  const HeroAliveMarquee({
    super.key,
    required this.compact,
    required this.isNight,
    this.sceneKey,
    this.conditionLabel,
    this.renderConditionLabel = true,
  });

  @override
  State<HeroAliveMarquee> createState() => _HeroAliveMarqueeState();
}

class _HeroAliveMarqueeState extends State<HeroAliveMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isTest {
    // bool.fromEnvironment is not reliably set by flutter test across all runners.
    // Use a binding type-name check as a deterministic fallback.
    if (bool.fromEnvironment('FLUTTER_TEST')) return true;
    final binding = WidgetsBinding.instance;
    return binding.runtimeType.toString().contains('TestWidgetsFlutterBinding');
  }

  void _syncAnimation() {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final tickerEnabled = TickerMode.of(context);
    final shouldAnimate = !_isTest && !disableAnimations && tickerEnabled;

    if (shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant HeroAliveMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use repaint to avoid widget rebuilds per frame (cheap, semantics-safe).
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final tickerEnabled = TickerMode.of(context);
    final shouldAnimate = !_isTest && !disableAnimations && tickerEnabled;

    final Animation<double> repaint = shouldAnimate
        ? _controller
        : const AlwaysStoppedAnimation<double>(0.0);

    final radius = widget.compact ? 14.0 : 16.0;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          key: const ValueKey('hero_alive_paint'),
          painter: _AliveScenePainter(
            repaint: repaint,
            compact: widget.compact,
            isNight: widget.isNight,
            sceneKey: widget.sceneKey,
            conditionLabel: widget.conditionLabel,
            renderConditionLabel: widget.renderConditionLabel,
          ),
          // Ensure the painter expands to fill the marquee slot.
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AliveScenePainter extends CustomPainter {
  final Animation<double> repaint;
  final bool compact;
  final bool isNight;
  final SceneKey? sceneKey;
  final String? conditionLabel;

  /// When false, the painter will not render an inline condition label.
  ///
  /// This is used when the marquee slot provides its own widget-layer label
  /// to guarantee readability without duplication.
  final bool renderConditionLabel;

  _AliveScenePainter({
    required this.repaint,
    required this.compact,
    required this.isNight,
    required this.sceneKey,
    required this.conditionLabel,
    required this.renderConditionLabel,
  }) : super(repaint: repaint);

  // Palette: Dracula-adjacent, tuned for legibility on small devices.
  static final Paint _sky = Paint()..color = const Color(0xFF403B63);
  static final Paint _sky2 = Paint()..color = const Color(0xFF35304F);

  // Day palette: brighter sky while staying in the Dracula family.
  static final Paint _daySky = Paint()..color = const Color(0xFF6B63B3);
  static final Paint _daySky2 = Paint()..color = const Color(0xFF524A8E);

  static final Paint _clearSky = Paint()..color = const Color(0xFF4A4380);
  static final Paint _clearSky2 = Paint()..color = const Color(0xFF3B3562);

  static final Paint _dayClearSky = Paint()..color = const Color(0xFF7A72D1);
  static final Paint _dayClearSky2 = Paint()..color = const Color(0xFF5C54A8);

  static final Paint _stormSky = Paint()..color = const Color(0xFF2A263F);
  static final Paint _stormSky2 = Paint()..color = const Color(0xFF242033);

  static final Paint _dayStormSky = Paint()..color = const Color(0xFF3B3562);
  static final Paint _dayStormSky2 = Paint()..color = const Color(0xFF2F2A4A);

  static final Paint _mountain1 = Paint()..color = const Color(0xFF6C6A84);
  static final Paint _mountain2 = Paint()..color = const Color(0xFF5E5B76);

  static final Paint _dayMountain1 = Paint()..color = const Color(0xFF8F8DB0);
  static final Paint _dayMountain2 = Paint()..color = const Color(0xFF7A769C);

  static final Paint _water = Paint()..color = const Color(0xFF2F5B6A);
  static final Paint _water2 = Paint()..color = const Color(0xFF2A515E);

  static final Paint _dayWater = Paint()..color = const Color(0xFF3D7A8C);
  static final Paint _dayWater2 = Paint()..color = const Color(0xFF356C7C);

  static final Paint _wave = Paint()..color = const Color(0xFF2A515E);
  static final Paint _wave2 = Paint()..color = const Color(0xFF3A6C7C);

  static final Paint _sparkle = Paint()..color = const Color(0xFFB9B7C9);

  static final Paint _cloud = Paint()..color = const Color(0xFF8A86A6);
  static final Paint _wind = Paint()..color = const Color(0xFFB9B7C9);
  static final Paint _tornado = Paint()..color = const Color(0xFF1B1827);
  static final Paint _tornadoDebris = Paint()
    ..color = const Color(0xFF1B1827).withAlpha(200);

  static final Paint _rain = Paint()..color = const Color(0xFF9AA1B5);
  static final Paint _snow = Paint()..color = const Color(0xFFD7D7E6);
  static final Paint _lightning = Paint()..color = const Color(0xFFF2EFA1);

  static final Paint _sun = Paint()..color = const Color(0xFFD7CF6A);
  static final Paint _moon = Paint()..color = const Color(0xFFCFCBE3);

  static final Paint _fog = Paint()..color = const Color(0xFF2C2A44);
  static final Paint _fogSoft = Paint()..color = const Color(0xFF2C2A44);
  static final Paint _fogStrong = Paint()
    ..color = const Color(0xFF2C2A44).withAlpha(220);
  // Visibility-family accents (keep subtle; readability first).
  static final Paint _hazeTint = Paint()..color = const Color(0x336B5A3C);
  static final Paint _hazeSpeck = Paint()..color = const Color(0x55D7CF6A);
  // Particulate-family accents (dust/sand/ash), kept subtle but distinct.
  static final Paint _dustTint = Paint()..color = const Color(0x3348362A);
  static final Paint _sandTint = Paint()..color = const Color(0x333C311B);
  static final Paint _ashTint = Paint()..color = const Color(0x3325252F);

  static final Paint _dustSpeck = Paint()..color = const Color(0x66B9A58C);
  static final Paint _sandSpeck = Paint()..color = const Color(0x66F2EFA1);
  static final Paint _ashFlake = Paint()..color = const Color(0x88B9B7C9);
  static final Paint _labelBg = Paint()..color = const Color(0xB0000000);
  static final Paint _labelBorder = Paint()
    ..color = const Color(0x80FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static const double _labelFontCompact = 9.0;
  static const double _labelFontRegular = 10.0;

  static String _labelFor(SceneKey kind) {
    switch (kind) {
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
        return 'Thundersnow';
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
    }
  }

  static void _pixel(Canvas canvas, int x, int y, double px, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(x * px, y * px, px, px), paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint skyTop = isNight ? _sky : _daySky;
    final Paint skyBottomPaint = isNight ? _sky2 : _daySky2;

    final Paint clearTop = isNight ? _clearSky : _dayClearSky;
    final Paint clearBottomPaint = isNight ? _clearSky2 : _dayClearSky2;

    final Paint stormTop = isNight ? _stormSky : _dayStormSky;
    final Paint stormBottomPaint = isNight ? _stormSky2 : _dayStormSky2;

    final Paint mountain1 = isNight ? _mountain1 : _dayMountain1;
    final Paint mountain2 = isNight ? _mountain2 : _dayMountain2;

    final Paint water1 = isNight ? _water : _dayWater;
    final Paint water2 = isNight ? _water2 : _dayWater2;

    // Treat the canvas like a small pixel grid.
    final px = compact ? 3.0 : 3.5;
    final w = (size.width / px).floor().clamp(1, 2000);
    final h = (size.height / px).floor().clamp(1, 2000);

    final rect = Offset.zero & size;
    final kind = sceneKey ?? SceneKey.partlyCloudy;

    final bool isClear = kind == SceneKey.clear;
    final bool isPartly = kind == SceneKey.partlyCloudy;
    final bool isCloudy = kind == SceneKey.cloudy;
    final bool isOvercast = kind == SceneKey.overcast;

    final bool isDrizzle =
        kind == SceneKey.drizzle || kind == SceneKey.freezingDrizzle;
    final bool isRain =
        kind == SceneKey.rainLight ||
        kind == SceneKey.rainModerate ||
        kind == SceneKey.rainHeavy ||
        kind == SceneKey.freezingRain;
    final bool isStorm =
        kind == SceneKey.thunderRain ||
        kind == SceneKey.thunderSnow ||
        kind == SceneKey.squall;

    final bool isSnow =
        kind == SceneKey.snowLight ||
        kind == SceneKey.snowModerate ||
        kind == SceneKey.snowHeavy ||
        kind == SceneKey.blowingSnow ||
        kind == SceneKey.blizzard ||
        kind == SceneKey.thunderSnow;
    final bool isSleet = kind == SceneKey.sleet;
    final bool isHail = kind == SceneKey.icePellets;

    final bool isFoggy =
        kind == SceneKey.fog ||
        kind == SceneKey.mist ||
        kind == SceneKey.hazeDust ||
        kind == SceneKey.smokeWildfire ||
        kind == SceneKey.ashfall;

    final bool isWindy =
        kind == SceneKey.windy ||
        kind == SceneKey.squall ||
        kind == SceneKey.tornado;

    final phase = repaint.value; // 0..1 repeating
    final shift = (phase * 8).floor();

    // Background bands (scene tuned, still Dracula adjacent).
    final Paint skyA;
    final Paint skyB;
    switch (kind) {
      case SceneKey.clear:
        skyA = clearTop;
        skyB = clearBottomPaint;
        break;
      case SceneKey.partlyCloudy:
        skyA = skyTop;
        skyB = clearBottomPaint;
        break;
      case SceneKey.cloudy:
        skyA = skyBottomPaint;
        skyB = skyTop;
        break;
      case SceneKey.overcast:
      case SceneKey.drizzle:
      case SceneKey.freezingDrizzle:
      case SceneKey.rainLight:
      case SceneKey.rainModerate:
      case SceneKey.rainHeavy:
      case SceneKey.freezingRain:
      case SceneKey.sleet:
        skyA = stormTop;
        skyB = stormBottomPaint;
        break;
      case SceneKey.thunderRain:
      case SceneKey.thunderSnow:
      case SceneKey.squall:
      case SceneKey.tornado:
        skyA = stormBottomPaint;
        skyB = stormTop;
        break;
      case SceneKey.snowLight:
      case SceneKey.snowModerate:
      case SceneKey.snowHeavy:
      case SceneKey.blowingSnow:
      case SceneKey.blizzard:
      case SceneKey.icePellets:
        skyA = skyBottomPaint;
        skyB = clearBottomPaint;
        break;
      case SceneKey.fog:
      case SceneKey.mist:
      case SceneKey.hazeDust:
      case SceneKey.smokeWildfire:
      case SceneKey.ashfall:
        skyA = skyBottomPaint;
        skyB = skyBottomPaint;
        break;
      case SceneKey.windy:
        skyA = skyTop;
        skyB = clearBottomPaint;
        break;
    }

    canvas.drawRect(rect, skyB);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.55), skyA);

    // Subtle horizon fog (stronger for true fog).
    final Paint horizonFog;
    switch (kind) {
      case SceneKey.fog:
        horizonFog = _fogStrong;
        break;
      case SceneKey.mist:
        horizonFog = Paint()..color = _fogSoft.color.withAlpha(170);
        break;
      case SceneKey.hazeDust:
        horizonFog = Paint()..color = _fogSoft.color.withAlpha(130);
        break;
      default:
        horizonFog = _fogSoft;
    }
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.48, size.width, size.height * 0.08),
      horizonFog,
    );

    // A tiny sun or moon so "clear" reads instantly.
    if (isClear || isPartly) {
      final cx = (w * 0.78).round();
      final cy = (h * 0.14).round();
      final r = compact ? 5 : 6;
      for (int y = -r; y <= r; y++) {
        for (int x = -r; x <= r; x++) {
          if (x * x + y * y <= r * r) {
            _pixel(canvas, cx + x, cy + y, px, isNight ? _moon : _sun);
          }
        }
      }
    } else if (isFoggy) {
      final cx = (w * 0.80).round();
      final cy = (h * 0.16).round();
      final r = compact ? 5 : 6;
      for (int y = -r; y <= r; y++) {
        for (int x = -r; x <= r; x++) {
          if (x * x + y * y <= r * r && (x + y).isEven) {
            _pixel(canvas, cx + x, cy + y, px, isNight ? _moon : _sun);
          }
        }
      }
    }

    // Helper: simple stacked pixel cloud.
    void cloud(int x, int y, int span, {int thickness = 2}) {
      final t = thickness.clamp(1, 3);
      canvas.drawRect(Rect.fromLTWH(x * px, y * px, span * px, t * px), _cloud);
      canvas.drawRect(
        Rect.fromLTWH((x + 1) * px, (y - 1) * px, (span - 2) * px, t * px),
        _cloud,
      );
      canvas.drawRect(
        Rect.fromLTWH((x + 3) * px, (y - 2) * px, (span - 6) * px, t * px),
        _cloud,
      );
    }

    // Cloud silhouettes (density depends on condition family).
    if (!isClear && !isFoggy) {
      final int thickness =
          (isOvercast ||
              isStorm ||
              isRain ||
              isDrizzle ||
              isSnow ||
              isSleet ||
              isHail)
          ? 3
          : (isCloudy ? 3 : 2);

      if (isPartly) {
        cloud(
          (w * 0.50).round(),
          (h * 0.14).round(),
          (w * 0.34).round(),
          thickness: 2,
        );
      } else {
        cloud(
          (w * 0.08).round(),
          (h * 0.16).round(),
          (w * 0.34).round(),
          thickness: thickness,
        );
        cloud(
          (w * 0.50).round(),
          (h * 0.12).round(),
          (w * 0.30).round(),
          thickness: thickness,
        );

        if (isOvercast ||
            isStorm ||
            isRain ||
            isDrizzle ||
            isSnow ||
            isSleet ||
            isHail ||
            isWindy) {
          cloud(
            (w * 0.22).round(),
            (h * 0.06).round(),
            (w * 0.48).round(),
            thickness: thickness,
          );
        }
      }
    }
    // Wind cues (kept paint-only and small-phone legible).
    if (isWindy) {
      void gust({
        required int x,
        required int y,
        required int len,
        int thickness = 1,
        int curl = 2,
      }) {
        // Main stroke.
        for (int t = 0; t < thickness; t++) {
          canvas.drawRect(
            Rect.fromLTWH(x * px, (y + t) * px, len * px, px),
            _wind,
          );
        }

        // Trailing offset stroke (gives a sense of flow without busy detail).
        canvas.drawRect(
          Rect.fromLTWH((x + 3) * px, (y + thickness) * px, (len - 5) * px, px),
          _wind,
        );

        // Small curl at the end.
        for (int i = 0; i < curl; i++) {
          _pixel(canvas, x + len + i, y - i, px, _wind);
        }
      }

      final shiftX = (phase * 10).floor();

      if (kind == SceneKey.windy) {
        // Windy: clean gust lines, airy spacing.
        for (int i = 0; i < 4; i++) {
          final y = (h * (0.14 + i * 0.10)).round();
          final x = ((w * 0.10).round() + shiftX + i * 9) % (w + 20) - 10;
          gust(x: x, y: y, len: 14, thickness: 1, curl: 2);
        }
      } else if (kind == SceneKey.squall) {
        // Squall: thicker, lower gusts (reads more forceful than plain Windy).
        for (int i = 0; i < 6; i++) {
          final y = (h * (0.18 + i * 0.08)).round();
          final x = ((w * 0.06).round() + shiftX * 2 + i * 11) % (w + 28) - 14;
          gust(x: x, y: y, len: 18, thickness: 2, curl: 3);
        }
      } else if (kind == SceneKey.tornado) {
        // Tornado: unmistakable funnel over the horizon.
        final fx = (w * 0.72).round();
        final topY = (h * 0.20).round();
        final baseY = (h * 0.58).round(); // just above the water
        final steps = (baseY - topY).clamp(8, 70);

        for (int i = 0; i < steps; i++) {
          final t = i / steps;
          final width = (14 - (t * 10)).round().clamp(3, 14);
          final y = topY + i;
          final x0 = fx - (width ~/ 2);

          canvas.drawRect(
            Rect.fromLTWH(x0 * px, y * px, width * px, px),
            _tornado,
          );

          // Small jagged pixels keep it alive without heavy animation.
          if (((i + shift) % 7) == 0) {
            _pixel(canvas, x0 - 1, y, px, _tornadoDebris);
          }
        }

        // Debris specks near the base.
        final debrisY = baseY + 2;
        for (int i = 0; i < 24; i++) {
          final dx = ((i * 7 + shift * 5) % 17) - 8;
          final dy = ((i * 11 + shift * 3) % 5) - 2;
          _pixel(canvas, fx + dx, debrisY + dy, px, _tornadoDebris);
        }
      }
    }

    // Mountains (two simple silhouettes).
    void mountain(int baseY, int peakX, int peakY, int width, Paint paint) {
      final path = Path()
        ..moveTo(0, baseY * px)
        ..lineTo(peakX * px, peakY * px)
        ..lineTo((peakX + width) * px, baseY * px)
        ..lineTo(w * px, baseY * px)
        ..lineTo(w * px, h * px)
        ..lineTo(0, h * px)
        ..close();
      canvas.drawPath(path, paint);
    }

    mountain(
      (h * 0.56).round(),
      (w * 0.28).round(),
      (h * 0.36).round(),
      (w * 0.18).round(),
      mountain2,
    );
    mountain(
      (h * 0.58).round(),
      (w * 0.62).round(),
      (h * 0.34).round(),
      (w * 0.22).round(),
      mountain1,
    );

    // Water base.
    final waterTop = (h * 0.62).round().clamp(0, h);
    canvas.drawRect(
      Rect.fromLTWH(0, waterTop * px, size.width, size.height),
      water1,
    );
    // A darker strip near the horizon adds depth and uses water2.
    canvas.drawRect(
      Rect.fromLTWH(0, (waterTop + 1) * px, size.width, px * 2),
      water2,
    );

    // Animated wave dither (sparkles only in fair weather).
    final bool stormy =
        isDrizzle || isRain || isStorm || isSnow || isSleet || isHail;
    final bool sparkleAllowed = isClear || isPartly;

    for (int y = waterTop + 1; y < h - 2; y++) {
      for (int x = 2; x < w - 2; x++) {
        int v = (x * 31 + y * 17 + shift * 5) % 13;

        // Stormy scenes read better with fewer bright pixels.
        if (stormy) v = (v * 3) % 13;

        if (v == 0 && sparkleAllowed) {
          _pixel(canvas, x, y, px, _sparkle);
        } else if (v < 4) {
          _pixel(canvas, x, y, px, _wave2);
        } else if (v < 7) {
          _pixel(canvas, x, y, px, _wave);
        }
      }
    }

    // A tiny "boat" silhouette for fog scenes, so fog does not feel like "overcast".
    if (isFoggy) {
      final boatY = (waterTop + 6).clamp(0, h - 2);
      final boatX = ((w * 0.20) + math.sin(phase * math.pi * 2) * 3)
          .round()
          .clamp(2, w - 6);
      final boatPaint = _fogSoft;
      canvas.drawRect(
        Rect.fromLTWH(boatX * px, boatY * px, px * 4, px),
        boatPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH((boatX + 1) * px, (boatY - 1) * px, px * 2, px),
        boatPaint,
      );
    }

    // Scene overlays: rain / snow / fog stay in the top half.
    final skyBottom = math.max(0, waterTop - 1);

    if (skyBottom > 0) {
      if (isDrizzle || isRain || isStorm) {
        // Rain family distinctness:
        // - Drizzle: sparse, short, mostly vertical.
        // - Rain: medium density, diagonal streaks.
        // - Squall/Thunderstorm: dense, longer, more wind-driven.
        final bool isSquall = kind == SceneKey.squall;
        final bool isThunder =
            kind == SceneKey.thunderRain || kind == SceneKey.thunderSnow;
        final bool isHeavy = isStorm || isSquall;

        final int dropSpacing = isDrizzle ? 9 : (isHeavy ? 4 : 6);
        final int dropLen = isDrizzle ? 2 : (isHeavy ? 6 : 4);
        final int dxPerStep = isDrizzle ? 0 : (isHeavy ? 2 : 1);
        final int thickness = isHeavy ? 2 : 1;
        final int alpha = isDrizzle ? 170 : (isHeavy ? 235 : 210);
        final rainPaint = Paint()..color = _rain.color.withAlpha(alpha);

        for (int y = 2; y < skyBottom; y++) {
          for (int x = 0; x < w; x++) {
            final v = (x * 13 + y * 29 + (shift * 11)) % dropSpacing;
            if (v == 0) {
              // Slight variation keeps the scene from looking like a grid.
              if (isDrizzle && ((x + y + shift) % 7 == 0)) continue;

              final extra = (isHeavy && ((x + shift) % 23 == 0)) ? 2 : 0;
              final len = dropLen + extra;

              for (int i = 0; i < len; i++) {
                final pxX = x + (dxPerStep * i);
                final pxY = y + i;
                for (int t = 0; t < thickness; t++) {
                  _pixel(canvas, pxX + t, pxY, px, rainPaint);
                }
              }
            }
          }
        }

        // Lightning only for true thunderstorms.
        if (isThunder) {
          final boltX = ((w * 0.55).round() + (shift % 8) - 4).clamp(2, w - 3);
          final boltY = (h * 0.06).round();
          for (int i = 0; i < 10; i++) {
            _pixel(
              canvas,
              boltX + (i.isEven ? 0 : 1),
              boltY + i,
              px,
              _lightning,
            );
          }
        }
      } else if (isSnow || isSleet || isHail) {
        // Snow family. Sleet mixes flakes with a few rain streaks.
        // Hail uses chunkier pellets.
        final int flakeSpacing = isHail ? 7 : 5;
        final int flakeSize = isHail ? 2 : 1;

        for (int y = 2; y < skyBottom; y++) {
          for (int x = 0; x < w; x++) {
            final v = (x * 17 + y * 19 + (shift * 7)) % flakeSpacing;
            if (v == 0) {
              _pixel(canvas, x, y, px, _snow);
              if (flakeSize == 2) {
                _pixel(canvas, x + 1, y, px, _snow);
                _pixel(canvas, x, y + 1, px, _snow);
              }
            }
          }
        }

        if (isSleet) {
          for (int y = 2; y < skyBottom; y++) {
            for (int x = 0; x < w; x++) {
              final v = (x * 11 + y * 23 + (shift * 9)) % 11;
              if (v == 0) {
                _pixel(canvas, x, y, px, _rain);
                _pixel(canvas, x + 1, y + 1, px, _rain);
                _pixel(canvas, x + 2, y + 2, px, _rain);
              }
            }
          }
        }
      } else if (isFoggy) {
        // Visibility family: make fog/mist/haze read differently at a glance.
        //
        // - Fog: thick, full-height bands; higher opacity.
        // - Mist: lower-half wisps; lighter opacity; more gaps.
        // - Haze: warm tint + sparse speckle; minimal banding.
        //
        // Smoke gets its own signature (plumes) so it never reads as generic fog.
        // Dust/sand/ash remain as a mid-strength banding baseline for now.

        if (kind == SceneKey.smokeWildfire) {
          // Smoke / wildfire signature:
          // - Blocky skyline near the horizon
          // - Two plumes that rise and curl (two-frame wobble)
          // - Light ambient veil so it still feels like reduced visibility

          final skylineY = (skyBottom - 1).clamp(6, skyBottom);
          final skylinePaint = Paint()..color = const Color(0xFF1B1830);
          final windowPaint = Paint()..color = const Color(0x44D7CF6A);
          final plumeBaseY = (skylineY - 1).clamp(0, skyBottom);
          final bool alt = (shift % 2) == 0;

          // Skyline blocks.
          final buildings = <({int x, int w, int h})>[
            (x: (w * 0.06).round(), w: (w * 0.10).round(), h: 6),
            (x: (w * 0.18).round(), w: (w * 0.08).round(), h: 4),
            (x: (w * 0.30).round(), w: (w * 0.12).round(), h: 7),
            (x: (w * 0.46).round(), w: (w * 0.09).round(), h: 5),
            (x: (w * 0.60).round(), w: (w * 0.14).round(), h: 8),
            (x: (w * 0.78).round(), w: (w * 0.10).round(), h: 5),
          ];
          for (final b in buildings) {
            final bx = b.x.clamp(0, w);
            final bw = b.w.clamp(2, w);
            final bh = b.h.clamp(3, skylineY);
            canvas.drawRect(
              Rect.fromLTWH(bx * px, (skylineY - bh) * px, bw * px, bh * px),
              skylinePaint,
            );

            // A couple of “window” pixels to keep it alive without noise.
            for (int wy = skylineY - bh + 1; wy < skylineY - 1; wy += 2) {
              for (int wx = bx + 1; wx < bx + bw - 1; wx += 4) {
                final v = (wx * 17 + wy * 29 + shift * 7) % 19;
                if (v == 0) _pixel(canvas, wx, wy, px, windowPaint);
              }
            }
          }

          void plume(int baseX, int baseY, {required bool flip}) {
            final height = compact ? 13 : 15;
            for (int i = 0; i < height; i++) {
              final t = i / (height - 1);
              // Drift and curl as it rises.
              int drift = (t * 3).round();
              drift += flip ? ((i % 3 == 0) ? 1 : 0) : ((i % 4 == 0) ? -1 : 0);
              final cx = baseX + drift;
              final cy = baseY - i;

              final half = (1 + (t * 4)).round();
              final alpha = (220 - (t * 120)).round().clamp(80, 230);
              final p = Paint()..color = _fogSoft.color.withAlpha(alpha);

              for (int dx = -half; dx <= half; dx++) {
                // Punch tiny holes so it reads as smoke, not a solid stripe.
                if (((dx.abs() + i + shift) % 4) == 0) continue;
                _pixel(canvas, cx + dx, cy, px, p);
                if (t > 0.70 && ((dx + i) % 3 == 0)) {
                  _pixel(canvas, cx + dx, cy - 1, px, p);
                }
              }
            }

            // A small curl cap to sell the two-frame motion.
            final capX = baseX + (flip ? 4 : 2);
            final capY = baseY - height + (flip ? 1 : 0);
            for (int j = 0; j < 4; j++) {
              _pixel(canvas, capX + j, capY + j, px, _fogSoft);
            }
          }

          // Two plumes.
          plume((w * 0.22).round(), plumeBaseY, flip: alt);
          plume((w * 0.58).round(), plumeBaseY, flip: !alt);

          // Ambient veil (very light) so the sky still feels “smoky.”
          final veilAlpha = compact ? 36 : 32;
          final veilPaint = Paint()..color = _fog.color.withAlpha(veilAlpha);
          for (int y = 2; y < skyBottom; y += 3) {
            for (int x = 0; x < w; x++) {
              final v = (x * 23 + y * 11 + shift * 5) % 41;
              if (v == 0) _pixel(canvas, x, y, px, veilPaint);
            }
          }
        } else if (kind == SceneKey.hazeDust) {
          // HAZE_DUST can represent haze, dust, or sand. SceneKey drives the
          // scene selection; the label can refine the particulate signature.
          final labelLower = (conditionLabel ?? _labelFor(kind)).toLowerCase();

          final bool wantsDust = labelLower.contains('dust');
          final bool wantsSand = labelLower.contains('sand');

          if (!wantsDust && !wantsSand) {
            // Haze: warm tint wash + drifting speckle, no heavy stripes.
            canvas.drawRect(
              Rect.fromLTWH(0, 0, size.width, skyBottom * px),
              _hazeTint,
            );
            for (int y = 2; y < skyBottom; y += 2) {
              for (int x = 0; x < w; x++) {
                final v = (x * 19 + y * 7 + (shift * 5)) % 29;
                if (v == 0) {
                  _pixel(canvas, x, y, px, _hazeSpeck);
                }
              }
            }
          } else if (wantsDust) {
            // Dust: warm brown wash + drifting gust streaks + sparse speckle.
            canvas.drawRect(
              Rect.fromLTWH(0, 0, size.width, skyBottom * px),
              _dustTint,
            );

            // Gust streaks (horizontal, mid-sky).
            for (int i = 0; i < 4; i++) {
              final y = (h * (0.18 + i * 0.10)).round();
              final x = ((shift * 3) + i * 9) % (w + 24) - 12;
              final p = Paint()..color = _fogSoft.color.withAlpha(90);
              canvas.drawRect(Rect.fromLTWH(x * px, y * px, 22 * px, px), p);
              canvas.drawRect(
                Rect.fromLTWH((x + 6) * px, (y + 1) * px, 14 * px, px),
                p,
              );
            }

            // Speckle.
            for (int y = 2; y < skyBottom; y += 2) {
              for (int x = 0; x < w; x++) {
                final v = (x * 17 + y * 13 + (shift * 7)) % 31;
                if (v == 0) {
                  _pixel(canvas, x, y, px, _dustSpeck);
                  if (((x + y + shift) % 29) == 0) {
                    _pixel(canvas, x + 1, y, px, _dustSpeck);
                  }
                }
              }
            }
          } else {
            // Sand: golden wash + denser grains + subtle ripple near horizon.
            canvas.drawRect(
              Rect.fromLTWH(0, 0, size.width, skyBottom * px),
              _sandTint,
            );

            // Denser grains.
            for (int y = 2; y < skyBottom; y += 2) {
              for (int x = 0; x < w; x++) {
                final v = (x * 19 + y * 9 + (shift * 9)) % 23;
                if (v == 0) {
                  _pixel(canvas, x, y, px, _sandSpeck);
                  if (((x + y + shift) % 11) == 0) {
                    _pixel(canvas, x, y + 1, px, _sandSpeck);
                  }
                }
              }
            }

            // Dune ripple near the horizon (subtle, single-pixel).
            final rippleY = (skyBottom - 2).clamp(0, skyBottom);
            for (int x = 0; x < w; x++) {
              final dy = (math.sin((x + shift) / 6.0) * 1.2).round();
              final y = (rippleY + dy).clamp(0, skyBottom - 1);
              if (((x + shift) % 3) == 0) {
                _pixel(canvas, x, y, px, _sandSpeck);
              }
            }

            // Occasional sand ribbon (wind-driven diagonal).
            for (int i = 0; i < 2; i++) {
              final baseY = (h * (0.14 + i * 0.12)).round();
              final baseX = ((shift * 5) + i * 17) % (w + 30) - 15;
              final p = Paint()..color = _sandSpeck.color.withAlpha(140);
              for (int j = 0; j < 10; j++) {
                _pixel(canvas, baseX + j, baseY + j, px, p);
                if ((j % 3) == 0) {
                  _pixel(canvas, baseX + j + 1, baseY + j, px, p);
                }
              }
            }
          }
        } else if (kind == SceneKey.ashfall) {
          // Ash: darker flakes falling, slightly diagonal drift.
          canvas.drawRect(
            Rect.fromLTWH(0, 0, size.width, skyBottom * px),
            _ashTint,
          );

          final drift = ((shift % 3) - 1);
          for (int y = 2; y < skyBottom; y++) {
            for (int x = 0; x < w; x++) {
              final v = (x * 23 + y * 31 + (shift * 5)) % 37;
              if (v == 0) {
                _pixel(canvas, x + drift, y, px, _ashFlake);
                if (((x + y + shift) % 17) == 0) {
                  _pixel(canvas, x + drift + 1, y + 1, px, _ashFlake);
                }
              }
            }
          }
        } else {
          final bool isFog = kind == SceneKey.fog;
          final bool isMist = kind == SceneKey.mist;

          final int startY = isMist ? (h * 0.32).round() : (h * 0.12).round();
          final int stepY = isFog ? 2 : (isMist ? 4 : 3);
          final int bandH = isFog ? 3 : 2;

          // Strength by type (kept intentionally conservative).
          double strength;
          switch (kind) {
            case SceneKey.fog:
              strength = 1.0;
              break;
            case SceneKey.mist:
              strength = 0.65;
              break;
            case SceneKey.smokeWildfire:
              strength = 0.75;
              break;
            case SceneKey.hazeDust:
              strength = 0.70;
              break;
            case SceneKey.ashfall:
              strength = 0.80;
              break;
            default:
              strength = 0.72;
          }

          final int fogAlpha = (0.22 * strength * 255).round().clamp(0, 255);
          final fogPaint = Paint()..color = _fog.color.withAlpha(fogAlpha);

          // Bands: for mist, break them into short wisps with gaps.
          for (int y = startY; y < skyBottom; y += stepY) {
            final wobble = ((shift + y) % 9) - 4;

            if (isMist) {
              // Wisps: segmented strips that leave the upper sky readable.
              int x = wobble - 6;
              while (x < w + 6) {
                final seg = 10 + ((x + y + shift) % 6); // 10..15
                final gap = 5 + ((x + shift) % 4); // 5..8
                canvas.drawRect(
                  Rect.fromLTWH(x * px, y * px, seg * px, bandH * px),
                  fogPaint,
                );
                x += seg + gap;
              }
            } else {
              // Fog baseline: full-width band.
              canvas.drawRect(
                Rect.fromLTWH(
                  px * wobble.toDouble(),
                  y * px,
                  size.width,
                  bandH * px,
                ),
                fogPaint,
              );
            }
          }

          // Fog gets a few denser pockets near the horizon to sell thickness.
          if (isFog) {
            final pocketAlpha = (fogAlpha * 0.55).round().clamp(0, 255);
            final pocketPaint = Paint()
              ..color = _fog.color.withAlpha(pocketAlpha);
            final int pocketTop = (h * 0.28).round();
            for (int y = pocketTop; y < skyBottom; y++) {
              for (int x = 0; x < w; x++) {
                final v = (x * 23 + y * 31 + (shift * 11)) % 37;
                if (v == 0) {
                  _pixel(canvas, x, y, px, pocketPaint);
                }
              }
            }
          }
        }
      }
    }

    // Tiny condition label at the bottom for explicit readability.
    _paintConditionLabel(canvas, size, px, kind, conditionLabel);
  }

  void _paintConditionLabel(
    Canvas canvas,
    Size size,
    double px,
    SceneKey kind,
    String? labelOverride,
  ) {
    // Guard: if the marquee is extremely short, keep the scene uncluttered.
    if (!renderConditionLabel) return;

    if (size.height < 28) return;

    final raw = (labelOverride ?? '').trim();
    final label = raw.isNotEmpty ? raw : _labelFor(kind);
    final fontSize = compact ? _labelFontCompact : _labelFontRegular;

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xAA000000);

    final tpOutline = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.0,
          foreground: outlinePaint,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.width - 10);

    final tpFill = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.0,
          color: const Color(0xF2FFFFFF),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.width - 10);

    double snap(double v) => (v / px).roundToDouble() * px;

    final double padX = compact ? 4.0 : 5.0;
    final double padY = compact ? 2.0 : 3.0;

    final bgWidth = tpFill.width + padX * 2;
    final bgHeight = tpFill.height + padY * 2;

    // Keep the label chip fully inside the canvas so the border never clips.
    final double bgX = snap(
      (size.width - bgWidth) / 2,
    ).clamp(1.0, math.max(1.0, size.width - bgWidth - 1.0));
    final double bgY = snap(
      size.height - bgHeight - (compact ? 2.0 : 3.0),
    ).clamp(1.0, math.max(1.0, size.height - bgHeight - 1.0));

    final bgRect = Rect.fromLTWH(bgX, bgY, bgWidth, bgHeight);

    final radius = Radius.circular(compact ? 4.0 : 5.0);
    final rrect = RRect.fromRectAndRadius(bgRect, radius);

    canvas.drawRRect(rrect, _labelBg);
    canvas.drawRRect(rrect, _labelBorder);

    final textOffset = Offset(bgX + padX, bgY + padY);

    // Outline then fill reads against any scene background.
    tpOutline.paint(canvas, textOffset);
    tpFill.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant _AliveScenePainter oldDelegate) {
    return oldDelegate.compact != compact ||
        oldDelegate.sceneKey != sceneKey ||
        oldDelegate.conditionLabel != conditionLabel ||
        oldDelegate.renderConditionLabel != renderConditionLabel ||
        oldDelegate.repaint != repaint;
  }
}
