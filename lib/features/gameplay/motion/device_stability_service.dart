import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DeviceStabilityService {
  // Main parameters
  static const double _stabilityThreshold = 0.5;
  static const Duration _requiredStableTime = Duration(milliseconds: 2500);
  static const Duration _eventThrottle = Duration(milliseconds: 50);
  static const Duration _updateDebounce = Duration(milliseconds: 50);
  static const Duration _angleWindow = Duration(seconds: 1);
  static const double _minAngle = 70.0;
  static const double _maxAngle = 120.0;
  static const double _alpha = 0.3;

  // State
  bool _isStable = false;
  bool _isStarted = false;
  DateTime? _stableStartTime;
  DateTime? _lastUpdateTime;
  double _lastFilteredMovement = 0.0;
  AccelerometerEvent? _lastEvent;
  double _currentAngle = 0.0;

  // History
  final List<double> _movementHistory = [];
  final List<_AngleSample> _angleHistory = [];

  // Stream Controllers
  final _stabilityController = BehaviorSubject<bool>.seeded(false);
  final _angleController = BehaviorSubject<double>.seeded(90.0);
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Getters
  double get currentAngle => _currentAngle;
  Duration get currentStableTime => _stableStartTime != null
      ? DateTime.now().difference(_stableStartTime!)
      : Duration.zero;
  Duration get requiredStableTime => _requiredStableTime;
  bool get isStable => _isStable;
  Stream<bool> get stabilityStream => _stabilityController.stream;
  Stream<double> get angleStream => _angleController.stream;

  void startStabilityCheck() {
    if (_isStarted) return;

    _isStarted = true;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _accelerometerSubscription =
        accelerometerEvents.throttleTime(_eventThrottle).listen((event) {
      final now = DateTime.now();

      final bool isDeviceStill = _checkIfDeviceStill(event);
      _updateAngleHistory(event, now);
      final bool isAngleCorrect = _isAngleStable(now);

      _currentAngle =
          _angleHistory.isNotEmpty ? _angleHistory.last.angle : _currentAngle;
      _angleController.add(_currentAngle);

      if (_lastUpdateTime != null &&
          now.difference(_lastUpdateTime!) < _updateDebounce) return;

      _lastUpdateTime = now;

      if (isDeviceStill) {
        if (_stableStartTime == null) {
          _stableStartTime = now;
        }

        final duration = now.difference(_stableStartTime!);
        if (duration >= _requiredStableTime && !_isStable) {
          _isStable = true;
          _stabilityController.add(true);
        }
      } else {
        if (_stableStartTime != null || _isStable) {
          _stableStartTime = null;
          _isStable = false;
          _stabilityController.add(false);
        }
      }

      _lastEvent = event;
    });
  }

  void _updateAngleHistory(AccelerometerEvent event, DateTime now) {
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final angleRad = acos(event.z / magnitude);
    final angleDeg = angleRad * (180 / pi);

    _angleHistory.add(_AngleSample(angleDeg, now));
    _angleHistory.removeWhere(
      (sample) => now.difference(sample.timestamp) > _angleWindow,
    );
  }

  bool _isAngleStable(DateTime now) {
    final recentSamples = _angleHistory
        .where((s) => now.difference(s.timestamp) <= _angleWindow)
        .toList();

    if (recentSamples.isEmpty) return false;

    final avgAngle = recentSamples.map((s) => s.angle).reduce((a, b) => a + b) /
        recentSamples.length;

    return avgAngle >= _minAngle && avgAngle <= _maxAngle;
  }

  bool _checkIfDeviceStill(AccelerometerEvent event) {
    if (_lastEvent == null) return false;

    final dx = event.x - _lastEvent!.x;
    final dy = event.y - _lastEvent!.y;
    final dz = event.z - _lastEvent!.z;

    final movement = sqrt(dx * dx + dy * dy + dz * dz);
    final filtered = _alpha * movement + (1 - _alpha) * _lastFilteredMovement;
    _lastFilteredMovement = filtered;

    _movementHistory.add(filtered);
    if (_movementHistory.length > 10) {
      _movementHistory.removeAt(0);
    }

    final avgMovement =
        _movementHistory.reduce((a, b) => a + b) / _movementHistory.length;

    return avgMovement < _stabilityThreshold;
  }

  void stopStabilityCheck() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isStarted = false;
    _isStable = false;
    _stableStartTime = null;
    SystemChrome.setPreferredOrientations([]);
  }

  void dispose() {
    stopStabilityCheck();
    _stabilityController.close();
    _angleController.close();
  }
}

class _AngleSample {
  final double angle;
  final DateTime timestamp;
  _AngleSample(this.angle, this.timestamp);
}
