import 'dart:math';
import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/rapid/controllers/pulse_line_controller.dart';

/// A widget that displays a growing/shrinking circle based on movement intensity
class PulseCircleWidget extends StatefulWidget {
  /// The controller that manages the pulse data
  final PulseLineController controller;
  
  /// The size of the container
  final double size;
  
  /// The background color of the widget
  final Color backgroundColor;
  
  /// The opacity of the circle
  final double circleOpacity;
  
  /// Whether to show target rings
  final bool showTargetRings;
  
  /// Whether to show particles
  final bool showParticles;

  const PulseCircleWidget({
    super.key,
    required this.controller,
    this.size = 300,
    this.backgroundColor = Colors.black,
    this.circleOpacity = 0.6,
    this.showTargetRings = true,
    this.showParticles = true,
  });

  @override
  State<PulseCircleWidget> createState() => _PulseCircleWidgetState();
}

class _PulseCircleWidgetState extends State<PulseCircleWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _particleAnim;
  final List<_Particle> _particles = [];
  final Random _random = Random();
  double _previousValue = 0.0;
  Duration? _lastTime;

  @override
  void initState() {
    super.initState();
    _particleAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateParticles)
    ..repeat();
  }

  void _updateParticles() {
    // Calculate dt and tick the controller
    final now = Duration(microseconds: DateTime.now().microsecondsSinceEpoch);
    double dtSeconds = 1/30;
    if (_lastTime != null) {
      dtSeconds = (now - _lastTime!).inMicroseconds / 1e6;
    }
    _lastTime = now;
    
    widget.controller.tick(dtSeconds);
    
    if (!widget.showParticles) {
      setState(() {});
      return;
    }
    
    final currentValue = widget.controller.points.isNotEmpty 
        ? widget.controller.points.last 
        : 0.0;
    
    // Spawn particles on significant increase
    if (currentValue > _previousValue + 0.1) {
      _spawnParticles(currentValue);
    }
    _previousValue = currentValue;
    
    // Update existing particles
    _particles.removeWhere((p) => p.life <= 0);
    for (var particle in _particles) {
      particle.update();
    }
    
    setState(() {});
  }

  void _spawnParticles(double intensity) {
    final color = _getColorForValue(intensity);
    for (int i = 0; i < 5; i++) {
      _particles.add(_Particle(
        color: color,
        angle: _random.nextDouble() * 2 * pi,
        speed: 1 + _random.nextDouble() * 2,
      ));
    }
  }

  Color _getColorForValue(double value) {
    if (value < 0.25) return Colors.red;
    if (value < 0.5) return Colors.amber;
    return Colors.green;
  }

  @override
  void dispose() {
    _particleAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: AnimatedBuilder(
        animation: _particleAnim,
        builder: (context, child) {
          final currentValue = widget.controller.points.isNotEmpty 
              ? widget.controller.points.last 
              : 0.0;
          
          return CustomPaint(
            painter: _PulseCirclePainter(
              value: currentValue,
              maxRadius: widget.size / 2,
              circleOpacity: widget.circleOpacity,
              showTargetRings: widget.showTargetRings,
              particles: widget.showParticles ? _particles : [],
            ),
            size: Size(widget.size, widget.size),
          );
        },
      ),
    );
  }
}

class _Particle {
  final Color color;
  final double angle;
  final double speed;
  double distance = 0;
  double life = 1.0;

  _Particle({
    required this.color,
    required this.angle,
    required this.speed,
  });

  void update() {
    distance += speed;
    life -= 0.02;
  }
}

class _PulseCirclePainter extends CustomPainter {
  final double value;
  final double maxRadius;
  final double circleOpacity;
  final bool showTargetRings;
  final List<_Particle> particles;

  _PulseCirclePainter({
    required this.value,
    required this.maxRadius,
    required this.circleOpacity,
    required this.showTargetRings,
    required this.particles,
  });

  Color _getColorForValue(double val) {
    if (val < 0.25) return Colors.red;
    if (val < 0.5) return Colors.amber;
    return Colors.green;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final currentRadius = (maxRadius * 0.3) + (maxRadius * 0.7 * value.clamp(0.0, 1.0));
    final circleColor = _getColorForValue(value);

    // Draw target rings
    if (showTargetRings) {
      final targetPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // Target at 25%, 50%, 75%
      final targets = [0.25, 0.5, 0.75];
      for (final target in targets) {
        final targetRadius = (maxRadius * 0.3) + (maxRadius * 0.7 * target);
        targetPaint.color = _getColorForValue(target).withOpacity(0.3);
        canvas.drawCircle(center, targetRadius, targetPaint);
      }
    }

    // Draw particles
    for (final particle in particles) {
      final particlePaint = Paint()
        ..color = particle.color.withOpacity(particle.life * 0.6)
        ..style = PaintingStyle.fill;
      
      final particleX = center.dx + cos(particle.angle) * particle.distance;
      final particleY = center.dy + sin(particle.angle) * particle.distance;
      
      canvas.drawCircle(
        Offset(particleX, particleY),
        3 * particle.life,
        particlePaint,
      );
    }

    // Draw main circle with glow
    final glowPaint = Paint()
      ..color = circleColor.withOpacity(0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawCircle(center, currentRadius + 10, glowPaint);

    // Draw main circle
    final circlePaint = Paint()
      ..color = circleColor.withOpacity(circleOpacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, currentRadius, circlePaint);

    // Draw border
    final borderPaint = Paint()
      ..color = circleColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(center, currentRadius, borderPaint);
  }

  @override
  bool shouldRepaint(_PulseCirclePainter oldDelegate) {
    return oldDelegate.value != value || 
           oldDelegate.particles.length != particles.length;
  }
}

