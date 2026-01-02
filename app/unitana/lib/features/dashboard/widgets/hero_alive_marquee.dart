import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paint-only, travel-neutral pixel scene that gently animates in runtime.
///
/// Test safety: when running under widget tests, the animation controller is
/// created but never started, so pumpAndSettle can complete.
class HeroAliveMarquee extends StatefulWidget {
  final bool compact;

  const HeroAliveMarquee({super.key, required this.compact});

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

  _AliveScenePainter({required this.repaint, required this.compact})
    : super(repaint: repaint);

  static final Paint _sky = Paint()..color = const Color(0xFF403B63);
  static final Paint _sky2 = Paint()..color = const Color(0xFF35304F);
  static final Paint _mountain1 = Paint()..color = const Color(0xFF6C6A84);
  static final Paint _mountain2 = Paint()..color = const Color(0xFF5E5B76);
  static final Paint _water = Paint()..color = const Color(0xFF2F5B6A);
  static final Paint _water2 = Paint()..color = const Color(0xFF2A515E);
  static final Paint _sparkle = Paint()..color = const Color(0xFFB9B7C9);
  static final Paint _fog = Paint()..color = const Color(0xFF2C2A44);

  @override
  void paint(Canvas canvas, Size size) {
    // Treat the canvas like a small pixel grid.
    final px = compact ? 3.0 : 3.5;
    final w = (size.width / px).floor().clamp(1, 2000);
    final h = (size.height / px).floor().clamp(1, 2000);

    final rect = Offset.zero & size;

    // Background bands.
    canvas.drawRect(rect, _sky2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.55), _sky);

    // Subtle fog at horizon.
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.48, size.width, size.height * 0.08),
      _fog,
    );

    // Mountains (two simple silhouettes).
    void mountain(int baseY, int peakX, int peakY, int width, Paint paint) {
      final path = Path();
      path.moveTo(0, baseY * px);
      path.lineTo(peakX * px, peakY * px);
      path.lineTo((peakX + width) * px, baseY * px);
      path.lineTo(w * px, baseY * px);
      path.lineTo(w * px, h * px);
      path.lineTo(0, h * px);
      path.close();
      canvas.drawPath(path, paint);
    }

    mountain(
      (h * 0.56).round(),
      (w * 0.28).round(),
      (h * 0.36).round(),
      (w * 0.18).round(),
      _mountain2,
    );
    mountain(
      (h * 0.58).round(),
      (w * 0.62).round(),
      (h * 0.34).round(),
      (w * 0.22).round(),
      _mountain1,
    );

    // Water base.
    final waterTop = (h * 0.62).round();
    canvas.drawRect(
      Rect.fromLTWH(0, waterTop * px, size.width, size.height),
      _water,
    );

    // Animated wave/sparkle dither.
    final phase = repaint.value;
    final shift = (phase * 8).floor();

    // Draw a sparse sparkle field and wave dots. Keep allocations minimal.
    for (int y = waterTop; y < h; y++) {
      final rowMod = (y + shift) & 3;
      for (int x = 0; x < w; x++) {
        // Small deterministic pattern.
        final v = (x * 31 + y * 17 + shift * 13) & 15;
        if (rowMod == 0 && v == 0) {
          canvas.drawRect(Rect.fromLTWH(x * px, y * px, px, px), _sparkle);
        } else if (rowMod == 2 && v == 1) {
          canvas.drawRect(Rect.fromLTWH(x * px, y * px, px, px), _water2);
        }
      }
    }

    // A tiny "boat" silhouette that drifts a few pixels.
    final boatY = waterTop + 3;
    final boatX = ((w * 0.20) + math.sin(phase * math.pi * 2) * 3).round();
    final boatPaint = _fog;
    canvas.drawRect(
      Rect.fromLTWH(boatX * px, boatY * px, px * 4, px),
      boatPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH((boatX + 1) * px, (boatY - 1) * px, px * 2, px),
      boatPaint,
    );

    // Stars, very subtle.
    // (Do not gate on kIsWeb; avoid foundation imports and keep this widget
    // universally compile-safe.)
    final starCount = compact ? 8 : 10;
    for (int i = 0; i < starCount; i++) {
      final sx = ((i * 37 + shift * 11) % (w - 1)).clamp(0, w - 1);
      final sy = ((i * 19 + shift * 7) % (waterTop - 2)).clamp(0, waterTop - 2);
      if (((i + shift) & 3) == 0) {
        canvas.drawRect(Rect.fromLTWH(sx * px, sy * px, px, px), _sparkle);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AliveScenePainter oldDelegate) {
    return oldDelegate.compact != compact || oldDelegate.repaint != repaint;
  }
}
