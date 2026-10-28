import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/touch_logger_utils.dart';

class HeatmapPainter extends CustomPainter {
  final List<TouchLog> logs;
  final Brightness brightness;

  HeatmapPainter(this.logs, this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    for (final log in logs) {
      final Offset p = log.markPosition.toOffset(size);

      final isLeft = log.isLeftHand;
      final baseColor = isLeft ? Colors.blue : Colors.red;

      final isDark = brightness == Brightness.dark;
      final Color heatColor = isDark
          ? baseColor.withAlpha((0.15 * 255).round())
          : Colors.black.withAlpha((0.05 * 255).round());

      canvas.drawCircle(
        p,
        40.0,
        Paint()
          ..color = heatColor
          ..style = PaintingStyle.fill,
      );

      // Touch point
      final markPaint = Paint()
        ..color = baseColor.withAlpha((0.6 * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(p, 6.0, markPaint);
    }

    // Target center
    if (logs.isNotEmpty) {
      final Offset target = logs.first.targetCenter.toOffset(size);

      final crossPaint = Paint()
        ..color = Colors.red.withAlpha((0.9 * 255).round())
        ..strokeWidth = 2.0;

      const double crossSize = 10.0;
      canvas.drawLine(target - Offset(crossSize, 0),
          target + Offset(crossSize, 0), crossPaint);
      canvas.drawLine(target - Offset(0, crossSize),
          target + Offset(0, crossSize), crossPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
