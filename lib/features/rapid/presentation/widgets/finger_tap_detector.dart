import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Indices of tips of fingers in MediaPipe Hands
class MpTipIndex {
  static const int thumb = 4;
  static const int index = 8;
  static const int middle = 12;
  static const int ring = 16;
  static const int pinky = 20;

  static const List<int> nonThumbTips = [index, middle, ring, pinky];
}

/// Minimum expected structure of a normalized landmark (0..1)
/// Se você já tiver um tipo próprio, faça um adapter para fornecer x,y,(z).
class NormalisedLandmark {
  final double x;
  final double y;
  final double? z; // optional
  const NormalisedLandmark(this.x, this.y, [this.z]);
}

/// Detector: fires 1x when ANY tip (8/12/16/20) crosses below dOn
/// em relação ao polegar (4), com histerese (dOff) e cooldown global.
class FingerTapDetector {
  // ===== Parameters (can come from Settings later) =====
  final double dOn;        // limiar de "encostou" (menor = mais exigente)
  final double dOff;       // limiar de "desencostou" (maior que dOn)
  final int cooldownMs;    // tempo mínimo entre taps (qualquer dedo)
  final bool use3D;        // se true e z disponível, usa distância 3D

  // ===== Internal state =====
  final Map<int, bool> _isClose = {
    MpTipIndex.index: false,
    MpTipIndex.middle: false,
    MpTipIndex.ring: false,
    MpTipIndex.pinky: false,
  };
  DateTime? _lastTapAt;

  FingerTapDetector({
    this.dOn = 0.040,      // ~4% of normalized width/height
    this.dOff = 0.055,     // hysteresis (greater than dOn)
    this.cooldownMs = 100, // 100–120 ms funciona bem
    this.use3D = false,
  }) : assert(dOff > dOn, 'dOff must be greater than dOn for hysteresis');

  /// Updates with landmarks from the frame. Returns true ONLY on the frame of the shot.
  ///
  /// `landmarks` deve conter pelo menos os índices das TIPS do polegar e dos outros dedos.
  bool update(Map<int, NormalisedLandmark> landmarks, DateTime now) {
    // Checagens básicas
    final thumb = landmarks[MpTipIndex.thumb];
    if (thumb == null) return false;

    bool firedThisFrame = false;

    for (final tip in MpTipIndex.nonThumbTips) {
      final lm = landmarks[tip];
      if (lm == null) {
        // If this finger is missing, consider it "not close" to avoid locking the state
        _isClose[tip] = false;
        continue;
      }

      final dist = _distance(thumb, lm);
      final wasClose = _isClose[tip] ?? false;

      // Hysteresis: enter below dOn; exit above dOff
      final bool isCloseNow = wasClose
          ? (dist < dOff)
          : (dist < dOn);

      // Edge transition: false -> true  => candidate for tap
      if (!wasClose && isCloseNow) {
        final canFire = _canFire(now);
        if (canFire) {
          firedThisFrame = true;
          _lastTapAt = now;
        }
      }

      _isClose[tip] = isCloseNow;
    }

    return firedThisFrame;
  }

  void reset() {
    for (final k in _isClose.keys) {
      _isClose[k] = false;
    }
    _lastTapAt = null;
  }

  bool _canFire(DateTime now) {
    if (_lastTapAt == null) return true;
    final elapsed = now.difference(_lastTapAt!).inMilliseconds;
    return elapsed >= cooldownMs;
  }

  double _distance(NormalisedLandmark a, NormalisedLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    if (use3D && a.z != null && b.z != null) {
      final dz = (a.z!) - (b.z!);
      return math.sqrt(dx*dx + dy*dy + dz*dz);
    }
    return math.sqrt(dx*dx + dy*dy);
  }
}
