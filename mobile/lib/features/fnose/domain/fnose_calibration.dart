import 'package:msupperlimbs/features/fnose/domain/fnose_types.dart';

/// `protocolCode` of the FNose setup (`MSUPPERLIMBS-API.md` §5): five steps,
/// device still → roll → pitch → nose → index finger.
const fnoseCalibrationProtocol = 'device-body-setup/v1';

/// What the engine saw of one setup phase, on the run clock.
class SetupStepRecord {
  SetupStepRecord(this.phase, this.startedMs);

  final FnoseGamePhase phase;
  final int startedMs;
  int attempts = 1;
  bool passed = false;
  int? endedMs;

  /// Hold that completed the step.
  int heldMs = 0;

  /// Means of the tracked value(s) during that hold: roll or pitch in [meanA]
  /// for the tilt steps, nose x/y (screen fraction) for the nose step.
  double? meanA;
  double? meanB;
}

/// One setup run ready for `/api/v1/calibrations`, built when the pre-game
/// closes. Bodies are camelCase as the API takes them.
class FnoseCalibrationRun {
  const FnoseCalibrationRun({
    required this.completed,
    required this.startedOffsetMs,
    required this.endedOffsetMs,
    required this.context,
    required this.sensorSamples,
    required this.poseFrames,
    required this.events,
    required this.steps,
    this.result,
  });

  final bool completed;
  final int startedOffsetMs;
  final int endedOffsetMs;

  /// Capture fields of the open request (screen, image, preview, settings).
  final Map<String, dynamic> context;
  final List<Map<String, dynamic>> sensorSamples;
  final List<Map<String, dynamic>> poseFrames;
  final List<Map<String, dynamic>> events;

  /// Reached steps in protocol order.
  final List<Map<String, dynamic>> steps;

  /// What the game consumes (the finger offset); only on completed runs.
  final Map<String, dynamic>? result;

  Map<String, dynamic> get openBody => {
    'protocolCode': fnoseCalibrationProtocol,
    'startedOffsetMs': startedOffsetMs,
    ...context,
  };

  Map<String, dynamic> get finishBody => {
    'status': completed ? 'COMPLETED' : 'ABANDONED',
    'endedOffsetMs': endedOffsetMs,
    'steps': steps,
    'result': ?result,
  };
}
