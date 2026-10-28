import 'package:flutter/material.dart';

class TargetTouchMark {
  final Offset position;
  final bool isLeftHand;
  final double angle;

  TargetTouchMark({
    required this.position,
    required this.isLeftHand,
    required this.angle,
  });
}

class TargetTouchMarksWidget extends StatelessWidget {
  final List<TargetTouchMark> marks;

  const TargetTouchMarksWidget({
    super.key,
    required this.marks,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _TouchMarksPainter(marks: marks),
      ),
    );
  }
}

class _TouchMarksPainter extends CustomPainter {
  final List<TargetTouchMark> marks;

  _TouchMarksPainter({required this.marks});

  @override
  void paint(Canvas canvas, Size size) {
    // debugPrint('Painting ${marks.length} touch marks');
    for (final mark in marks) {
      // debugPrint('Painting mark at position: ${mark.position}, isLeft: ${mark.isLeftHand}, angle: ${mark.angle}');
      final color = mark.isLeftHand ? Colors.blue : Colors.red;
      final fillPaint = Paint()
        ..color = color.withAlpha((0.3 * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(mark.position, 15, fillPaint);

      // Draw a circle with X inside
      final paint = Paint()
        ..color = color.withAlpha((0.8 * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(mark.position, 15, paint);
      canvas.drawLine(
        mark.position.translate(-8, -8),
        mark.position.translate(8, 8),
        paint,
      );
      canvas.drawLine(
        mark.position.translate(8, -8),
        mark.position.translate(-8, 8),
        paint,
      );

      // Text with angle - commented out to show only visual marks
      /*
      final textSpan = TextSpan(
        text: '${mark.angle.toStringAsFixed(1)}°',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        mark.position.translate(-textPainter.width / 2, 20),
      );
      */
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
