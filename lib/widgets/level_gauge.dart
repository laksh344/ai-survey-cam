import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math' as math;
import '../core/app_colors.dart';

/// Rotating level gauge line that shows phone tilt
class LevelGauge extends StatefulWidget {
  const LevelGauge({super.key});

  @override
  State<LevelGauge> createState() => _LevelGaugeState();
}

class _LevelGaugeState extends State<LevelGauge> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _tiltAngle = 0.0; // in degrees

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        // Calculate tilt angle from accelerometer data
        // Using X and Y components to determine horizontal tilt
        final double tilt = math.atan2(event.x, event.y) * (180 / math.pi);

        if (mounted) {
          setState(() {
            _tiltAngle = tilt;
          });
        }
      },
      onError: (error) {
        // Handle error silently
      },
    );
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _EngineeringLevelPainter(
          tiltAngle: _tiltAngle,
          color: AppColors.guideLines,
        ),
        child: Container(),
      ),
    );
  }
}

class _EngineeringLevelPainter extends CustomPainter {
  final double tiltAngle;
  final Color color;

  _EngineeringLevelPainter({required this.tiltAngle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw fixed crosshair
    const double crosshairSize = 20.0;
    canvas.drawLine(
      center.translate(-crosshairSize, 0),
      center.translate(crosshairSize, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -crosshairSize),
      center.translate(0, crosshairSize),
      paint,
    );

    // Draw rotating horizon line
    final double horizonLength = size.width * 0.8;

    // Save canvas state
    canvas.save();

    // Rotate canvas around center
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tiltAngle * (math.pi / 180));
    canvas.translate(-center.dx, -center.dy);

    // Draw horizon
    canvas.drawLine(
      center.translate(-horizonLength / 2, 0),
      center.translate(horizonLength / 2, 0),
      paint,
    );

    // Restore canvas
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EngineeringLevelPainter oldDelegate) {
    return oldDelegate.tiltAngle != tiltAngle || oldDelegate.color != color;
  }
}
