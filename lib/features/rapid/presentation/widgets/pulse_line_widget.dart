import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/rapid/controllers/pulse_line_controller.dart';
import 'package:msupperlimbs/features/rapid/models/pulse_line_state.dart';

/// A widget that displays a pulse line visualization based on movement intensity
class PulseLineWidget extends StatefulWidget {
  /// The controller that manages the pulse line data
  final PulseLineController controller;
  
  /// The height of the pulse line
  final double height;
  
  /// The width of the pulse line
  final double width;
  
  /// The background color of the widget
  final Color backgroundColor;
  
  /// The opacity of the background
  final double backgroundOpacity;

  /// Creates a new pulse line widget
  const PulseLineWidget({
    super.key,
    required this.controller,
    this.height = 80,
    this.width = double.infinity,
    this.backgroundColor = Colors.black,
    this.backgroundOpacity = 0.8,
    this.lineColor,
    this.lineWidth,
    this.glowEnabled,
    this.glowBlurSigma,
    this.useFixedDt,
    this.fixedDtSeconds,
  });
  
  /// The color of the line
  final Color? lineColor;
  
  /// The width of the line
  final double? lineWidth;
  
  /// Whether to show the glow effect
  final bool? glowEnabled;
  
  /// The blur sigma for the glow effect
  final double? glowBlurSigma;
  
  /// Whether to use a fixed time step
  final bool? useFixedDt;
  
  /// The fixed time step in seconds
  final double? fixedDtSeconds;


  @override
  State<PulseLineWidget> createState() => _PulseLineWidgetState();
}

class _PulseLineWidgetState extends State<PulseLineWidget> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  
  // Default visual settings
  Color _lineColor = Colors.green;
  double _lineWidth = 3.0;
  bool _glowEnabled = true;
  double _glowBlurSigma = 8.0;
  bool _useFixedDt = true;
  double _fixedDtSeconds = 1/30;

  Duration? _lastTime;

  @override
  void initState() {
    super.initState();
    
    // Apply settings if provided
    if (widget.lineColor != null) _lineColor = widget.lineColor!;
    if (widget.lineWidth != null) _lineWidth = widget.lineWidth!;
    if (widget.glowEnabled != null) _glowEnabled = widget.glowEnabled!;
    if (widget.glowBlurSigma != null) _glowBlurSigma = widget.glowBlurSigma!;
    if (widget.useFixedDt != null) _useFixedDt = widget.useFixedDt!;
    if (widget.fixedDtSeconds != null) _fixedDtSeconds = widget.fixedDtSeconds!;
    
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000 ~/ 60),
    )..addListener(_onTick)
    ..repeat();
  }

  void _onTick() {
    double dtSeconds;
    
    if (_useFixedDt) {
      // Usar passo fixo (mais estável)
      dtSeconds = _fixedDtSeconds;
    } else {
      // Usar passo variável baseado no tempo real
      final now = Duration(microseconds: DateTime.now().microsecondsSinceEpoch);
      dtSeconds = 1/30; // Default 30 FPS
      if (_lastTime != null) {
        dtSeconds = (now - _lastTime!).inMicroseconds / 1e6;
      }
      _lastTime = now;
    }

    // AVANÇA A SIMULAÇÃO:
    widget.controller.tick(dtSeconds);

    // Redesenha:
    setState(() {});
  }

  @override
  void dispose() {
    _anim.removeListener(_onTick);
    _anim.dispose();
    super.dispose();
  }
  
  /// Handles updates from the controller
  void _handleControllerUpdate() {
    // Force a rebuild when the controller updates
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor.withOpacity(widget.backgroundOpacity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return CustomPaint(
            painter: _PulseLinePainter(
              points: widget.controller.points,
              color: _lineColor,
              lineWidth: _lineWidth,
              state: widget.controller.state,
              glowEnabled: _glowEnabled,
              glowBlurSigma: _glowBlurSigma,
            ),
            size: Size(widget.width, widget.height),
          );
        },
      ),
    );
  }
}

/// Custom painter that draws the pulse line
class _PulseLinePainter extends CustomPainter {
  /// The points to draw
  final List<double> points;
  
  /// The color of the line
  final Color color;
  
  /// The width of the line
  final double lineWidth;
  
  /// The current state of the pulse line
  final PulseLineState state;
  
  /// Whether to show the glow effect
  final bool _glowEnabled;
  
  /// The blur sigma for the glow effect
  final double _glowBlurSigma;

  _PulseLinePainter({
    required this.points,
    required this.color,
    required this.lineWidth,
    required this.state,
    bool glowEnabled = true,
    double glowBlurSigma = 8.0,
  }) : _glowEnabled = glowEnabled,
       _glowBlurSigma = glowBlurSigma;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Determinar a cor baseada no valor atual (último ponto)
    final currentValue = points.last;
    final Color lineColor;
    
    // Cor baseada no valor: vermelho (0-0.25), amarelo (0.25-0.5), verde (>0.5)
    if (currentValue < 0.25) {
      lineColor = Colors.red;
    } else if (currentValue < 0.5) {
      lineColor = Colors.amber;
    } else {
      lineColor = Colors.green;
    }

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Calculate the horizontal step between points
    final double dx = size.width / (points.length - 1);
    
    // Start the path at the first point
    final double initialY = size.height - (points.first * size.height);
    path.moveTo(0, initialY);
    
    // Usar curva suavizada para todos os pontos
    if (points.length >= 3) {
      // Criar uma lista de pontos para a curva
      final List<Offset> pointOffsets = [];
      for (int i = 0; i < points.length; i++) {
        final double x = i * dx;
        final double y = size.height - (points[i] * size.height);
        pointOffsets.add(Offset(x, y));
      }
      
      // Desenhar curva suavizada usando Catmull-Rom spline
      for (int i = 0; i < pointOffsets.length - 1; i++) {
        final Offset p0 = i > 0 ? pointOffsets[i - 1] : pointOffsets[i];
        final Offset p1 = pointOffsets[i];
        final Offset p2 = pointOffsets[i + 1];
        final Offset p3 = i < pointOffsets.length - 2 ? pointOffsets[i + 2] : p2;
        
        // Desenhar segmentos pequenos para uma curva mais suave
        for (double t = 0; t <= 1; t += 0.05) {
          final double t2 = t * t;
          final double t3 = t2 * t;
          
          // Fórmula Catmull-Rom
          final double tension = 0.5; // Valor entre 0 e 1, quanto menor mais suave
          
          final double x = 0.5 * ((2 * p1.dx) +
              (-p0.dx + p2.dx) * t +
              (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
              (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);
          
          final double y = 0.5 * ((2 * p1.dy) +
              (-p0.dy + p2.dy) * t +
              (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
              (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);
          
          if (t == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
      }
    } else {
      // Fallback para poucos pontos
      for (int i = 1; i < points.length; i++) {
        final double x = i * dx;
        final double y = size.height - (points[i] * size.height);
        path.lineTo(x, y);
      }
    }
    
    // Draw the path
    canvas.drawPath(path, paint);
    
    // Add a glow effect if enabled
    if (_glowEnabled) {
      final glowPaint = Paint()
        ..color = lineColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth * 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _glowBlurSigma);
      
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_PulseLinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.state != state;
  }
}
