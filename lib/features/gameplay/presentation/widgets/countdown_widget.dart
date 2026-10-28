import 'dart:async';
import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';

class CountdownWidget extends StatefulWidget {
  final int initialTime;
  final VoidCallback onCountdownFinished;
  final FNoseGameMode gameMode;
  final bool showHands;

  const CountdownWidget({
    Key? key,
    required this.initialTime,
    required this.onCountdownFinished,
    required this.gameMode,
    required this.showHands,
  }) : super(key: key);

  @override
  _CountdownWidgetState createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget>
    with SingleTickerProviderStateMixin {
  late int _remainingTime;
  Timer? _timer;

  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.initialTime;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacityAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime <= 0) {
        timer.cancel();
        widget.onCountdownFinished();
      } else {
        setState(() {
          _remainingTime--;
          if (_remainingTime <= 5) {
            if (!_controller.isAnimating) {
              _controller.repeat(reverse: true);
            }
          } else {
            if (_controller.isAnimating) {
              _controller.stop();
              _controller.value = 1.0;
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isRight = widget.gameMode == FNoseGameMode.rightHand;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _controller.isAnimating
              ? _opacityAnimation
              : const AlwaysStoppedAnimation(1.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showHands)
                Opacity(
                  opacity: isRight ? 0.4 : 1.0,
                  child: Image.asset(
                    isRight
                        ? 'lib/assets/game_mode/left-hand-disabled-100x100.png'
                        : 'lib/assets/game_mode/left-hand-enabled-100x100.png',
                    width: 60,
                    height: 60,
                  ),
                ),
              if (widget.showHands) const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTime(_remainingTime),
                  style: TextStyle(
                    color: _remainingTime <= 5
                        ? Colors.redAccent
                        : _remainingTime <= 15
                            ? Colors.deepOrangeAccent
                            : Colors.lightGreenAccent,
                    fontSize: 42.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.showHands) const SizedBox(width: 12),
              if (widget.showHands)
                Opacity(
                  opacity: isRight ? 1.0 : 0.4,
                  child: Image.asset(
                    isRight
                        ? 'lib/assets/game_mode/right-hand-enabled-100x100.png'
                        : 'lib/assets/game_mode/right-hand-disabled-100x100.png',
                    width: 60,
                    height: 60,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
