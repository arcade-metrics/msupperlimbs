import 'package:flutter/material.dart';

class TouchExplosion extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;
  final Color color;

  const TouchExplosion({
    required this.position,
    required this.onComplete,
    //this.color = Colors.lightGreenAccent,
    this.color = Colors.yellowAccent,
    super.key,
  });

  @override
  State<TouchExplosion> createState() => _TouchExplosionState();
}

class _TouchExplosionState extends State<TouchExplosion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward().whenComplete(widget.onComplete);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final scale = Tween<double>(begin: 0.2, end: 5.0).evaluate(_controller);
        final opacity =
            Tween<double>(begin: 0.8, end: 0.0).evaluate(_controller);

        return Positioned(
          left: widget.position.dx - 50,
          top: widget.position.dy - 50,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withAlpha((0.8 * 255).round()),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
