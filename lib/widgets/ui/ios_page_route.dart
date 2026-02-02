import 'package:flutter/material.dart';

class IOSPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  IOSPageRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // New screen: Scale 0.98 -> 1.0, Opacity 0 -> 1
            const Curve curve = Cubic(0.2, 0.0, 0.0, 1.0);

            final Animation<double> curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1.0)
                    .animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}
