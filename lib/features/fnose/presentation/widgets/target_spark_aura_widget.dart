import 'dart:math';
import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/spark_state_enum.dart';

class SparkAuraWidget extends StatefulWidget {
  final Offset? position;
  final SparkState sparkState;
  final double radius;
  final Duration duration;

  const SparkAuraWidget({
    super.key,
    required this.position,
    required this.sparkState,
    this.radius = 45,
    this.duration = const Duration(milliseconds: 450),
  });

  @override
  State<SparkAuraWidget> createState() => _SparkAuraWidgetState();
}

class _SparkAuraWidgetState extends State<SparkAuraWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void didUpdateWidget(covariant SparkAuraWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldShowAura(widget.sparkState)) {
      _ctrl.repeat();
    } else {
      _ctrl.stop();
    }
  }

  bool _shouldShowAura(SparkState state) {
    return state == SparkState.armed || state == SparkState.aiming;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.position == null || !_shouldShowAura(widget.sparkState)) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: widget.position!.dx - widget.radius,
      top: widget.position!.dy - widget.radius,
      child: SizedBox(
        width: widget.radius * 2,
        height: widget.radius * 2,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value; // 0 → 1
            return CustomPaint(
              painter: _ParticlePainter(t),
            );
          },
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  final Random _rnd = Random(42);

  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 14; i++) {
      final r = size.width / 2 * t;
      final angle = i * pi * 2 / 14 + _rnd.nextDouble() * 0.3;
      final dx = size.width / 2 + r * cos(angle);
      final dy = size.height / 2 + r * sin(angle);
      final opacity = (1 - t).clamp(0.0, 1.0);
      final colour = Colors.yellowAccent.withOpacity(opacity);
      canvas.drawCircle(
        Offset(dx, dy),
        2 + 3 * (1 - t),
        Paint()..color = colour,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}
