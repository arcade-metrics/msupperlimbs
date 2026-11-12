import 'dart:ui';

import 'package:msupperlimbs/features/fnose/data/models/fnose_settings.dart';
import 'package:msupperlimbs/features/fnose/domain/arm_movement_tracker.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_calibration.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_types.dart';
import 'package:msupperlimbs/features/fnose/domain/pregame_telemetry_buffer.dart';
import 'package:msupperlimbs/features/match/domain/event_timeline.dart';
import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';
import 'package:msupperlimbs/features/motion/domain/motion_data_contract.dart';
import 'package:msupperlimbs/features/motion/domain/screen_mapper.dart';
import 'package:msupperlimbs/features/motion/domain/session_clock.dart';

class FnoseGameEngine {
  FnoseGameEngine({
    required FnoseSettings settings,
    required FnoseAdvSettings adv,
    required SessionClock clock,
    this.poseSampleEveryNFrames = 1,
    this._onChanged,
  }) : _settings = settings,
       _adv = adv,
       _clock = clock,
       telemetry = PregameTelemetryBuffer(clock: clock),
       remainingSeconds = settings.totalTime,
       totalSeconds = settings.totalTime,
       _left = ArmMovementTracker(
         bufferSize: adv.i('landmark_buffer_size', 3),
         flexionThreshold: adv.d('elbow_flexion_threshold', 45),
         extensionThreshold: adv.d('elbow_extension_threshold', 150),
         noseTouchDistanceThreshold: adv.d(
           'nose_touch_distance_threshold',
           0.35,
         ),
         minAngleChangeForDetection: adv.d(
           'min_angle_change_for_elbow_detection',
           4,
         ),
       ),
       _right = ArmMovementTracker(
         bufferSize: adv.i('landmark_buffer_size', 3),
         flexionThreshold: adv.d('elbow_flexion_threshold', 45),
         extensionThreshold: adv.d('elbow_extension_threshold', 150),
         noseTouchDistanceThreshold: adv.d(
           'nose_touch_distance_threshold',
           0.35,
         ),
         minAngleChangeForDetection: adv.d(
           'min_angle_change_for_elbow_detection',
           4,
         ),
       ) {
    telemetry.start();
    telemetry.addPhase(to: phase.name);
    _enterStep(phase, _clock.now());
  }

  final FnoseSettings _settings;
  final FnoseAdvSettings _adv;
  final SessionClock _clock;
  final int poseSampleEveryNFrames;
  final void Function()? _onChanged;

  final ArmMovementTracker _left;
  final ArmMovementTracker _right;
  final PregameTelemetryBuffer telemetry;

  FnoseGamePhase phase = FnoseGamePhase.deviceStill;
  FnoseSparkState leftSpark = FnoseSparkState.idle;
  FnoseSparkState rightSpark = FnoseSparkState.idle;

  int remainingSeconds;
  final int totalSeconds;
  int leftSparks = 0;
  int rightSparks = 0;
  bool deviceStill = false;
  double pitch = 0;
  double roll = 0;
  bool noseInside = false;
  Offset? nosePosition;
  bool fingerInside = false;
  Offset? fingerPosition;
  Offset? fingerCalibrationOffset;
  Offset? calibratedFingerPosition;
  Offset? calibrationTargetPosition;

  /// `/calibrations` run of this pre-game, once uploaded.
  String? calibrationRunId;

  int? screenWidth;
  int? screenHeight;
  int? imageWidth;
  int? imageHeight;

  /// Área ocupada pela pré-visualização no ecrã, medida em layout.
  Rect? previewRect;

  DateTime? _holdStartedAt;
  DateTime? _lastHoldSampleAt;
  DateTime? _unstableSince;
  int _poseFrameCounter = 0;
  Offset? _fingerSmoothed;
  DateTime? _fingerOutsideSince;
  bool _pregameClosed = false;

  /// Setup steps reached so far, in the order first entered.
  final _steps = <FnoseGamePhase, SetupStepRecord>{};
  double _holdSumA = 0;
  double _holdSumB = 0;
  int _holdSamples = 0;

  DateTime? _leftFireUntil;
  DateTime? _rightFireUntil;
  int? _playingStartedMs;
  int? _finishedMs;

