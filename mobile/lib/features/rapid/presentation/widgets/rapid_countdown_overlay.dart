import 'package:flutter/material.dart';

class RapidCountdownOverlay extends StatefulWidget {
  const RapidCountdownOverlay({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<RapidCountdownOverlay> createState() => _RapidCountdownOverlayState();
}

class _RapidCountdownOverlayState extends State<RapidCountdownOverlay>
    with SingleTickerProviderStateMixin {
  static const _sequence = ['3', '2', '1', 'GO!'];
  late final AnimationController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 850),
        )..addStatusListener((status) {
          if (status != AnimationStatus.completed) return;
          if (_index < _sequence.length - 1) {
            setState(() => _index++);
            _controller.forward(from: 0);
          } else {
            Future<void>.delayed(const Duration(milliseconds: 250), () {
              if (mounted) widget.onFinished();
            });
          }
        });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _sequence[_index];
    final isGo = text == 'GO!';
    return ColoredBox(
      color: (isGo ? Colors.green.shade800 : Colors.black).withValues(
        alpha: 0.82,
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeOut.transform(_controller.value);
            return Opacity(
              opacity: (1.0 - t * 0.85).clamp(0.15, 1.0),
              child: Transform.scale(
                scale: (isGo ? 1.1 : 1.0) + t * 1.2,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: isGo ? 96 : 110,
                    fontWeight: FontWeight.w900,
                    color: isGo ? Colors.white : Colors.lightBlueAccent,
                    letterSpacing: 2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
