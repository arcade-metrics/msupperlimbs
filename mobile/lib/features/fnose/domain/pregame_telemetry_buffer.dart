import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';
import 'package:msupperlimbs/features/motion/domain/session_clock.dart';

/// Single-clock pregame telemetry buffer.
///
/// All pose samples, sensor samples and trigger events share the run
/// timeline via [offsetMs] (ms since `SessionClock.startedAt`, no epoch).
class PregameTelemetryBuffer {
  PregameTelemetryBuffer({
    required this.clock,
    this.poseMinIntervalMs = 0,
    this.sensorMinIntervalMs = 50,
  });

  final SessionClock clock;
  final int poseMinIntervalMs;
  final int sensorMinIntervalMs;

  bool _active = false;
  int? _startedOffsetMs;
  int? _endedOffsetMs;
  int? _lastPoseMs;
  int? _lastSensorMs;

  final List<Map<String, dynamic>> poseSamples = [];
  final List<Map<String, dynamic>> sensorSamples = [];
  final List<Map<String, dynamic>> events = [];

  bool get isActive => _active;
  int? get startedOffsetMs => _startedOffsetMs;
  int? get endedOffsetMs => _endedOffsetMs;

  /// Canonical clock for every sample/event in this run.
  int offsetMs([DateTime? at]) => clock.offsetMs(at);

  void start({DateTime? at}) {
    if (_active) return;
    _active = true;
    _startedOffsetMs = offsetMs(at);
    _endedOffsetMs = null;
    poseSamples.clear();
    sensorSamples.clear();
    events.clear();
    _lastPoseMs = null;
    _lastSensorMs = null;
    addEvent('calibration_start', at: at);
  }

  void addPose(List<LandmarkPoint> pose, {DateTime? at}) {
    if (!_active) return;
    final t = offsetMs(at);
    final last = _lastPoseMs;
    if (last != null && t - last < poseMinIntervalMs) return;
    _lastPoseMs = t;
    poseSamples.add({
      'offsetMs': t,
      'pose': [for (final p in pose) p.toKinematicJson()],
    });
  }

  void addSensor({
    required double ax,
    required double ay,
    required double az,
    double? gx,
    double? gy,
    double? gz,
    double? angle,
    double? pitch,
    double? roll,
    DateTime? at,
  }) {
    if (!_active) return;
    final t = offsetMs(at);
    final last = _lastSensorMs;
    if (last != null && t - last < sensorMinIntervalMs) return;
    _lastSensorMs = t;
    sensorSamples.add({
      'offsetMs': t,
      'ax': ax,
      'ay': ay,
      'az': az,
      'gx': ?gx,
      'gy': ?gy,
      'gz': ?gz,
      'angle': ?angle,
      'pitch': ?pitch,
      'roll': ?roll,
    });
  }

  void addEvent(String type, {Map<String, dynamic>? data, DateTime? at}) {
    if (!_active && type != 'calibration_start') return;
    events.add({'offsetMs': offsetMs(at), 'type': type, 'data': ?data});
  }

  /// Setup phase change (deviceStill … calibrateFinger) on the run timeline.
  void addPhase({String? from, required String to, DateTime? at}) {
    addEvent('phase', data: {'fromPhase': ?from, 'toPhase': to}, at: at);
  }

  void setCalibrationOffset(
    double dx,
    double dy, {
    double? fingerX,
    double? fingerY,
    double? targetX,
    double? targetY,
    DateTime? at,
  }) {
    addEvent(
      'target_calibrated',
      data: {
        'finger': {'x': ?fingerX, 'y': ?fingerY},
        'target': {'x': ?targetX, 'y': ?targetY},
        'offset': {'dx': dx, 'dy': dy},
      },
      at: at,
    );
  }

  /// Closes the window with a final `game_start` (or `abandoned`) event.
  /// Later samples and events are ignored; closing twice does nothing.
  void close({bool abandoned = false, DateTime? at}) {
    if (!_active) return;
    addEvent(abandoned ? 'abandoned' : 'game_start', at: at);
    _endedOffsetMs = offsetMs(at);
    _active = false;
  }
}
