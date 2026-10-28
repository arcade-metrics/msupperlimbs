import 'dart:async';
import 'package:flutter/material.dart';

class SparkFireMarker extends StatefulWidget {
  final Offset position;
  final double size;

  const SparkFireMarker({
    super.key,
    required this.position,
    this.size = 30,
  });

  @override
  State<SparkFireMarker> createState() => _SparkFireMarkerState();
}

class _SparkFireMarkerState extends State<SparkFireMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // TODO rise to 2 sec
    );

    _fadeAnimation = Tween(begin: 1.0, end: 0.3).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    // Wait 100ms, and tham start animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - widget.size / 2,
      top: widget.position.dy - widget.size / 2,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _SparkPainter(),
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // External circle (border)
    final borderPaint = Paint()
      ..color = Colors.redAccent.withAlpha((0.8 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Internal circle (fill)
    final fillPaint = Paint()
      ..color = Colors.orangeAccent.withAlpha((0.3 * 255).round())
      ..style = PaintingStyle.fill;

    // Draw internal circle with fill
    canvas.drawCircle(center, radius, fillPaint);

    // Draw external circle (border)
    canvas.drawCircle(center, radius, borderPaint);

    // Draw the X on centre
    final crossPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final crossSize = radius * 0.5;
    canvas.drawLine(
      Offset(center.dx - crossSize, center.dy - crossSize),
      Offset(center.dx + crossSize, center.dy + crossSize),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx + crossSize, center.dy - crossSize),
      Offset(center.dx - crossSize, center.dy + crossSize),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
