import 'dart:async';
import 'package:flutter/material.dart';

class CountdownPreGameWidget extends StatefulWidget {
  final Function(bool) onCountdownPreGameFinished;

  const CountdownPreGameWidget({
    Key? key,
    required this.onCountdownPreGameFinished,
  }) : super(key: key);

  @override
  _CountdownPreGameWidgetState createState() => _CountdownPreGameWidgetState();
}

class _CountdownPreGameWidgetState extends State<CountdownPreGameWidget> {
  late int _remainingTime;
  Timer? _timer;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _remainingTime = 5;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime <= 0) {
        timer.cancel();
        setState(() {
          _isVisible = false;
        });
        widget.onCountdownPreGameFinished(true);
      } else {
        setState(() {
          _remainingTime--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return SizedBox.shrink();

    return Stack(
      children: [
        Container(
          color: Colors.black54,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          child: _remainingTime >= 3
              ? const SizedBox.shrink()
              : Text(
                  _remainingTime == 0 ? "START!" : "$_remainingTime",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 100,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
