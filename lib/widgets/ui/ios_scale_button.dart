import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IOSScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double pressedScale; // Default 0.97
  final bool enableFeedback;

  const IOSScaleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.pressedScale = 0.97,
    this.enableFeedback = true,
  });

  @override
  State<IOSScaleButton> createState() => _IOSScaleButtonState();
}

class _IOSScaleButtonState extends State<IOSScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    // Press: 90ms. Release: 120ms. We use a base duration and reverse.
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));

    _scaleAnim = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.2, 0.0, 0.0, 1.0),
        reverseCurve: const Cubic(0.2, 0.0, 0.0, 1.0),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enableFeedback) HapticFeedback.selectionClick();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    // Release duration: 120ms. Wait slightly if tap was super fast?
    // Apple feels responsive. Reverse immediately but with curve.
    _controller.duration = const Duration(milliseconds: 120);
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.duration = const Duration(milliseconds: 120);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: widget.child,
      ),
    );
  }
}