  /// `countdown`, `playing` e `finished`; as fases de setup ficam em
  /// [telemetry] (calibração).
  final List<Map<String, dynamic>> _phaseEvents = [];
  final List<Map<String, dynamic>> _poseSamples = [];
  final List<Map<String, dynamic>> _sparkEvents = [];
  final List<Map<String, dynamic>> _hitEvents = [];
  final List<double> _angles = [];
  final List<double> _distances = [];

  OffsetMark? lastHitMark;
  bool? lastHitValid;

  FnoseSettings get settings => _settings;
  FnoseAdvSettings get adv => _adv;
  int get totalSparks => leftSparks + rightSparks;

  bool get isPregame => phase.index <= FnoseGamePhase.calibrateFinger.index;

  int _holdRequiredMs(FnoseGamePhase target) => switch (target) {
    FnoseGamePhase.deviceStill => _adv.i('required_stable_time_ms', 2500),
    FnoseGamePhase.deviceRoll ||
    FnoseGamePhase.devicePitch => _adv.i('tilt_hold_ms', 700),
    FnoseGamePhase.alignNose => _adv.i('nose_hold_ms', 1200),
    FnoseGamePhase.calibrateFinger => _adv.i('finger_hold_ms', 1200),
    _ => 0,
  };

  /// Progresso somado de todo o pré-jogo, para a barra não zerar entre fases.
  double get holdProgress {
    if (!isPregame) return 1;
    var total = 0;
    var done = 0;
    for (final candidate in FnoseGamePhase.values) {
      if (candidate.index > FnoseGamePhase.calibrateFinger.index) break;
      final required = _holdRequiredMs(candidate);
      total += required;
      if (candidate.index < phase.index) {
        done += required;
      } else if (candidate == phase && _holdStartedAt != null) {
        final sample = _lastHoldSampleAt ?? _holdStartedAt!;
        final elapsed = sample.difference(_holdStartedAt!).inMilliseconds;
        done += elapsed.clamp(0, required);
      }
    }
    return total == 0 ? 0 : (done / total).clamp(0.0, 1.0);
  }

  /// Tempo jogado de verdade: da fase `playing` até `finished` (ou agora).
  int get playedMs {
    final started = _playingStartedMs;
    if (started == null) return 0;
    return (_finishedMs ?? _clock.offsetMs()) - started;
  }

  FnoseGameResult get result {
    final avgAngle = _angles.isEmpty
        ? null
        : _angles.reduce((a, b) => a + b) / _angles.length;
    final avgDistance = _distances.isEmpty
        ? null
        : _distances.reduce((a, b) => a + b) / _distances.length;
    return FnoseGameResult(
      totalTime: totalSeconds,
      durationMs: playedMs,
      gameMode: _settings.gameMode,
      totalLeftSparks: leftSparks,
      totalRightSparks: rightSparks,
      totalSparks: totalSparks,
      avgDistance: avgDistance,
      avgAngle: avgAngle,
      phaseEvents: List.unmodifiable(_phaseEvents),
      poseSamples: List.unmodifiable(_poseSamples),
      sparkEvents: List.unmodifiable(_sparkEvents),
      hitEvents: List.unmodifiable(_hitEvents),
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      calibrationRunId: calibrationRunId,
      preview: _mapper?.normalizedPreview,
    );
  }

  void notify() => _onChanged?.call();

  static bool _isSetup(FnoseGamePhase p) =>
      p.index <= FnoseGamePhase.calibrateFinger.index;

  void _setPhase(FnoseGamePhase next, DateTime at) {
    if (next == phase) return;
    if (_isSetup(phase) && next.index > phase.index) _passStep(phase, at);
    if (_isSetup(next)) _enterStep(next, at);
    if (next.index <= FnoseGamePhase.calibrateFinger.index) {
      telemetry.addPhase(from: phase.name, to: next.name, at: at);
    } else {
      _phaseEvents.add(
        phaseEvent(
          offsetMs: _clock.offsetMs(at),
          from: phase.name,
          to: next.name,
        ),
      );
    }
    phase = next;
  }

  void _enterStep(FnoseGamePhase step, DateTime at) {
    final seen = _steps[step];
    if (seen == null) {
      _steps[step] = SetupStepRecord(step, _clock.offsetMs(at));
      return;
    }
    seen
      ..attempts += 1
      ..passed = false
      ..endedMs = null;
  }

