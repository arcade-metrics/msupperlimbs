import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/rapid/controllers/pulse_line_controller.dart';

/// A widget that displays a vertical bar that rises and falls based on movement intensity
class PulseBarWidget extends StatefulWidget {
  /// The controller that manages the pulse data
  final PulseLineController controller;
  
  /// The height of the bar container
  final double height;
  
  /// The width of the bar
  final double width;
  
  /// The background color of the widget
  final Color backgroundColor;
  
  /// The opacity of the bar
  final double barOpacity;

  const PulseBarWidget({
    super.key,
    required this.controller,
    this.height = 300,
    this.width = 60,
    this.backgroundColor = Colors.black,
    this.barOpacity = 0.6,
  });

  @override
  State<PulseBarWidget> createState() => _PulseBarWidgetState();
}

class _PulseBarWidgetState extends State<PulseBarWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  Duration? _lastTime;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000 ~/ 60),
    )..addListener(_onTick)
    ..repeat();
  }

  void _onTick() {
    final now = Duration(microseconds: DateTime.now().microsecondsSinceEpoch);
    double dtSeconds = 1/30;
    if (_lastTime != null) {
      dtSeconds = (now - _lastTime!).inMicroseconds / 1e6;
    }
    _lastTime = now;

    widget.controller.tick(dtSeconds);
    setState(() {});
  }

  @override
  void dispose() {
    _anim.removeListener(_onTick);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = screenWidth / 3;
    final padding = barWidth * 0.1; // 10% padding proporcional
    
    return Container(
      width: barWidth,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final currentValue = widget.controller.points.isNotEmpty 
              ? widget.controller.points.last 
              : 0.0;
          
          // Colour based on value: red (0-0.25), amber (0.25-0.5), green (>0.5)
          final Color barColor;
          if (currentValue < 0.25) {
            barColor = Colors.red;
          } else if (currentValue < 0.5) {
            barColor = Colors.amber;
          } else {
            barColor = Colors.green;
          }
          
          return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: barWidth - (padding * 2),
              height: widget.height * currentValue.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: barColor.withOpacity(widget.barOpacity),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: barColor.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

