import 'dart:math' as math;

import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';

/// Tracks elbow angle + nose/target touch readiness for one arm.
class ArmMovementTracker {
  ArmMovementTracker({
    this.bufferSize = 3,
    this.flexionThreshold = 45.0,
    this.extensionThreshold = 150.0,
    this.noseTouchDistanceThreshold = 0.35,
    this.minAngleChangeForDetection = 4.0,
  });

  final int bufferSize;
  final double flexionThreshold;
  final double extensionThreshold;
  final double noseTouchDistanceThreshold;
  final double minAngleChangeForDetection;

  final List<double> _angleBuffer = [];
  LandmarkPoint? _index;
  LandmarkPoint? _nose;
  LandmarkPoint? _wrist;

  bool _readyForTargetTouch = false;
  bool _targetTouchRegistered = false;

  double get latestAngle => _angleBuffer.isEmpty ? 0 : _angleBuffer.last;

  void updateFromLandmarks({
    required LandmarkPoint shoulder,
    required LandmarkPoint elbow,
    required LandmarkPoint wrist,
    required LandmarkPoint index,
    required LandmarkPoint nose,
  }) {
    _index = index;
    _nose = nose;
    _wrist = wrist;
    update(
      computeElbowAngle(
        shoulder: [shoulder.x, shoulder.y, shoulder.z],
        elbow: [elbow.x, elbow.y, elbow.z],
        wrist: [wrist.x, wrist.y, wrist.z],
      ),
    );
  }

  void update(double angle) {
    _angleBuffer.add(angle);
    if (_angleBuffer.length > bufferSize) {
      _angleBuffer.removeAt(0);
    }
  }

  bool isNoseTouch() {
    if (_angleBuffer.length < 2 || _wrist == null || _nose == null) {
      return false;
    }
    final dx = _wrist!.x - _nose!.x;
    final dy = _wrist!.y - _nose!.y;
    final dz = _wrist!.z - _nose!.z;
    // Landmarks already normalised 0..1; divide by √2 diagonal of unit square.
    final distance = math.sqrt(dx * dx + dy * dy + dz * dz) / math.sqrt(2);
    final angle = _angleBuffer.last;
    final touching =
        distance < noseTouchDistanceThreshold && angle < flexionThreshold;
    if (touching) {
      _readyForTargetTouch = true;
      _targetTouchRegistered = false;
    }
    return touching;
  }

  bool isTargetTouch() {
    if (_angleBuffer.length < 2 || _index == null) return false;
    if (!_readyForTargetTouch || _targetTouchRegistered) return false;
    final curr = _angleBuffer.last;
    final wellExtended = curr > extensionThreshold;
    if (wellExtended) {
      _targetTouchRegistered = true;
      _readyForTargetTouch = false;
    }
    return wellExtended;
  }

  bool isExtending() {
    if (_angleBuffer.length < 2) return false;
    final prev = _angleBuffer[_angleBuffer.length - 2];
    final curr = _angleBuffer.last;
    return curr > prev &&
        (curr - prev) > minAngleChangeForDetection &&
        curr < extensionThreshold;
  }

  bool isFlexioning() {
    if (_angleBuffer.length < 2) return false;
    final prev = _angleBuffer[_angleBuffer.length - 2];
    final curr = _angleBuffer.last;
    return prev > extensionThreshold &&
        curr < prev &&
        (prev - curr).abs() > minAngleChangeForDetection;
  }

  void reset() {
    _angleBuffer.clear();
    _readyForTargetTouch = false;
    _targetTouchRegistered = false;
  }

  static double computeElbowAngle({
    required List<double> shoulder,
    required List<double> elbow,
    required List<double> wrist,
  }) {
    final ax = shoulder[0] - elbow[0];
    final ay = shoulder[1] - elbow[1];
    final bx = wrist[0] - elbow[0];
    final by = wrist[1] - elbow[1];
    final dot = ax * bx + ay * by;
    final magA = math.sqrt(ax * ax + ay * ay);
    final magB = math.sqrt(bx * bx + by * by);
    if (magA == 0 || magB == 0) return 0;
    final cosAngle = (dot / (magA * magB)).clamp(-1.0, 1.0);
    return math.acos(cosAngle) * (180 / math.pi);
  }
}