  /// Called before [_resetHold], while the completing hold is still known.
  void _passStep(FnoseGamePhase step, DateTime at) {
    final record = _steps[step];
    if (record == null) return;
    final holdStart = _holdStartedAt;
    record
      ..passed = true
      ..endedMs = _clock.offsetMs(at)
      ..heldMs = holdStart == null ? 0 : at.difference(holdStart).inMilliseconds
      ..meanA = _holdSamples == 0 ? null : _holdSumA / _holdSamples
      ..meanB = _holdSamples == 0 ? null : _holdSumB / _holdSamples;
  }

  void _sampleHold(double a, [double b = 0]) {
    _holdSumA += a;
    _holdSumB += b;
    _holdSamples += 1;
  }

  /// Sensor tick from [PregameSensorSampler] — same wall clock as pose/events.
  void onSensorStatus({
    required bool still,
    required double pitch,
    required double roll,
    required DateTime now,
  }) {
    deviceStill = still;
    this.pitch = pitch;
    this.roll = roll;
    if (!isPregame) {
      notify();
      return;
    }

    if (!still) {
      _unstableSince ??= now;
      final graceMs = _adv.i('stability_grace_ms', 400);
      if (now.difference(_unstableSince!).inMilliseconds < graceMs) {
        notify();
        return;
      }
      if (phase != FnoseGamePhase.deviceStill) {
        _setPhase(FnoseGamePhase.deviceStill, now);
        telemetry.addEvent('stability_lost', at: now);
      }
      _resetHold();
      notify();
      return;
    }
    _unstableSince = null;

    switch (phase) {
      case FnoseGamePhase.deviceStill:
        _startOrContinueHold(now);
        if (_holdReached(_adv.i('required_stable_time_ms', 2500), now)) {
          _setPhase(FnoseGamePhase.deviceRoll, now);
          _resetHold();
          telemetry.addEvent('stability_ok', at: now);
        }
        notify();
      case FnoseGamePhase.deviceRoll:
        final ok =
            roll >= _adv.d('roll_min_deg', -8) &&
            roll <= _adv.d('roll_max_deg', 8);
        if (!ok) {
          _resetHold();
        } else {
          _startOrContinueHold(now);
          _sampleHold(roll);
          if (_holdReached(_adv.i('tilt_hold_ms', 700), now)) {
            _setPhase(FnoseGamePhase.devicePitch, now);
            _resetHold();
          }
        }
        notify();
      case FnoseGamePhase.devicePitch:
        final ok =
            pitch >= _adv.d('pitch_min_deg', -12) &&
            pitch <= _adv.d('pitch_max_deg', 12);
        if (!ok) {
          _resetHold();
        } else {
          _startOrContinueHold(now);
          _sampleHold(pitch);
          if (_holdReached(_adv.i('tilt_hold_ms', 700), now)) {
            _setPhase(FnoseGamePhase.alignNose, now);
            _resetHold();
          }
        }
        notify();
      default:
        notify();
    }
  }

