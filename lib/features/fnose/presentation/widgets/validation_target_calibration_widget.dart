import 'dart:async';
import 'package:flutter/material.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';
import 'package:msupperlimbs/features/gameplay/presentation/widgets/target_widget.dart';

class FNoseTargetCalibrationWidget extends StatefulWidget {
  final FNoseGameMode gameMode;
  final double xPercent;
  final double yPercent;
  final double scale;
  final Offset? indexTipPosition;
  final void Function(Offset offset) onCalibrated;
  final Duration duration;
  
  // TODO: Move to advanced settings
  final double calibrationTargetMaxJitter;
  // TODO: Move to advanced settings
  final Duration calibrationTargetTimeFrozen;
  // TODO: Move to advanced settings
  final double calibrationTargetStabilityTolerance;

  const FNoseTargetCalibrationWidget({
    super.key,
    required this.gameMode,
    required this.xPercent,
    required this.yPercent,
    required this.scale,
    required this.indexTipPosition,
    required this.onCalibrated,
    this.duration = const Duration(seconds: 8),
    this.calibrationTargetMaxJitter = 20.0,
    this.calibrationTargetTimeFrozen = const Duration(seconds: 1),
    this.calibrationTargetStabilityTolerance = 30.0, // maxJitter * 1.5
  });

  @override
  State<FNoseTargetCalibrationWidget> createState() =>
      _FNoseTargetCalibrationWidgetState();
}

class _FNoseTargetCalibrationWidgetState
    extends State<FNoseTargetCalibrationWidget> {
  final List<Offset> _samples = [];
  Timer? _calibrationTimer;
  Timer? _stabilityTimer;
  Offset? _targetCenter;
  Offset? _lastTip;
  Offset? _stabilityCheckTip;
  bool _isCalibrating = false;
  bool _isCheckingStability = false;
  double _progress = 0.0;
  bool _isTipCentered = false;
  bool _showOverlay = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateTargetCenter();
  }

  @override
  void didUpdateWidget(covariant FNoseTargetCalibrationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final tip = widget.indexTipPosition;
    
    // If no tip detected, reset everything
    if (tip == null) {
      _resetStabilityCheck();
      return;
    }
    
    // If already calibrating, don't interfere
    if (_isCalibrating) return;
    
    // Start checking for stability
    if (!_isCheckingStability) {
      _startStabilityCheck(tip);
    } else {
      _checkIfStable(tip);
    }
  }

  void _calculateTargetCenter() {
    final screenSize = MediaQuery.of(context).size;
    final imageSize = screenSize.shortestSide * widget.scale;
    final isLeftHand = widget.gameMode == FNoseGameMode.leftHand;
    final xPos = isLeftHand 
        ? screenSize.width * widget.xPercent + (imageSize / 2)  // Borda esquerda do alvo
        : screenSize.width * (1 - widget.xPercent) - (imageSize / 2);  // Borda direita do alvo
    final yPos = screenSize.height * widget.yPercent;
    _targetCenter = Offset(xPos, yPos);
  }

  void _startStabilityCheck(Offset tip) {
    _isCheckingStability = true;
    _stabilityCheckTip = tip;
    
    _stabilityTimer = Timer(widget.calibrationTargetTimeFrozen, () {
      // If we reach here, tip was stable for the required duration
      _startCalibration();
    });
  }

  void _checkIfStable(Offset tip) {
    if (_stabilityCheckTip == null) return;
    
    final movement = (tip - _stabilityCheckTip!).distance;
    
    // If movement exceeds stability tolerance, reset
    if (movement > widget.calibrationTargetStabilityTolerance) {
      _resetStabilityCheck();
    }
  }

  void _resetStabilityCheck() {
    _stabilityTimer?.cancel();
    _stabilityTimer = null;
    _stabilityCheckTip = null;
    _isCheckingStability = false;
  }

  void _startCalibration() {
    setState(() {
      _isCalibrating = true;
      _isTipCentered = true;
    });
    _samples.clear();
    _progress = 0;
    _resetStabilityCheck();

    final totalSamples = widget.duration.inMilliseconds ~/ 100; // 80 samples @ 8s
    final discardSamples = 30; // First 3 seconds to discard

    _calibrationTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final tip = widget.indexTipPosition;
      if (tip == null || _targetCenter == null) {
        _resetCalibration();
        return;
      }

      // Check for excessive movement (jitter)
      if (_lastTip != null && (tip - _lastTip!).distance > widget.calibrationTargetMaxJitter) {
        _resetCalibration();
        return;
      }

      final offset = tip - _targetCenter!;
      _samples.add(offset);
      _lastTip = tip;

      setState(() {
        _progress = _samples.length / totalSamples;
      });

      if (_samples.length >= totalSamples) {
        // Use only last 5 seconds (samples 30-80)
        final usefulSamples = _samples.sublist(discardSamples);
        final avg = _calculateMeanOffset(usefulSamples);
        
        setState(() {
          _showOverlay = true;
        });

        Future.delayed(const Duration(seconds: 3), () {
          widget.onCalibrated(avg);
        });

        timer.cancel();
      }
    });
  }

  void _resetCalibration() {
    _calibrationTimer?.cancel();
    setState(() {
      _isCalibrating = false;
      _isTipCentered = false;
      _progress = 0;
    });
    _samples.clear();
    _lastTip = null;
  }

  Offset _calculateMeanOffset(List<Offset> offsets) {
    if (offsets.isEmpty) return Offset.zero;
    final dx =
        offsets.map((e) => e.dx).reduce((a, b) => a + b) / offsets.length;
    final dy =
        offsets.map((e) => e.dy).reduce((a, b) => a + b) / offsets.length;
    return Offset(dx, dy);
  }

  @override
  void dispose() {
    _calibrationTimer?.cancel();
    _stabilityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _calculateTargetCenter();

    final String message = widget.indexTipPosition == null
        ? 'Raise your hand to start'
        : (!_isCalibrating
            ? 'Point to the centre of the target and hold still'
            : 'Hold steady... Calibrating...');

    return Stack(
      children: [
        TargetWidget(
          gameMode: widget.gameMode,
          targetNumber: 1,
          xPercent: widget.xPercent,
          yPercent: widget.yPercent,
          scale: widget.scale,
          useCalibrationImage: true,
        ),

        // Top block: Title + Message
        Positioned(
          top: 40,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((0.4 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.calibration_calibratingTarget,
                  style: const TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 28,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 32,
                    color: !_isCalibrating
                        ? Colors.lightBlueAccent
                        : Colors.lightGreenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // Percentage above the bar
        Positioned(
          bottom: 70,
          left: 16,
          right: 16,
          child: Text(
            '${(_progress * 100).clamp(0, 100).toInt()}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black87,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Progress bar
        Positioned(
          bottom: 40,
          left: 16,
          right: 16,
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.white24,
            color: Colors.lightGreenAccent,
            minHeight: 16,
          ),
        ),

        // Overlay final
        if (_showOverlay)
          Positioned.fill(
            child: Container(
              color: Colors.blue.shade900.withOpacity(0.95),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.calibration_holdPosition,
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 32,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.calibration_startingIn,
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 28,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
