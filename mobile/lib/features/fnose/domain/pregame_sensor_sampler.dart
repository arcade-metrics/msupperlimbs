import 'dart:async';
import 'package:flutter/services.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings.dart';
import 'package:msupperlimbs/features/fnose/domain/device_attitude.dart';
import 'package:msupperlimbs/features/fnose/domain/pregame_telemetry_buffer.dart';
import 'package:msupperlimbs/features/motion/domain/session_clock.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Accelerometer (+ optional gyro) feeder for [PregameTelemetryBuffer].
/// Uses the buffer clock so sensor rows share `t` with pose/events.
class PregameSensorSampler {
  PregameSensorSampler(
    this._buffer, {
    required FnoseAdvSettings settings,
    required this.clock,
    required this.orientation,
    this.onTick,
  }) : _filter = DeviceAttitudeFilter(
         alpha: settings.d('alpha', 0.3),
         stabilityThreshold: settings.d('stability_threshold', 0.5),
       );

  final PregameTelemetryBuffer _buffer;
  final DeviceOrientation Function() orientation;
  final DeviceAttitudeFilter _filter;
  final SessionClock clock;
  final void Function({
    required bool still,
    required double pitch,
    required double roll,
    required DateTime now,
  })?
  onTick;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double? _gx;
  double? _gy;
  double? _gz;
  bool _deviceStill = false;
  double _pitch = 0;
  double _roll = 0;

  bool get deviceStill => _deviceStill;
  double get pitch => _pitch;
  double get roll => _roll;

  void start() {
    stop();
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onAccel);
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onGyro);
  }

  void stop() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
  }

  void _onGyro(GyroscopeEvent e) {
    _gx = e.x;
    _gy = e.y;
    _gz = e.z;
  }

  void _onAccel(AccelerometerEvent e) {
    final now = clock.now();
    final attitude = _filter.update(
      x: e.x,
      y: e.y,
      z: e.z,
      orientation: orientation(),
    );
    _deviceStill = attitude.still;
    _pitch = attitude.pitch;
    _roll = attitude.roll;

    _buffer.addSensor(
      ax: e.x,
      ay: e.y,
      az: e.z,
      gx: _gx,
      gy: _gy,
      gz: _gz,
      angle: _pitch,
      pitch: _pitch,
      roll: _roll,
      at: now,
    );
    onTick?.call(still: _deviceStill, pitch: _pitch, roll: _roll, now: now);
  }
}