  void onPose(List<LandmarkPoint> pose, DateTime now) {
    final byIndex = <int, LandmarkPoint>{for (final p in pose) p.index: p};
    if (isPregame || phase == FnoseGamePhase.countdown) {
      telemetry.addPose(pose, at: now);
    }

    switch (phase) {
      case FnoseGamePhase.deviceStill:
      case FnoseGamePhase.deviceRoll:
      case FnoseGamePhase.devicePitch:
        break;
      case FnoseGamePhase.alignNose:
        final mapper = _mapper;
        final nose = byIndex[PoseIdx.nose];
        if (mapper == null || nose == null) {
          noseInside = false;
          nosePosition = null;
          _resetHold();
          notify();
          break;
        }
        final point = mapper.toScreen(nose);
        nosePosition = point;
        noseInside =
            mapper.distance(point, noseTargetCenter) <= noseTargetRadius;
        if (!noseInside) {
          _resetHold();
        } else {
          _startOrContinueHold(now);
          _sampleHold(point.dx, point.dy);
          if (_holdReached(_adv.i('nose_hold_ms', 1200), now)) {
            _setPhase(FnoseGamePhase.calibrateFinger, now);
            _resetHold();
            _resetFingerTracking();
            telemetry.addEvent('nose_aligned', at: now);
          }
        }
        notify();
      case FnoseGamePhase.calibrateFinger:
        final mapper = _mapper;
        final isLeft = _settings.gameMode != 'rightHand';
        final finger = byIndex[isLeft ? PoseIdx.leftIndex : PoseIdx.rightIndex];
        if (mapper == null || finger == null) {
          _resetFingerTracking();
          fingerPosition = null;
          _resetHold();
          notify();
          break;
        }
        final point = _smoothFinger(mapper.toScreen(finger));
        fingerPosition = point;
        final target = fingerTargetCenter;
        // Histerese: uma vez dentro, só sai depois de passar a margem.
        final margin = fingerInside ? _adv.d('finger_stability', 0.05) : 0.0;
        final inside =
            mapper.distance(point, target) <= fingerTargetRadius + margin;
        if (inside) {
          _fingerOutsideSince = null;
          fingerInside = true;
        } else {
          _fingerOutsideSince ??= now;
          final graceMs = _adv.i('finger_grace_ms', 400);
          if (now.difference(_fingerOutsideSince!).inMilliseconds >= graceMs) {
            fingerInside = false;
            _resetHold();
            notify();
            break;
          }
        }
        _startOrContinueHold(now);
        if (inside && _holdReached(_adv.i('finger_hold_ms', 1200), now)) {
          calibratedFingerPosition = point;
          calibrationTargetPosition = target;
          fingerCalibrationOffset = target - point;
          telemetry.setCalibrationOffset(
            fingerCalibrationOffset!.dx,
            fingerCalibrationOffset!.dy,
            fingerX: point.dx,
            fingerY: point.dy,
            targetX: target.dx,
            targetY: target.dy,
            at: now,
          );
          _setPhase(FnoseGamePhase.countdown, now);
          _resetHold();
          telemetry.addEvent('countdown_start', at: now);
        }
        notify();
      case FnoseGamePhase.countdown:
      case FnoseGamePhase.finished:
        break;
      case FnoseGamePhase.playing:
        _poseFrameCounter += 1;
        if (_poseFrameCounter % poseSampleEveryNFrames == 0) {
          _samplePose(pose, now);
        }
        _processArms(byIndex, now);
    }
  }

  ScreenMapper? get _mapper {
    final width = screenWidth;
    final height = screenHeight;
    final rect = previewRect;
    if (width == null || height == null || rect == null) return null;
    return ScreenMapper(
      screenSize: Size(width.toDouble(), height.toDouble()),
      previewRect: rect,
    );
  }

  /// Raio aceite/desenhado, em fração do menor lado do ecrã.
  double get noseTargetRadius => _adv.d('nose_alignment_target_radius', 0.07);

  Offset get noseTargetCenter {
    final configuredX = _adv.d('x_nose_alignment', 0.7);
    final x = _settings.gameMode == 'rightHand' ? 1 - configuredX : configuredX;
    return Offset(x, _adv.d('y_nose_alignment', 0.3));
  }

  /// Raio desenhado do alvo, em fração do menor lado: o que se vê é o que valida.
  double get fingerTargetRadius =>
      _adv.d('target_scale', 0.45) *
      _settings.targetSize.clamp(0.5, 2.0) *
      0.5;

  Offset get fingerTargetCenter {
    final mapper = _mapper;
    if (mapper == null) return Offset.zero;
    final halfWidth =
        mapper.radiusToPixels(fingerTargetRadius) / mapper.screenSize.width;
    final xPosition = _adv.d('x_target_position', 0.1);
    final x = _settings.gameMode != 'rightHand'
        ? xPosition + halfWidth
        : 1 - xPosition - halfWidth;
    return Offset(x, _adv.d('y_target_position', 0.5));
  }

  Offset? adjustedFingerPosition(LandmarkPoint finger) {
    final mapper = _mapper;
    if (mapper == null) return null;
    return mapper.toScreen(finger) + (fingerCalibrationOffset ?? Offset.zero);
  }

  /// Filtro passa-baixo do indicador: o tremor da landmark não decide a fase.
  Offset _smoothFinger(Offset point) {
    final alpha = _adv.d('finger_smoothing', 0.35).clamp(0.05, 1.0);
    final previous = _fingerSmoothed;
    final smoothed = previous == null
        ? point
        : previous + (point - previous) * alpha;
    _fingerSmoothed = smoothed;
    return smoothed;
  }

