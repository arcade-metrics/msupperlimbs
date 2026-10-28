import 'dart:math' as math;

import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/mp_tip_index.dart';

/// Normalized fingertip sample (0..1 image space).
class TapLandmark {
  const TapLandmark(this.x, this.y, [this.z]);

  final double x;
  final double y;
  final double? z;

  factory TapLandmark.fromPoint(LandmarkPoint p) => TapLandmark(p.x, p.y, p.z);
}

/// Fires once when any non-thumb tip crosses below [dOn] relative to the thumb,
/// with hysteresis ([dOff]) and a global cooldown.
class FingerTapDetector {
  FingerTapDetector({
    this.dOn = 0.040,
    this.dOff = 0.055,
    this.cooldownMs = 110,
    this.use3D = false,
  }) : assert(dOff > dOn, 'dOff must be greater than dOn for hysteresis');

  /// Builds thresholds from persisted Rapid settings.
  ///
  /// `tapSensitivity` já pertence ao espaço A normalizado do MediaPipe.
  factory FingerTapDetector.fromSettings(
    RapidSettings settings, {
    bool use3D = false,
  }) {
    final dOn = settings.tapSensitivity;
    return FingerTapDetector(
      dOn: dOn,
      dOff: dOn * (0.055 / 0.040),
      cooldownMs: settings.tapCooldownMs,
      use3D: use3D,
    );
  }

  final double dOn;
  final double dOff;
  final int cooldownMs;
  final bool use3D;

  final Map<int, bool> _isClose = {
    MpTipIndex.index: false,
    MpTipIndex.middle: false,
    MpTipIndex.ring: false,
    MpTipIndex.pinky: false,
  };

  DateTime? _lastTapAt;

  /// Which tip indices are currently considered "close" (for debug/UI).
  Map<int, bool> get closeFlags => Map.unmodifiable(_isClose);

  DateTime? get lastTapAt => _lastTapAt;

  /// Returns `true` only on the frame where a new tap is registered.
  bool update(Map<int, TapLandmark> landmarks, DateTime now) {
    final thumb = landmarks[MpTipIndex.thumb];
    if (thumb == null) return false;

    var firedThisFrame = false;

    for (final tip in MpTipIndex.nonThumbTips) {
      final lm = landmarks[tip];
      if (lm == null) {
        _isClose[tip] = false;
        continue;
      }

      final dist = _distance(thumb, lm);
      final wasClose = _isClose[tip] ?? false;
      final isCloseNow = wasClose ? dist < dOff : dist < dOn;

      if (!wasClose && isCloseNow && _canFire(now)) {
        firedThisFrame = true;
        _lastTapAt = now;
      }

      _isClose[tip] = isCloseNow;
    }

    return firedThisFrame;
  }

  /// Convenience: build tip map from a single hand's [LandmarkPoint] list.
  bool updateFromPoints(List<LandmarkPoint> handPoints, DateTime now) {
    final map = <int, TapLandmark>{};
    for (final p in handPoints) {
      if (p.index == MpTipIndex.thumb ||
          MpTipIndex.nonThumbTips.contains(p.index)) {
        map[p.index] = TapLandmark.fromPoint(p);
      }
    }
    return update(map, now);
  }

  void reset() {
    for (final k in _isClose.keys) {
      _isClose[k] = false;
    }
    _lastTapAt = null;
  }

  bool _canFire(DateTime now) {
    if (_lastTapAt == null) return true;
    return now.difference(_lastTapAt!).inMilliseconds >= cooldownMs;
  }

  double _distance(TapLandmark a, TapLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    if (use3D && a.z != null && b.z != null) {
      final dz = a.z! - b.z!;
      return math.sqrt(dx * dx + dy * dy + dz * dz);
    }
    return math.sqrt(dx * dx + dy * dy);
  }
}
