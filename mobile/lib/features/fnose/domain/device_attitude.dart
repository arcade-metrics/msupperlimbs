import 'dart:math' as math;

import 'package:flutter/services.dart';

class DeviceAttitude {
  const DeviceAttitude({
    required this.still,
    required this.pitch,
    required this.roll,
  });

  final bool still;
  final double pitch;
  final double roll;
}

/// Converte gravidade nos eixos físicos em inclinação relativa ao ecrã.
class DeviceAttitudeFilter {
  DeviceAttitudeFilter({required this.alpha, required this.stabilityThreshold});

  final double alpha;
  final double stabilityThreshold;
  double? _lastX;
  double? _lastY;
  double? _lastZ;
  double? _movement;

  DeviceAttitude update({
    required double x,
    required double y,
    required double z,
    required DeviceOrientation orientation,
  }) {
    if (_lastX != null) {
      final dx = x - _lastX!;
      final dy = y - _lastY!;
      final dz = z - _lastZ!;
      final instant = math.sqrt(dx * dx + dy * dy + dz * dz);
      _movement = _movement == null
          ? instant
          : alpha * instant + (1 - alpha) * _movement!;
    }
    _lastX = x;
    _lastY = y;
    _lastZ = z;

    final screenX = orientation == DeviceOrientation.landscapeRight ? y : -y;
    final screenY = orientation == DeviceOrientation.landscapeRight ? -x : x;
    final roll = math.atan2(screenX, screenY.abs()) * 180 / math.pi;
    final pitch =
        math.atan2(z, math.sqrt(screenX * screenX + screenY * screenY)) *
        180 /
        math.pi;
    return DeviceAttitude(
      still: _movement != null && _movement! < stabilityThreshold,
      pitch: pitch,
      roll: roll,
    );
  }
}