  void _resetFingerTracking() {
    _fingerSmoothed = null;
    _fingerOutsideSince = null;
    fingerInside = false;
  }

  void _startOrContinueHold(DateTime now) {
    _holdStartedAt ??= now;
    _lastHoldSampleAt = now;
  }

  bool _holdReached(int milliseconds, DateTime now) =>
      _holdStartedAt != null &&
      now.difference(_holdStartedAt!).inMilliseconds >= milliseconds;

  void _resetHold() {
    _holdStartedAt = null;
    _lastHoldSampleAt = null;
    _holdSumA = 0;
    _holdSumB = 0;
    _holdSamples = 0;
  }

  /// Closes the pre-game window and returns the run for `/calibrations`
  /// (same `offsetMs` timeline as the match); null if already closed.
  /// [completed] is false when the player leaves during the setup.
  FnoseCalibrationRun? closeCalibration({
    required bool completed,
    DateTime? at,
  }) {
    if (_pregameClosed) return null;
    _pregameClosed = true;
    telemetry.close(abandoned: !completed, at: at);
    final end = telemetry.endedOffsetMs ?? _clock.offsetMs(at);
    final offset = fingerCalibrationOffset;
    return FnoseCalibrationRun(
      completed: completed,
      startedOffsetMs: telemetry.startedOffsetMs ?? end,
      endedOffsetMs: end,
      context: {
        'screenWidth': ?screenWidth,
        'screenHeight': ?screenHeight,
        'imageWidth': ?imageWidth,
        'imageHeight': ?imageHeight,
        'preview': ?_mapper?.normalizedPreview,
        'settingsSnapshot': {..._settings.toUpdateJson(), ..._adv.toApiJson()},
        'dataContractVersion': MotionDataContract.version,
      },
      sensorSamples: List.of(telemetry.sensorSamples),
      poseFrames: List.of(telemetry.poseSamples),
      events: [
        for (final e in telemetry.events)
          {
            'offsetMs': e['offsetMs'],
            'eventType': e['type'],
            'payload': ?e['data'],
          },
      ],
      steps: [
        for (final step
            in _steps.values.toList()
              ..sort((a, b) => a.phase.index.compareTo(b.phase.index)))
          _stepJson(step),
      ],
      result: completed && offset != null
          ? {
              'fingerOffset': {
                'dx': offset.dx,
                'dy': offset.dy,
                'space': 'screen_norm',
              },
            }
          : null,
    );
  }

  Map<String, dynamic> _stepJson(SetupStepRecord step) {
    final passed = step.passed;
    final common = {
      'status': passed ? 'PASSED' : 'ABANDONED',
      'startedOffsetMs': step.startedMs,
      'endedOffsetMs': ?step.endedMs,
      'attempts': step.attempts,
    };
    Map<String, dynamic> tilt(String axis, String min, String max) => {
      'stepType': 'DEVICE_TILT',
      ...common,
      'params': {
        'axis': axis,
        'minDeg': _adv.d(min, axis == 'ROLL' ? -8 : -12),
        'maxDeg': _adv.d(max, axis == 'ROLL' ? 8 : 12),
        'holdMs': _adv.i('tilt_hold_ms', 700),
      },
      if (passed) 'result': {'meanDeg': step.meanA ?? 0, 'heldMs': step.heldMs},
    };
    return switch (step.phase) {
      FnoseGamePhase.deviceStill => {
        'stepType': 'DEVICE_STILL',
        ...common,
        'params': {
          'requiredStableTimeMs': _adv.i('required_stable_time_ms', 2500),
          'stabilityGraceMs': _adv.i('stability_grace_ms', 400),
        },
        if (passed) 'result': {'achievedMs': step.heldMs},
      },
      FnoseGamePhase.deviceRoll => tilt('ROLL', 'roll_min_deg', 'roll_max_deg'),
      FnoseGamePhase.devicePitch => tilt(
        'PITCH',
        'pitch_min_deg',
        'pitch_max_deg',
      ),
      FnoseGamePhase.alignNose => {
        'stepType': 'BODY_LANDMARK_ALIGN',
        ...common,
        'params': {
          'landmark': 'nose',
          'region': _region(noseTargetCenter, noseTargetRadius),
          'holdMs': _adv.i('nose_hold_ms', 1200),
        },
        if (passed) 'result': _alignResult(step),
      },
      _ => _targetStep(step, common),
    };
  }

