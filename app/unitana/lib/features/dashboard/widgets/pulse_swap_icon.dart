import 'package:flutter/material.dart';

/// A subtle, Dracula-friendly pulse that hints the swap affordance is tappable.
///
/// Animations are disabled in widget tests and when the platform requests
/// reduced motion.
class PulseSwapIcon extends StatefulWidget {
  final Color color;
  final double size;
  final IconData icon;

  const PulseSwapIcon({
    super.key,
    required this.color,
    this.size = 18,
    this.icon = Icons.swap_horiz_rounded,
  });

  @override
  State<PulseSwapIcon> createState() => _PulseSwapIconState();
}

class _PulseSwapIconState extends State<PulseSwapIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  bool get _isTest {
    if (bool.fromEnvironment('FLUTTER_TEST')) return true;
    final binding = WidgetsBinding.instance;
    return binding.runtimeType.toString().contains('TestWidgetsFlutterBinding');
  }

  void _syncAnimation() {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (_isTest || disableAnimations) {
      _controller.stop();
      _controller.value = 1;
      return;
    }

    if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
      lowerBound: 0.35,
      upperBound: 1.0,
      value: 1.0,
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant PulseSwapIcon oldWidget) {
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
    return FadeTransition(
      opacity: _opacity,
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
