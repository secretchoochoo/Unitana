import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum TutorialArrowStyle { targetCurve, pullDownBounce, none }

class TutorialStep {
  final String title;
  final String body;
  final GlobalKey? targetKey;
  final Alignment cardAlignment;
  final TutorialArrowStyle arrowStyle;
  final Alignment targetAlignment;
  final bool showSpotlight;
  final bool arrowAboveCard;
  final double arrowScale;
  final Alignment? fallbackScreenTargetAlignment;

  const TutorialStep({
    required this.title,
    required this.body,
    this.targetKey,
    this.cardAlignment = Alignment.bottomCenter,
    this.arrowStyle = TutorialArrowStyle.targetCurve,
    this.targetAlignment = Alignment.center,
    this.showSpotlight = true,
    this.arrowAboveCard = false,
    this.arrowScale = 1.0,
    this.fallbackScreenTargetAlignment,
  });
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _stepIndex = 0;
  final GlobalKey _cardKey = GlobalKey();
  late final AnimationController _arrowController;
  bool _queuedLayoutTick = false;
  final Map<int, Rect> _targetRectCache = <int, Rect>{};

  TutorialStep get _step => widget.steps[_stepIndex];

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _syncArrowAnimation();
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  Rect? _targetRect() {
    final targetKey = _step.targetKey;
    if (targetKey == null) return null;
    final context = targetKey.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) {
      return _targetRectCache[_stepIndex];
    }
    final overlayBox = Overlay.of(this.context).context.findRenderObject();
    if (overlayBox is! RenderBox || !overlayBox.hasSize) {
      return _targetRectCache[_stepIndex];
    }
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final rect = topLeft & box.size;
    _targetRectCache[_stepIndex] = rect;
    return rect;
  }

  Rect? _cardRect() {
    final context = _cardKey.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    final overlayBox = Overlay.of(this.context).context.findRenderObject();
    if (overlayBox is! RenderBox || !overlayBox.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    return topLeft & box.size;
  }

  void _next() {
    if (_stepIndex >= widget.steps.length - 1) {
      widget.onComplete();
      return;
    }
    setState(() => _stepIndex += 1);
    _syncArrowAnimation();
  }

  void _back() {
    if (_stepIndex <= 0) return;
    setState(() => _stepIndex -= 1);
    _syncArrowAnimation();
  }

  void _syncArrowAnimation() {
    final needsBounce = _step.arrowStyle == TutorialArrowStyle.pullDownBounce;
    if (needsBounce) {
      if (!_arrowController.isAnimating) {
        _arrowController.repeat();
      }
      return;
    }
    if (_arrowController.isAnimating) {
      _arrowController.stop();
    }
    if (_arrowController.value != 0) {
      _arrowController.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetRect();
    final cardRect = _cardRect();
    if ((target == null || cardRect == null) && !_queuedLayoutTick) {
      _queuedLayoutTick = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _queuedLayoutTick = false;
        if (!mounted) return;
        setState(() {});
      });
    }
    final cs = Theme.of(context).colorScheme;
    final chalkCard = Color.alphaBlend(
      Colors.black.withAlpha(90),
      cs.surfaceContainerHighest,
    );
    final chalkText = Colors.white.withAlpha(235);

    return IgnorePointer(
      ignoring: false,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SpotlightPainter(
                  targetRect: _step.showSpotlight ? target : null,
                ),
              ),
            ),
            if (_step.arrowStyle != TutorialArrowStyle.none &&
                !_step.arrowAboveCard)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _arrowController,
                    builder: (context, _) => CustomPaint(
                      painter: _ArrowPainter(
                        targetRect: target,
                        cardRect: cardRect,
                        style: _step.arrowStyle,
                        phase: _arrowController.value,
                        targetAlignment: _step.targetAlignment,
                        arrowScale: _step.arrowScale,
                        fallbackScreenTargetAlignment:
                            _step.fallbackScreenTargetAlignment,
                      ),
                    ),
                  ),
                ),
              ),
            Align(
              alignment: _step.cardAlignment,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 96, 16, 28),
                child: _ChalkCard(
                  key: _cardKey,
                  title: _step.title,
                  body: _step.body,
                  textColor: chalkText,
                  background: chalkCard,
                  showBack: _stepIndex > 0,
                  onBack: _back,
                  onNext: _next,
                  onSkip: widget.onSkip,
                  isLast: _stepIndex == widget.steps.length - 1,
                ),
              ),
            ),
            if (_step.arrowStyle != TutorialArrowStyle.none &&
                _step.arrowAboveCard)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _arrowController,
                    builder: (context, _) => CustomPaint(
                      painter: _ArrowPainter(
                        targetRect: target,
                        cardRect: cardRect,
                        style: _step.arrowStyle,
                        phase: _arrowController.value,
                        targetAlignment: _step.targetAlignment,
                        arrowScale: _step.arrowScale,
                        fallbackScreenTargetAlignment:
                            _step.fallbackScreenTargetAlignment,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;

  const _SpotlightPainter({required this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.black.withAlpha(195);
    final fullPath = Path()..addRect(Offset.zero & size);
    final target = targetRect;
    if (target == null) {
      canvas.drawRect(Offset.zero & size, bg);
      return;
    }
    final inset = 10.0;
    final hole = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        math.max(0, target.left - inset),
        math.max(0, target.top - inset),
        math.min(size.width, target.right + inset),
        math.min(size.height, target.bottom + inset),
      ),
      const Radius.circular(14),
    );
    final holePath = Path()..addRRect(hole);
    final overlay = Path.combine(PathOperation.difference, fullPath, holePath);
    canvas.drawPath(overlay, bg);

    final glow = Paint()
      ..color = Colors.white.withAlpha(125)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawRRect(hole, glow);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect;
}

class _ArrowPainter extends CustomPainter {
  final Rect? targetRect;
  final Rect? cardRect;
  final TutorialArrowStyle style;
  final double phase;
  final Alignment targetAlignment;
  final double arrowScale;
  final Alignment? fallbackScreenTargetAlignment;

  const _ArrowPainter({
    required this.targetRect,
    required this.cardRect,
    required this.style,
    required this.phase,
    required this.targetAlignment,
    required this.arrowScale,
    required this.fallbackScreenTargetAlignment,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chalkInk = Colors.white.withAlpha(238);
    final chalkDust = Colors.white.withAlpha(110);
    final pShadow = Paint()
      ..color = Colors.black.withAlpha(170)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.8 * arrowScale
      ..strokeCap = StrokeCap.round;
    final p = Paint()
      ..color = chalkInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.2 * arrowScale
      ..strokeCap = StrokeCap.round;
    final pDust = Paint()
      ..color = chalkDust
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * arrowScale
      ..strokeCap = StrokeCap.round;

    if (style == TutorialArrowStyle.pullDownBounce) {
      final card = cardRect;
      if (card == null) return;
      final bob = math.sin(phase * math.pi * 2) * 12;
      final start = Offset(card.center.dx, card.bottom + 14 + bob);
      final end = Offset(start.dx, start.dy + (126 * arrowScale));
      _drawChalkLine(canvas, start, end, pShadow, p, pDust);
      final head = 40.0 * arrowScale;
      final left = Offset(end.dx - (18 * arrowScale), end.dy - head);
      final right = Offset(end.dx + (18 * arrowScale), end.dy - head);
      _drawChalkLine(canvas, end, left, pShadow, p, pDust);
      _drawChalkLine(canvas, end, right, pShadow, p, pDust);
      return;
    }

    final target = targetRect;
    final card = cardRect;
    if (card == null) return;
    final fallbackPoint = fallbackScreenTargetAlignment == null
        ? null
        : _pointFromAlignment(
            Offset.zero & size,
            fallbackScreenTargetAlignment!,
          );
    var to = target != null
        ? _pointFromAlignment(target, targetAlignment)
        : fallbackPoint;
    if (to == null) return;
    if (card.contains(to)) {
      to =
          fallbackPoint ??
          Offset(card.center.dx, card.top - (120 * arrowScale));
    }
    final targetPoint = to;
    final edgePoint = targetPoint.dy < card.top
        ? (() {
            if (targetPoint.dx < card.left + 24) {
              return Offset(card.left - 12, card.top);
            }
            if (targetPoint.dx > card.right - 24) {
              return Offset(card.right + 12, card.top);
            }
            return Offset(
              targetPoint.dx.clamp(card.left + 24, card.right - 24),
              card.top,
            );
          })()
        : _nearestPointOnRect(card, to);
    final baseVx = to.dx - edgePoint.dx;
    final baseVy = to.dy - edgePoint.dy;
    final baseDist = math.max(
      1.0,
      math.sqrt(baseVx * baseVx + baseVy * baseVy),
    );
    final ux = baseVx / baseDist;
    final uy = baseVy / baseDist;
    final minTargetDistance = 86.0 * arrowScale;
    if (baseDist < minTargetDistance) {
      to = Offset(
        edgePoint.dx + (ux * minTargetDistance),
        edgePoint.dy + (uy * minTargetDistance),
      );
    }
    final from = Offset(edgePoint.dx + (ux * 22), edgePoint.dy + (uy * 22));
    _drawChalkLine(canvas, from, to, pShadow, p, pDust);

    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final head = 22.0 * arrowScale;
    final tip = to;
    final left = Offset(
      tip.dx - head * math.cos(angle - 0.52),
      tip.dy - head * math.sin(angle - 0.52),
    );
    final right = Offset(
      tip.dx - head * math.cos(angle + 0.52),
      tip.dy - head * math.sin(angle + 0.52),
    );
    _drawChalkLine(canvas, tip, left, pShadow, p, pDust);
    _drawChalkLine(canvas, tip, right, pShadow, p, pDust);
  }

  void _drawChalkLine(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint shadow,
    Paint main,
    Paint dust,
  ) {
    canvas.drawLine(a, b, shadow);
    canvas.drawLine(a, b, main);
    canvas.drawLine(a, b, dust);

    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.max(1.0, math.sqrt((dx * dx) + (dy * dy)));
    final nx = -dy / len;
    final ny = dx / len;

    final jitterA = Offset(
      a.dx + (nx * 1.4 * arrowScale),
      a.dy + (ny * 1.4 * arrowScale),
    );
    final jitterB = Offset(
      b.dx + (nx * 1.4 * arrowScale),
      b.dy + (ny * 1.4 * arrowScale),
    );
    canvas.drawLine(jitterA, jitterB, dust);
  }

  Offset _pointFromAlignment(Rect rect, Alignment alignment) {
    final dx = rect.center.dx + (alignment.x * rect.width / 2);
    final dy = rect.center.dy + (alignment.y * rect.height / 2);
    return Offset(dx, dy);
  }

  Offset _nearestPointOnRect(Rect rect, Offset point) {
    double x = point.dx.clamp(rect.left, rect.right);
    double y = point.dy.clamp(rect.top, rect.bottom);
    final inside =
        point.dx >= rect.left &&
        point.dx <= rect.right &&
        point.dy >= rect.top &&
        point.dy <= rect.bottom;
    if (!inside) return Offset(x, y);

    final leftDist = (point.dx - rect.left).abs();
    final rightDist = (rect.right - point.dx).abs();
    final topDist = (point.dy - rect.top).abs();
    final bottomDist = (rect.bottom - point.dy).abs();
    final minDist = math.min(
      math.min(leftDist, rightDist),
      math.min(topDist, bottomDist),
    );
    if (minDist == leftDist) return Offset(rect.left, point.dy);
    if (minDist == rightDist) return Offset(rect.right, point.dy);
    if (minDist == topDist) return Offset(point.dx, rect.top);
    return Offset(point.dx, rect.bottom);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect ||
      oldDelegate.cardRect != cardRect ||
      oldDelegate.style != style ||
      oldDelegate.phase != phase ||
      oldDelegate.targetAlignment != targetAlignment ||
      oldDelegate.arrowScale != arrowScale ||
      oldDelegate.fallbackScreenTargetAlignment !=
          fallbackScreenTargetAlignment;
}

class _ChalkCard extends StatelessWidget {
  final String title;
  final String body;
  final bool showBack;
  final bool isLast;
  final Color textColor;
  final Color background;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _ChalkCard({
    super.key,
    required this.title,
    required this.body,
    required this.showBack,
    required this.isLast,
    required this.textColor,
    required this.background,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final border = Colors.white.withAlpha(110);
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.fromLTRB(28, 14, 22, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.singleDay(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.w400,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.singleDay(
              color: textColor.withAlpha(225),
              fontSize: 27,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (showBack)
                TextButton(onPressed: onBack, child: const Text('Back')),
              const Spacer(),
              TextButton(onPressed: onSkip, child: const Text('Skip')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onNext,
                child: Text(isLast ? 'Got it' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