  Map<String, dynamic> _alignResult(SetupStepRecord step) {
    final mean = _inRegionSpace(Offset(step.meanA ?? 0, step.meanB ?? 0));
    return {'meanX': mean.dx, 'meanY': mean.dy, 'heldMs': step.heldMs};
  }

  Map<String, dynamic> _targetStep(
    SetupStepRecord step,
    Map<String, dynamic> common,
  ) {
    final mapper = _mapper;
    final offset = fingerCalibrationOffset;
    final point = calibratedFingerPosition;
    final tolerance = _adv.d('finger_stability', 0.05);
    return {
      'stepType': 'TARGET_POINT',
      ...common,
      'params': {
        'landmark': _settings.gameMode == 'rightHand'
            ? 'right_index'
            : 'left_index',
        'target': _region(
          calibrationTargetPosition ?? fingerTargetCenter,
          fingerTargetRadius,
        ),
        'tolerance': mapper == null
            ? tolerance
            : mapper.radiusToPixels(tolerance),
        'smoothing': _adv.d('finger_smoothing', 0.35).clamp(0.05, 1.0),
        'holdMs': _adv.i('finger_hold_ms', 1200),
      },
      if (step.passed && offset != null)
        'result': {
          'offsetDx': _inRegionSpace(offset).dx,
          'offsetDy': _inRegionSpace(offset).dy,
          if (point != null) ...{
            'pointX': _inRegionSpace(point).dx,
            'pointY': _inRegionSpace(point).dy,
          },
        },
    };
  }

  /// Regions are in screen pixels when the screen is known: the app's radii
  /// are fractions of the shorter side, which is not `screen_norm`.
  Map<String, dynamic> _region(Offset center, double radius) {
    final mapper = _mapper;
    if (mapper == null) {
      return {
        'x': center.dx,
        'y': center.dy,
        'radius': radius,
        'space': 'screen_norm',
      };
    }
    final px = mapper.toPixels(center);
    return {
      'x': px.dx,
      'y': px.dy,
      'radius': mapper.radiusToPixels(radius),
      'space': 'screen_px',
    };
  }

  Offset _inRegionSpace(Offset screenFraction) =>
      _mapper?.toPixels(screenFraction) ?? screenFraction;

  void beginPlaying() {
    if (phase != FnoseGamePhase.countdown) return;
    final now = _clock.now();
    _setPhase(FnoseGamePhase.playing, now);
    _playingStartedMs = _clock.offsetMs(now);
    _finishedMs = null;
    remainingSeconds = totalSeconds;
    leftSparks = 0;
    rightSparks = 0;
    leftSpark = FnoseSparkState.idle;
    rightSpark = FnoseSparkState.idle;
    _leftFireUntil = null;
    _rightFireUntil = null;
    _left.reset();
    _right.reset();
    _poseFrameCounter = 0;
    _poseSamples.clear();
    _sparkEvents.clear();
    _hitEvents.clear();
    _angles.clear();
    _distances.clear();
    lastHitMark = null;
    lastHitValid = null;
    notify();
  }

  void onCountdownFinished() => beginPlaying();

  void onSecondElapsed() {
    if (phase != FnoseGamePhase.playing) return;
    remainingSeconds -= 1;
    if (remainingSeconds <= 0) {
      remainingSeconds = 0;
      final now = _clock.now();
      _setPhase(FnoseGamePhase.finished, now);
      _finishedMs = _clock.offsetMs(now);
    }
    notify();
  }

  void _samplePose(List<LandmarkPoint> pose, DateTime now) {
    _poseSamples.add({
      'offsetMs': _clock.offsetMs(now),
      'phase': phase.name,
      'pose': [for (final p in pose) p.toKinematicJson()],
    });
  }

