import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialStep {
  final String title;
  final String body;
  final GlobalKey? targetKey;
  final Alignment cardAlignment;

  const TutorialStep({
    required this.title,
    required this.body,
    this.targetKey,
    this.cardAlignment = Alignment.bottomCenter,
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

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _stepIndex = 0;

  TutorialStep get _step => widget.steps[_stepIndex];

  Rect? _targetRect() {
    final targetKey = _step.targetKey;
    if (targetKey == null) return null;
    final context = targetKey.currentContext;
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
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetRect();
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
                painter: _SpotlightPainter(targetRect: target),
              ),
            ),
            Align(
              alignment: _step.cardAlignment,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: _ChalkCard(
                  title: _step.title,
                  body: _step.body,
                  textColor: chalkText,
                  background: chalkCard,
                  showBack: _stepIndex > 0,
                  onBack: () => setState(() => _stepIndex -= 1),
                  onNext: _next,
                  onSkip: widget.onSkip,
                  isLast: _stepIndex == widget.steps.length - 1,
                ),
              ),
            ),
            if (target != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ArrowPainter(
                      targetRect: target,
                      cardAlignment: _step.cardAlignment,
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
  final Rect targetRect;
  final Alignment cardAlignment;

  const _ArrowPainter({required this.targetRect, required this.cardAlignment});

  @override
  void paint(Canvas canvas, Size size) {
    final target = targetRect.center;
    final start = Offset(
      size.width * (cardAlignment.x + 1) / 2,
      size.height * (cardAlignment.y + 1) / 2,
    );

    final p = Paint()
      ..color = Colors.white.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        (start.dx + target.dx) / 2 + 30,
        (start.dy + target.dy) / 2 - 30,
        target.dx,
        target.dy,
      );
    canvas.drawPath(path, p);

    final angle = math.atan2(target.dy - start.dy, target.dx - start.dx);
    const head = 12.0;
    final tip = target;
    final left = Offset(
      tip.dx - head * math.cos(angle - 0.45),
      tip.dy - head * math.sin(angle - 0.45),
    );
    final right = Offset(
      tip.dx - head * math.cos(angle + 0.45),
      tip.dy - head * math.sin(angle + 0.45),
    );
    canvas.drawLine(tip, left, p);
    canvas.drawLine(tip, right, p);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect ||
      oldDelegate.cardAlignment != cardAlignment;
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
