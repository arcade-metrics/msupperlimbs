import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/pulse_line_controller.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/pulse_line_state.dart';

class PulseVisualization extends StatelessWidget {
  const PulseVisualization({
    super.key,
    required this.controller,
    required this.type,
    this.height = 88,
  });

  final PulseLineController controller;
  final String type;
  final double height;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      'bar' => _PulseBar(controller: controller, height: height),
      'circle' => _PulseCircle(controller: controller, size: height),
      _ => _PulseLine(controller: controller, height: height),
    };
  }
}

Color _colorFor(PulseLineState state) {
  return switch (state) {
    PulseLineState.idle => Colors.lightBlueAccent,
    PulseLineState.active => Colors.greenAccent,
    PulseLineState.unstable => Colors.amberAccent,
    PulseLineState.flatline => Colors.redAccent,
  };
}

class _PulseLine extends StatelessWidget {
  const _PulseLine({required this.controller, required this.height});

  final PulseLineController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          painter: _PulseLinePainter(
            points: controller.points,
            color: _colorFor(controller.state),
          ),
        ),
      ),
    );
  }
}

class _PulseLinePainter extends CustomPainter {
  _PulseLinePainter({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final n = points.length;
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? 0.0 : size.width * i / (n - 1);
      final y = size.height * (1.0 - points[i].clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PulseLinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

class _PulseBar extends StatelessWidget {
  const _PulseBar({required this.controller, required this.height});

  final PulseLineController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    final y = controller.currentY.clamp(0.0, 1.0);
    return SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: y,
          widthFactor: 0.12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _colorFor(controller.state),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseCircle extends StatelessWidget {
  const _PulseCircle({required this.controller, required this.size});

  final PulseLineController controller;
  final double size;

  @override
  Widget build(BuildContext context) {
    final y = controller.currentY.clamp(0.0, 1.0);
    final diameter = (size * 0.35) + (size * 0.65 * y);
    return SizedBox(
      height: size,
      width: size,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _colorFor(controller.state).withValues(alpha: 0.35),
            border: Border.all(color: _colorFor(controller.state), width: 3),
          ),
        ),
      ),
    );
  }
}
