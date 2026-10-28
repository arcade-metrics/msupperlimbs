import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/distance_utils.dart';

class ArmMovementTracker {
  final int bufferSize;
  final double flexionThreshold; // e.g. 35°
  final double extensionThreshold; // e.g. 160°
  final double noseTouchDistanceThreshold;
  Size? _imageSize; // Normalised image size from ML Kit
  PoseLandmark? _index;
  PoseLandmark? _nose;
  PoseLandmark? _wrist;

  /// Minimum angular change (in degrees) required to detect meaningful transitions
  final double minAngleChangeForDetection;

  final List<double> _angleBuffer = [];
  String? _lastDirection;

  bool _readyForTargetTouch = false;
  bool _targetTouchRegistered = false;

  ArmMovementTracker({
    required this.bufferSize,
    required this.flexionThreshold,
    required this.extensionThreshold,
    required this.noseTouchDistanceThreshold,
    required this.minAngleChangeForDetection,
  });

  void update(double angle) {
    if (_angleBuffer.isNotEmpty) {
      final prev = _angleBuffer.last;
      final dir = angle > prev ? 'increasing' : 'decreasing';
      _lastDirection = dir;
    }

    _angleBuffer.add(angle);
    if (_angleBuffer.length > bufferSize) {
      _angleBuffer.removeAt(0);
    }

    debugPrint(
        'ArmMovementTracker: Updated angle: ${angle.toStringAsFixed(1)}°, buffer size: ${_angleBuffer.length}');
  }

  void updateFromLandmarks({
    required PoseLandmark shoulder,
    required PoseLandmark elbow,
    required PoseLandmark wrist,
    required PoseLandmark index,
    required PoseLandmark nose,
    required Size imageSize,
  }) {
    _index = index;
    _nose = nose;
    _wrist = wrist;
    _imageSize = imageSize;

    final angle = computeElbowAngle(
      shoulder: [shoulder.x, shoulder.y, shoulder.z],
      elbow: [elbow.x, elbow.y, elbow.z],
      wrist: [wrist.x, wrist.y, wrist.z],
    );

    debugPrint('Shoulder: ${shoulder.x}, ${shoulder.y}, ${shoulder.z}');
    debugPrint('Elbow: ${elbow.x}, ${elbow.y}, ${elbow.z}');
    debugPrint('Wrist: ${wrist.x}, ${wrist.y}, ${wrist.z}');
    debugPrint('Update: angle = ${angle.toStringAsFixed(1)}°');

    update(angle);
  }

  bool isNoseTouch() {
    if (_angleBuffer.length < 2 || _wrist == null || _nose == null)
      return false;

    final dx = _wrist!.x - _nose!.x;
    final dy = _wrist!.y - _nose!.y;
    final dz = _wrist!.z - _nose!.z;
    final distance = normaliseDistance(dx, dy, dz, _imageSize!);

    final angle = _angleBuffer.last;
    final isTouching = distance < 0.35 && angle < 45.0;

    if (isTouching) {
      _readyForTargetTouch = true;
      _targetTouchRegistered = false;
    }

    return isTouching;
  }

  bool isTargetTouch() {
    if (_angleBuffer.length < 2 || _index == null || _imageSize == null) {
      debugPrint(
          'isTargetTouch: Early return - buffer: ${_angleBuffer.length}, index: $_index, imageSize: $_imageSize');
      return false;
    }

    if (!_readyForTargetTouch || _targetTouchRegistered) {
      debugPrint(
          'isTargetTouch: Not ready - readyForTargetTouch: $_readyForTargetTouch, targetTouchRegistered: $_targetTouchRegistered');
      return false;
    }

    final curr = _angleBuffer.last;
    final isWellExtended = curr > 150.0;

    debugPrint(
        'isTargetTouch: Current angle: ${curr.toStringAsFixed(1)}°, isWellExtended: $isWellExtended');

    if (isWellExtended) {
      debugPrint(
          'Valid target touch. Elbow angle: ${curr.toStringAsFixed(1)}° (fully extended > 150°)');
      _targetTouchRegistered = true;
      _readyForTargetTouch = false;
    }

    return isWellExtended;
  }

  void reset() {
    debugPrint('ArmMovementTracker: Resetting tracker');
    _angleBuffer.clear();
    _lastDirection = null;
    _readyForTargetTouch = false;
    _targetTouchRegistered = false;
  }

  double get latestAngle => _angleBuffer.isNotEmpty ? _angleBuffer.last : 0.0;

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
    final magA = sqrt(ax * ax + ay * ay);
    final magB = sqrt(bx * bx + by * by);

    final cosAngle = (dot / (magA * magB)).clamp(-1.0, 1.0);
    final angle = acos(cosAngle) * (180 / pi);

    debugPrint('computeElbowAngle: angle = ${angle.toStringAsFixed(1)}°');
    return angle;
  }

  bool isExtending() {
    if (_angleBuffer.length < 2) {
      debugPrint(
          'isExtending: Early return - buffer too small: ${_angleBuffer.length}');
      return false;
    }
    final prev = _angleBuffer[_angleBuffer.length - 2];
    final curr = _angleBuffer.last;

    final isExtending = curr > prev &&
        (curr - prev) > minAngleChangeForDetection &&
        curr < 150.0;

    if (isExtending) {
      debugPrint(
          'Arm extending: ${prev.toStringAsFixed(1)}° -> ${curr.toStringAsFixed(1)}° (change: ${(curr - prev).toStringAsFixed(1)}°)');
    } else {
      debugPrint(
          'isExtending: Not extending - prev: ${prev.toStringAsFixed(1)}°, curr: ${curr.toStringAsFixed(1)}°, change: ${(curr - prev).toStringAsFixed(1)}°, minChange: $minAngleChangeForDetection');
    }
    return isExtending;
  }

  bool isFlexioning() {
    if (_angleBuffer.length < 2) {
      debugPrint(
          'isFlexioning: Early return - buffer too small: ${_angleBuffer.length}');
      return false;
    }
    final prev = _angleBuffer[_angleBuffer.length - 2];
    final curr = _angleBuffer.last;

    final startedExtended = prev > 150.0;
    final isStartFlexing = curr < prev;
    final decreasedEnough = (prev - curr).abs() > minAngleChangeForDetection;

    final isFlexing = startedExtended && isStartFlexing && decreasedEnough;
    if (isFlexing) {
      debugPrint(
          'Arm flexing after extension: ${prev.toStringAsFixed(1)}° -> ${curr.toStringAsFixed(1)}°');
    } else {
      debugPrint(
          'isFlexioning: Not flexing - startedExtended: $startedExtended, isStartFlexing: $isStartFlexing, decreasedEnough: $decreasedEnough');
    }
    return isFlexing;
  }
}