  void _processArms(Map<int, LandmarkPoint> byIndex, DateTime now) {
    final leftActive = _settings.gameMode != 'rightHand';
    final rightActive = !leftActive;

    if (leftActive) {
      _tickArm(isLeft: true, byIndex: byIndex, tracker: _left, now: now);
    } else {
      _left.reset();
      _setSpark(isLeft: true, FnoseSparkState.idle, now);
    }

    if (rightActive) {
      _tickArm(isLeft: false, byIndex: byIndex, tracker: _right, now: now);
    } else {
      _right.reset();
      _setSpark(isLeft: false, FnoseSparkState.idle, now);
    }
  }

  /// Sets one arm's spark state; a change becomes a `spark` event.
  void _setSpark(FnoseSparkState next, DateTime at, {required bool isLeft}) {
    final current = isLeft ? leftSpark : rightSpark;
    if (next == current) return;
    _sparkEvents.add({
      'offsetMs': _clock.offsetMs(at),
      'eventType': 'spark',
      'side': isLeft ? 'left' : 'right',
      'fromState': current.name,
      'toState': next.name,
    });
    if (isLeft) {
      leftSpark = next;
    } else {
      rightSpark = next;
    }
  }

  void _tickArm({
    required bool isLeft,
    required Map<int, LandmarkPoint> byIndex,
    required ArmMovementTracker tracker,
    required DateTime now,
  }) {
    final nose = byIndex[PoseIdx.nose];
    final shoulder =
        byIndex[isLeft ? PoseIdx.leftShoulder : PoseIdx.rightShoulder];
    final elbow = byIndex[isLeft ? PoseIdx.leftElbow : PoseIdx.rightElbow];
    final wrist = byIndex[isLeft ? PoseIdx.leftWrist : PoseIdx.rightWrist];
    final index = byIndex[isLeft ? PoseIdx.leftIndex : PoseIdx.rightIndex];

    if (nose == null ||
        shoulder == null ||
        elbow == null ||
        wrist == null ||
        index == null) {
      return;
    }

    tracker.updateFromLandmarks(
      shoulder: shoulder,
      elbow: elbow,
      wrist: wrist,
      index: index,
      nose: nose,
    );

    final fireMs = _adv.i('spark_fire_ms', 450);
    final fireUntil = isLeft ? _leftFireUntil : _rightFireUntil;
    if (fireUntil != null) {
      if (now.isBefore(fireUntil)) {
        _setSpark(isLeft: isLeft, FnoseSparkState.fire, now);
        notify();
        return;
      }
      if (isLeft) {
        _leftFireUntil = null;
      } else {
        _rightFireUntil = null;
      }
    }

    // Sequência simplificada: idle → armed (nariz) → hit no alvo → fire → idle.
    var spark = isLeft ? leftSpark : rightSpark;
    if (spark == FnoseSparkState.fire || spark == FnoseSparkState.aiming) {
      spark = FnoseSparkState.idle;
    }

    final tipScreen = adjustedFingerPosition(index);
    if (tipScreen != null) {
      fingerPosition = tipScreen;
    }

    if (spark == FnoseSparkState.idle && tracker.isNoseTouch()) {
      spark = FnoseSparkState.armed;
    } else if (spark == FnoseSparkState.armed && tipScreen != null) {
      final mapper = _mapper;
      if (mapper != null) {
        final inside =
            mapper.distance(tipScreen, fingerTargetCenter) <= fingerTargetRadius;
        if (inside) {
          _registerTargetHit(
            mapper,
            isLeft: isLeft,
            tip: index,
            tipScreen: tipScreen,
            nose: nose,
            angle: tracker.latestAngle,
            now: now,
          );
          if (isLeft) {
            leftSparks += 1;
            _leftFireUntil = now.add(Duration(milliseconds: fireMs));
          } else {
            rightSparks += 1;
            _rightFireUntil = now.add(Duration(milliseconds: fireMs));
          }
          spark = FnoseSparkState.fire;
          tracker.reset();
        }
      }
    }

    _setSpark(isLeft: isLeft, spark, now);
    notify();
  }

