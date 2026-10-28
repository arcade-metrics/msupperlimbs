import 'dart:math';

import 'package:flutter/material.dart';

class FingerAura extends StatefulWidget {
  const FingerAura({
    super.key,
    required this.position,
    this.duration = const Duration(milliseconds: 450),
    this.radius = 45,
  });

  final Offset position;
  final Duration duration;
  final double radius;

  @override
  State<FingerAura> createState() => _FingerAuraState();
}

class _FingerAuraState extends State<FingerAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - widget.radius,
      top: widget.position.dy - widget.radius,
      child: SizedBox(
        width: widget.radius * 2,
        height: widget.radius * 2,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
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
  _ParticlePainter(this.t);
  final double t; // 0→1

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42); // deterministic sparkle pattern
    for (int i = 0; i < 14; i++) {
      final r = size.width / 2 * t; // radial expansion
      final angle = i * pi * 2 / 14 + rnd.nextDouble() * 0.3;
      final dx = size.width / 2 + r * cos(angle);
      final dy = size.height / 2 + r * sin(angle);
      final opacity = (1 - t).clamp(0.0, 1.0);
      final colour = Colors.yellowAccent.withOpacity(opacity);
      canvas.drawCircle(
          Offset(dx, dy), 2 + 3 * (1 - t), Paint()..color = colour);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}
