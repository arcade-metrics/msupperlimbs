import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/normalised_offset_utils.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/touch_logger_utils.dart';

class HeatmapPainterWidget extends StatelessWidget {
  final List<TouchLog> logs;

  const HeatmapPainterWidget({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No touch data',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            CustomPaint(
              painter: HeatmapPainter(logs),
              child: Container(),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: TargetOverlayPainter(logs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeatmapPainter extends CustomPainter {
  final List<TouchLog> logs;

  HeatmapPainter(this.logs);

  @override
  void paint(Canvas canvas, Size size) {
    // Fundo branco
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Grid moderno
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 1;

    const double step = 40;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Pontos de toque com gradiente
    for (final log in logs) {
      final Offset p = log.markPosition.toOffset(size);
      
      // Círculo externo com transparência
      final outerPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 12.0, outerPaint);
      
      // Círculo interno mais sólido
      final innerPaint = Paint()
        ..color = Colors.blue.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 6.0, innerPaint);
      
      // Centro do ponto
      final centerPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 2.0, centerPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class TargetOverlayPainter extends CustomPainter {
  final List<TouchLog> logs;

  TargetOverlayPainter(this.logs);

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    final Offset center = logs.first.targetCenter.toOffset(size);

    // Cruz do centro
    final crossPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 2;

    const double crossSize = 12;
    canvas.drawLine(center - Offset(crossSize, 0),
        center + Offset(crossSize, 0), crossPaint);
    canvas.drawLine(center - Offset(0, crossSize),
        center + Offset(0, crossSize), crossPaint);

    // Círculos concêntricos
    final circlePaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, i * 40.0, circlePaint);
    }
    
    // Círculo central do alvo
    final centerCirclePaint = Paint()
      ..color = Colors.red.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8.0, centerCirclePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
