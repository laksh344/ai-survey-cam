import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class IOSGlassContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final double? width;
  final double? height;
  final double opacity; // Default to AppColors.opGlassMin

  const IOSGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.opacity = AppColors.opGlassMin,
  });

  @override
  State<IOSGlassContainer> createState() => _IOSGlassContainerState();
}

class _IOSGlassContainerState extends State<IOSGlassContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240), // 220-260ms rule
    );
    _opacityAnim = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.2, 0.0, 0.0, 1.0), // Global Apple curve
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: widget.opacity),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: AppColors.opGlassBorder),
                width: 1, // Soft 1px border
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
