import 'package:flutter/material.dart';

class RapidTimerPreGameWidget extends StatefulWidget {
  final VoidCallback onFinished;

  const RapidTimerPreGameWidget({required this.onFinished, super.key});

  @override
  State<RapidTimerPreGameWidget> createState() => _RapidTimerPreGameWidgetState();
}

class _RapidTimerPreGameWidgetState extends State<RapidTimerPreGameWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _currentIndex = 0;
  final List<String> _sequence = ['3', '2', '1', 'GO!'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_currentIndex < _sequence.length - 1) {
            setState(() {
              _currentIndex++;
            });
            _controller.forward(from: 0);
          } else {
            Future.delayed(const Duration(milliseconds: 300), () {
              widget.onFinished();
            });
          }
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
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    final currentText = _sequence[_currentIndex];
    final isGo = currentText == 'GO!';

    final backgroundColor = isGo
        ? Colors.green.shade800
            .withAlpha((0.9 * 255).round()) // GO! com fundo forte
        : Colors.black
            .withAlpha((0.8 * 255).round()); // contagem com fundo escuro

    final textColor = isGo ? Colors.white : Colors.lightBlueAccent;

    final shadowColor = isGo
        ? Colors.white.withAlpha((0.8 * 255).round())
        : Colors.black.withAlpha((0.8 * 255).round());

    final baseScale = isGo ? 1.2 : 1.0;
    final scale = baseScale + animation.value * 1.5;
    final opacity = 1.0 - animation.value;

    return Container(
      color: backgroundColor,
      child: Center(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Text(
                  currentText,
                  style: TextStyle(
                    fontSize: 120,
                    fontFamily: 'BebasNeue',
                    color: textColor,
                    shadows: [
                      Shadow(
                        offset: const Offset(3, 3),
                        blurRadius: 10,
                        color: shadowColor,
                      ),
                    ],
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
