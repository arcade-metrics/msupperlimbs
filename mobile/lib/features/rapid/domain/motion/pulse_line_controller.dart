import 'dart:collection';

import 'package:msupperlimbs/features/rapid/data/models/rapid_settings.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/pulse_line_state.dart';

/// Sliding-window pulse height simulation driven by taps + gravity.
///
/// Pure domain (no Flutter widgets). UI listens via [onTick] / [onImpulse].
class PulseLineController {
  PulseLineController({
    this.maxPoints = 420,
    this.minY = 0.0,
    this.maxY = 1.0,
    this.baseline = 0.25,
    this.gravityPerSecond = 0.35,
    this.impulseStrength = 0.06,
    this.floorRestitution = 0.0,
    double decayRateIdle = 0.05,
    double decayRateActive = 0.03,
    double decayRateUnstable = 0.07,
    double decayRateFlatline = 0.10,
    PulseLineState initialState = PulseLineState.idle,
  }) : _decayRateIdle = decayRateIdle,
       _decayRateActive = decayRateActive,
       _decayRateUnstable = decayRateUnstable,
       _decayRateFlatline = decayRateFlatline,
       _points = Queue<double>(),
       _currentY = baseline,
       _state = initialState {
    for (var i = 0; i < maxPoints; i++) {
      _points.add(baseline);
    }
  }

  factory PulseLineController.fromSettings(RapidSettings settings) {
    return PulseLineController(
      maxPoints: settings.maxPoints,
      minY: settings.minY,
      maxY: settings.maxY,
      baseline: settings.baseline,
      gravityPerSecond: settings.gravityPerSecond,
      impulseStrength: settings.impulseStrength,
      floorRestitution: settings.floorRestitution,
      decayRateIdle: settings.decayRateIdle,
      decayRateActive: settings.decayRateActive,
      decayRateUnstable: settings.decayRateUnstable,
      decayRateFlatline: settings.decayRateFlatline,
    );
  }

  final int maxPoints;
  final double minY;
  final double maxY;
  final double baseline;
  final double gravityPerSecond;
  final double impulseStrength;
  final double floorRestitution;

  final double _decayRateIdle;
  final double _decayRateActive;
  final double _decayRateUnstable;
  final double _decayRateFlatline;

  final Queue<double> _points;
  double _currentY;
  PulseLineState _state;

  void Function(double height, PulseLineState state, String eventType)?
  onStateChange;
  void Function(double heightBefore, double heightAfter, double impulse)?
  onImpulse;
  void Function()? onTick;

  List<double> get points => _points.toList(growable: false);
  PulseLineState get state => _state;
  double get currentY => _currentY;

  set state(PulseLineState newState) {
    if (_state == newState) return;
    _state = newState;
    onStateChange?.call(_currentY, newState, 'state_change');
    onTick?.call();
  }

  /// Advance simulation by [dtSeconds].
  void tick(double dtSeconds) {
    if (dtSeconds <= 0) {
      _pushPoint(_currentY);
      onTick?.call();
      return;
    }

    final heightBefore = _currentY;
    final extra = _state.getDecayRate(
      idleRate: _decayRateIdle,
      activeRate: _decayRateActive,
      unstableRate: _decayRateUnstable,
      flatlineRate: _decayRateFlatline,
    );
    _currentY -= (gravityPerSecond + extra) * dtSeconds;

    if (_currentY < minY) {
      _currentY = minY + (baseline - minY) * floorRestitution;
    } else if (_currentY > maxY) {
      _currentY = maxY;
    }

    _pushPoint(_currentY);

    if ((heightBefore - _currentY).abs() > 0.001) {
      onStateChange?.call(_currentY, _state, 'tick');
    }
    onTick?.call();
  }

  /// Apply an upward impulse (call when a finger tap fires).
  void impulse([double? strength]) {
    final heightBefore = _currentY;
    final up = strength ?? impulseStrength;
    _currentY = (_currentY + up).clamp(minY, maxY);
    _pushPoint(_currentY);
    onImpulse?.call(heightBefore, _currentY, up);
    onStateChange?.call(_currentY, _state, 'impulse');
    onTick?.call();
  }

  void update(double value) {
    _currentY = value.clamp(minY, maxY);
    _pushPoint(_currentY);
    onTick?.call();
  }

  void reset({double? to}) {
    _currentY = to ?? baseline;
    _points.clear();
    for (var i = 0; i < maxPoints; i++) {
      _points.add(_currentY);
    }
    onTick?.call();
  }

  void _pushPoint(double y) {
    _points.add(y);
    while (_points.length > maxPoints) {
      _points.removeFirst();
    }
  }
}
