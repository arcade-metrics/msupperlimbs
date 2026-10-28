import 'dart:math';
import 'package:flutter/material.dart';

class AccuracyGaugePainter extends CustomPainter {
  final double precisionIndex; // Changed from accuracyRate to precisionIndex
  final bool isDarkMode;

  AccuracyGaugePainter({required this.precisionIndex, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = 20.0;
    final barY = size.height / 2 - barHeight / 2;
    final barWidth = size.width - 40; // Leave space for labels
    final barX = 20.0;

    // Define precision ranges and colors (0-1 scale)
    const precisionRanges = [
      {'min': 0.0, 'max': 0.25, 'color': Colors.red, 'label': 'Poor'},
      {'min': 0.25, 'max': 0.5, 'color': Colors.orange, 'label': 'Low'},
      {'min': 0.5, 'max': 0.75, 'color': Colors.lightGreen, 'label': 'Good'},
      {'min': 0.75, 'max': 1.0, 'color': Colors.green, 'label': 'Excellent'},
    ];

    // Draw background bar
    final backgroundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey.withOpacity(0.3);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(10),
      ),
      backgroundPaint,
    );

    // Draw colored segments
    double currentX = barX;
    for (final range in precisionRanges) {
      final segmentWidth =
          ((range['max'] as double) - (range['min'] as double)) *
              barWidth;

      final segmentPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = range['color'] as Color;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(currentX, barY, segmentWidth, barHeight),
          const Radius.circular(10),
        ),
        segmentPaint,
      );

      currentX += segmentWidth;
    }

    // Draw pointer
    final pointerPosition = _getPointerPosition(precisionIndex, barWidth);
    final pointerColor = isDarkMode ? Colors.white : Colors.black;
    final pointerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = pointerColor;

    final pointerX = barX + pointerPosition;

    // Draw pointer line
    canvas.drawLine(
      Offset(pointerX, barY - 5),
      Offset(pointerX, barY + barHeight + 5),
      pointerPaint,
    );

    // Draw pointer triangle
    final path = Path();
    path.moveTo(pointerX - 8, barY - 10);
    path.lineTo(pointerX + 8, barY - 10);
    path.lineTo(pointerX, barY - 20);
    path.close();

    canvas.drawPath(path, pointerPaint);

    // Draw precision index text (convert to percentage)
    final textSpan = TextSpan(
      text: '${(precisionIndex * 100).toStringAsFixed(1)}%',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: pointerColor,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(pointerX - textPainter.width / 2, barY + barHeight + 10),
    );

    // Draw range labels
    _drawRangeLabels(
        canvas, barX, barWidth, barY + barHeight + 35, precisionRanges);
  }

  double _getPointerPosition(double precisionIndex, double barWidth) {
    // precisionIndex is already 0-1, so we can use it directly
    return precisionIndex * barWidth;
  }

  void _drawRangeLabels(Canvas canvas, double barX, double barWidth,
      double labelY, List<Map<String, dynamic>> ranges) {
    for (int i = 0; i < ranges.length; i++) {
      final range = ranges[i];
      final midPoint =
          ((range['min'] as double) + (range['max'] as double)) / 2;
      final labelX = barX + (midPoint * barWidth);

      final textSpan = TextSpan(
        text: range['label'] as String,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: range['color'] as Color,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AccuracyGaugeWidget extends StatelessWidget {
  final double precisionIndex;
  final double height;

  const AccuracyGaugeWidget({
    Key? key,
    required this.precisionIndex,
    this.height = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: AccuracyGaugePainter(
          precisionIndex: precisionIndex,
          isDarkMode: isDarkMode,
        ),
        size: Size.infinite,
      ),
    );
  }
}