  void _registerTargetHit(
    ScreenMapper mapper, {
    required bool isLeft,
    required LandmarkPoint tip,
    required Offset tipScreen,
    required LandmarkPoint nose,
    required double angle,
    required DateTime now,
  }) {
    lastHitMark = OffsetMark(
      x: tipScreen.dx,
      y: tipScreen.dy,
      isLeft: isLeft,
    );
    lastHitValid = true;

    _angles.add(angle);
    final dx = tip.x - nose.x;
    final dy = tip.y - nose.y;
    _distances.add((Offset(dx, dy)).distance);
    // tip/nose in the camera image; tip (with the calibration offset) and
    // target in screen pixels, exactly as the hit was decided.
    final tipPx = mapper.toPixels(tipScreen);
    final targetPx = mapper.toPixels(fingerTargetCenter);
    _hitEvents.add({
      'offsetMs': _clock.offsetMs(now),
      'eventType': 'hit',
      'side': isLeft ? 'left' : 'right',
      'angleDeg': angle,
      'tipX': tip.x,
      'tipY': tip.y,
      'noseX': nose.x,
      'noseY': nose.y,
      'tipScreenX': tipPx.dx,
      'tipScreenY': tipPx.dy,
      'targetX': targetPx.dx,
      'targetY': targetPx.dy,
      'targetRadius': mapper.radiusToPixels(fingerTargetRadius),
    });
  }
}

class OffsetMark {
  const OffsetMark({required this.x, required this.y, required this.isLeft});
  final double x;
  final double y;
  final bool isLeft;
}

class FnoseGameResult {
  const FnoseGameResult({
    required this.totalTime,
    this.durationMs = 0,
    required this.gameMode,
    required this.totalLeftSparks,
    required this.totalRightSparks,
    required this.totalSparks,
    this.avgDistance,
    this.avgAngle,
    this.phaseEvents = const [],
    this.poseSamples = const [],
    this.sparkEvents = const [],
    this.hitEvents = const [],
    this.screenWidth,
    this.screenHeight,
    this.imageWidth,
    this.imageHeight,
    this.matchId,
    this.sessionId,
    this.saveError,
    this.calibrationRunId,
    this.preview,
    this.queued = false,
  });

  final int totalTime;

  /// Tempo jogado medido (fase `playing` → `finished`), em ms.
  final int durationMs;
  final String gameMode;
  final int totalLeftSparks;
  final int totalRightSparks;
  final int totalSparks;
  final double? avgDistance;
  final double? avgAngle;
  final List<Map<String, dynamic>> phaseEvents;
  final List<Map<String, dynamic>> poseSamples;

  /// Spark state changes per arm (`idle` → `armed` → `fire` → `idle`).
  final List<Map<String, dynamic>> sparkEvents;

  /// One per spark counted.
  final List<Map<String, dynamic>> hitEvents;
  final int? screenWidth;
  final int? screenHeight;
  final int? imageWidth;
  final int? imageHeight;
  final String? matchId;
  final String? sessionId;
  final String? saveError;
  final String? calibrationRunId;
  final Map<String, double>? preview;

  /// Not sent yet but kept on the device; [saveError] says so.
  final bool queued;

  bool get saved => matchId != null && saveError == null;

  FnoseGameResult copyWith({
    String? matchId,
    String? sessionId,
    String? saveError,
    String? calibrationRunId,
    bool? queued,
    bool clearSaveError = false,
  }) {
    return FnoseGameResult(
      totalTime: totalTime,
      durationMs: durationMs,
      gameMode: gameMode,
      totalLeftSparks: totalLeftSparks,
      totalRightSparks: totalRightSparks,
      totalSparks: totalSparks,
      avgDistance: avgDistance,
      avgAngle: avgAngle,
      phaseEvents: phaseEvents,
      poseSamples: poseSamples,
      sparkEvents: sparkEvents,
      hitEvents: hitEvents,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      matchId: matchId ?? this.matchId,
      sessionId: sessionId ?? this.sessionId,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      calibrationRunId: calibrationRunId ?? this.calibrationRunId,
      preview: preview,
      queued: queued ?? this.queued,
    );
  }

  /// `phase`, `spark` and `hit` on one timeline, ordered by `offsetMs`.
  List<Map<String, dynamic>> get events =>
      byOffset([phaseEvents, sparkEvents, hitEvents]);

  /// Body of `POST /msupperlimbs-fnose/matches/{id}/metrics`.
  Map<String, dynamic> toMetricsJson() => {
    'totalLeftSparks': totalLeftSparks,
    'totalRightSparks': totalRightSparks,
    'totalSparks': totalSparks,
    'avgDistance': ?avgDistance,
    'avgAngle': ?avgAngle,
    'isValidMatch': totalSparks > 0,
  };
}
