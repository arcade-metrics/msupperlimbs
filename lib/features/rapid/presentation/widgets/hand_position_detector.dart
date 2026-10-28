import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/gameplay/application/device_stability_service_provider.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/rapid_hand_validation_widget.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/rapid_stability_checker_overlay.dart';
import 'package:msupperlimbs/features/rapid/presentation/widgets/rapid_timer_pre_game.dart';

class HandPositionDetector extends ConsumerStatefulWidget {
  /// Callback when hand detection is complete and game should start
  final VoidCallback onDetectionComplete;
  
  /// Hand landmarks from the parent widget
  final List<Map<String, dynamic>> handLandmarks;

  const HandPositionDetector({
    Key? key,
    required this.onDetectionComplete,
    required this.handLandmarks,
  }) : super(key: key);

  @override
  ConsumerState<HandPositionDetector> createState() => _HandPositionDetectorState();
}

class _HandPositionDetectorState extends ConsumerState<HandPositionDetector> {
  // Pre-game validation states
  bool _isPreGame = false;
  bool _showValidationUI = false;
  bool _isHandValidated = false;
  bool _showTimerPreGame = false;
  
  // Hand detection state
  bool _isHandDetected = false;
  Timer? _handDetectionTimer;
  Timer? _stabilityTimer;
  
  @override
  void initState() {
    super.initState();
    _checkHandDetection();
    _initStabilityCheck();
  }
  
  @override
  void didUpdateWidget(HandPositionDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkHandDetection();
  }
  
  void _initStabilityCheck() {
    final stabilityService = ref.read(deviceStabilityServiceProvider);
    
    // Check periodically if device is stable and hand is detected
    _stabilityTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return;
      
      final isStable = stabilityService.isStable;
      
      if (isStable && !_showValidationUI) {
        // Device just became stable - show validation UI after a small delay
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && stabilityService.isStable) {
            setState(() {
              _showValidationUI = true;
            });
          }
        });
      } else if (!isStable && _showValidationUI) {
        // Device is no longer stable - hide validation UI
        setState(() {
          _showValidationUI = false;
          _isHandValidated = false;
          _showTimerPreGame = false;
        });
        _handDetectionTimer?.cancel();
      }
      
      // Check hand detection continuously when validation UI is shown
      if (_showValidationUI && !_isHandValidated) {
        _checkHandDetection();
      }
    });
  }
  
  void _checkHandDetection() {
    final bool handDetected = widget.handLandmarks.isNotEmpty;
    
    if (handDetected != _isHandDetected) {
      setState(() {
        _isHandDetected = handDetected;
      });
      
      if (handDetected && !_isHandValidated && _handDetectionTimer == null) {
        debugPrint('[HandPositionDetector] Hand just detected, starting 3 second timer');
        _handDetectionTimer = Timer(const Duration(seconds: 3), () {
          debugPrint('[HandPositionDetector] 3 seconds elapsed, hand still detected: $_isHandDetected');
          if (mounted && _isHandDetected) {
            setState(() {
              _isHandValidated = true;
              _showTimerPreGame = true;
            });
            debugPrint('[HandPositionDetector] Hand validated, starting countdown timer');
          }
        });
      } else if (!handDetected) {
        debugPrint('[HandPositionDetector] Hand lost, canceling timer');
        _handDetectionTimer?.cancel();
        _handDetectionTimer = null;
        if (_isHandValidated) {
          setState(() {
            _isHandValidated = false;
            _showTimerPreGame = false;
          });
        }
      }
    }
  }
  
  @override
  void dispose() {
    _handDetectionTimer?.cancel();
    _stabilityTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final stabilityAsync = ref.watch(deviceStabilityProvider);
    
    return Stack(
      children: [
        // Hand position guide image - only show when validation UI is active
        if (_showValidationUI && !_isHandValidated)
          Positioned.fill(
            child: Center(
              child: Transform.scale(
                scale: 1.44, // Increase image size by 44% (1.2 * 1.2)
                child: Image.asset(
                  _isHandDetected 
                      ? 'lib/assets/positions/hand_position-green-2400x1080.png'
                      : 'lib/assets/positions/hand_position-blue-2400x1080.png',
                  fit: BoxFit.cover, // Changed from contain to cover to allow cropping
                ),
              ),
            ),
          ),
        
        // Device stability checker (first phase) - shows until validation UI is active
        RapidStabilityCheckerOverlay(
          stabilityAsync: stabilityAsync,
          showValidationUI: _showValidationUI,
        ),
        
        // Hand validation overlay (second phase) - shows with the image
        if (_showValidationUI && !_isHandValidated)
          Positioned.fill(
            child: RapidHandValidationWidget(
              isHandDetected: _isHandDetected,
              currentMessage: _isHandDetected 
                  ? 'Hand detected, please hold position...' 
                  : 'Please position your hand in the center',
            ),
          ),
        
        // Pre-game countdown (final phase)
        if (_showTimerPreGame)
          Positioned.fill(
            child: RapidTimerPreGameWidget(
              onFinished: () {
                setState(() {
                  _showTimerPreGame = false;
                });
                widget.onDetectionComplete();
              },
            ),
          ),
      ],
    );
  }
}