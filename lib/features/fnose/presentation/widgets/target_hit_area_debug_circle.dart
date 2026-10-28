import 'package:flutter/material.dart';

class TargetHitboxPainter extends CustomPainter {
  final Offset center;
  final double targetScale;

  TargetHitboxPainter({
    required this.center,
    required this.targetScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.shortestSide * 0.5 * targetScale;

    final Paint borderPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
