import 'dart:ui';

import 'package:msupperlimbs/features/fnose/data/models/fnose_settings.dart';
import 'package:msupperlimbs/features/fnose/domain/arm_movement_tracker.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_types.dart';
import 'package:msupperlimbs/features/fnose/domain/pregame_telemetry_buffer.dart';
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
  }) : _settings = settings.gameMode == 'bothHands'
           ? settings.copyWith(gameMode: 'leftHand')
           : settings,
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
  String? pregameRunId;

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

  DateTime? _leftFireUntil;
  DateTime? _rightFireUntil;

  final List<Map<String, dynamic>> _poseSamples = [];
  final List<Map<String, dynamic>> _touchEvents = [];
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

  FnoseGameResult get result {
    final avgAngle = _angles.isEmpty
        ? null
        : _angles.reduce((a, b) => a + b) / _angles.length;
    final avgDistance = _distances.isEmpty
        ? null
        : _distances.reduce((a, b) => a + b) / _distances.length;
    return FnoseGameResult(
      totalTime: totalSeconds,
      gameMode: _settings.gameMode,
      totalLeftSparks: leftSparks,
      totalRightSparks: rightSparks,
      totalSparks: totalSparks,
      avgDistance: avgDistance,
      avgAngle: avgAngle,
      poseSamples: List.unmodifiable(_poseSamples),
      touchEvents: List.unmodifiable(_touchEvents),
      settingsSnapshot: _settings.toUpdateJson(),
      advSettingsSnapshot: Map<String, dynamic>.from(_adv.data),
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      pregameRunId: pregameRunId,
      startedAtMs: _clock.startedAt.millisecondsSinceEpoch,
      endedAtMs: _clock.nowMs(),
      preview: _mapper?.normalizedPreview,
    );
  }

  void notify() => _onChanged?.call();

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
        phase = FnoseGamePhase.deviceStill;
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
          phase = FnoseGamePhase.deviceRoll;
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
          if (_holdReached(_adv.i('tilt_hold_ms', 700), now)) {
            phase = FnoseGamePhase.devicePitch;
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
          if (_holdReached(_adv.i('tilt_hold_ms', 700), now)) {
            phase = FnoseGamePhase.alignNose;
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
          if (_holdReached(_adv.i('nose_hold_ms', 1200), now)) {
            phase = FnoseGamePhase.calibrateFinger;
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
          phase = FnoseGamePhase.countdown;
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
  }

  /// Closes pregame window and returns POST payload (same `t` timeline).
  Map<String, dynamic>? closePregame({
    required String status,
    String? deviceModel,
    DateTime? at,
  }) {
    if (_pregameClosed) return null;
    _pregameClosed = true;
    return telemetry.finish(
      gameMode: _settings.gameMode,
      status: status,
      deviceModel: deviceModel,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      preview: _mapper?.normalizedPreview,
      settingsSnapshot: _settings.toUpdateJson(),
      advSettingsSnapshot: Map<String, dynamic>.from(_adv.data),
      at: at,
    );
  }

  void beginPlaying() {
    if (phase != FnoseGamePhase.countdown) return;
    phase = FnoseGamePhase.playing;
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
    _touchEvents.clear();
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
      phase = FnoseGamePhase.finished;
    }
    notify();
  }

  void _samplePose(List<LandmarkPoint> pose, DateTime now) {
    _poseSamples.add({
      't': now.toUtc().millisecondsSinceEpoch,
      'pose': [for (final p in pose) p.toKinematicJson()],
      'hands': const <Map<String, dynamic>>[],
    });
  }

  void _processArms(Map<int, LandmarkPoint> byIndex, DateTime now) {
    final mode = _settings.gameMode;
    final leftActive = mode == 'leftHand' || mode == 'bothHands';
    final rightActive = mode == 'rightHand' || mode == 'bothHands';

    if (leftActive) {
      _tickArm(isLeft: true, byIndex: byIndex, tracker: _left, now: now);
    } else {
      _left.reset();
      leftSpark = FnoseSparkState.idle;
    }

    if (rightActive) {
      _tickArm(isLeft: false, byIndex: byIndex, tracker: _right, now: now);
    } else {
      _right.reset();
      rightSpark = FnoseSparkState.idle;
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
        if (isLeft) {
          leftSpark = FnoseSparkState.fire;
        } else {
          rightSpark = FnoseSparkState.fire;
        }
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

    if (isLeft) {
      leftSpark = spark;
    } else {
      rightSpark = spark;
    }
    notify();
  }

  void _registerTargetHit({
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
    _touchEvents.add({
      't': now.toUtc().millisecondsSinceEpoch,
      'isLeft': isLeft,
      'angle': angle,
      'screen': {'x': tipScreen.dx, 'y': tipScreen.dy},
      'target': {
        'x': fingerTargetCenter.dx,
        'y': fingerTargetCenter.dy,
        'r': fingerTargetRadius,
      },
      'noseX': nose.x,
      'noseY': nose.y,
      'insideTarget': true,
      'gameMode': _settings.gameMode,
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
    required this.gameMode,
    required this.totalLeftSparks,
    required this.totalRightSparks,
    required this.totalSparks,
    this.avgDistance,
    this.avgAngle,
    this.poseSamples = const [],
    this.touchEvents = const [],
    this.settingsSnapshot,
    this.advSettingsSnapshot,
    this.screenWidth,
    this.screenHeight,
    this.imageWidth,
    this.imageHeight,
    this.matchId,
    this.sessionId,
    this.saveError,
    this.pregameRunId,
    this.startedAtMs,
    this.endedAtMs,
    this.preview,
  });

  final int totalTime;
  final String gameMode;
  final int totalLeftSparks;
  final int totalRightSparks;
  final int totalSparks;
  final double? avgDistance;
  final double? avgAngle;
  final List<Map<String, dynamic>> poseSamples;
  final List<Map<String, dynamic>> touchEvents;
  final Map<String, dynamic>? settingsSnapshot;
  final Map<String, dynamic>? advSettingsSnapshot;
  final int? screenWidth;
  final int? screenHeight;
  final int? imageWidth;
  final int? imageHeight;
  final String? matchId;
  final String? sessionId;
  final String? saveError;
  final String? pregameRunId;
  final int? startedAtMs;
  final int? endedAtMs;
  final Map<String, double>? preview;

  bool get saved => matchId != null && saveError == null;

  FnoseGameResult copyWith({
    String? matchId,
    String? sessionId,
    String? saveError,
    String? pregameRunId,
    bool clearSaveError = false,
  }) {
    return FnoseGameResult(
      totalTime: totalTime,
      gameMode: gameMode,
      totalLeftSparks: totalLeftSparks,
      totalRightSparks: totalRightSparks,
      totalSparks: totalSparks,
      avgDistance: avgDistance,
      avgAngle: avgAngle,
      poseSamples: poseSamples,
      touchEvents: touchEvents,
      settingsSnapshot: settingsSnapshot,
      advSettingsSnapshot: advSettingsSnapshot,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      matchId: matchId ?? this.matchId,
      sessionId: sessionId ?? this.sessionId,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      pregameRunId: pregameRunId ?? this.pregameRunId,
      startedAtMs: startedAtMs,
      endedAtMs: endedAtMs,
      preview: preview,
    );
  }

  Map<String, dynamic> toMatchPayload({String? deviceModel}) {
    return {
      'data_contract_version': MotionDataContract.version,
      'device_model': ?deviceModel,
      'total_time': totalTime,
      'game_mode': gameMode,
      'total_left_sparks': totalLeftSparks,
      'total_right_sparks': totalRightSparks,
      'total_sparks': totalSparks,
      'avg_distance': avgDistance,
      'avg_angle': avgAngle,
      'settings_snapshot': settingsSnapshot,
      'adv_settings_snapshot': advSettingsSnapshot,
      'screen_width': screenWidth,
      'screen_height': screenHeight,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'is_valid_match': totalSparks > 0,
      'pose_samples': poseSamples,
      'touch_events': touchEvents,
      'pregame_run_id': ?pregameRunId,
      'started_at_ms': startedAtMs,
      'ended_at_ms': endedAtMs,
      'preview': preview,
    };
  }
}

class FnoseMatchSaveResponse {
  const FnoseMatchSaveResponse({
    required this.id,
    required this.sessionId,
    required this.totalSparks,
    required this.poseChunkCount,
    required this.touchChunkCount,
  });

  final String id;
  final String sessionId;
  final int totalSparks;
  final int poseChunkCount;
  final int touchChunkCount;

  factory FnoseMatchSaveResponse.fromJson(Map<String, dynamic> json) {
    return FnoseMatchSaveResponse(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      totalSparks: json['total_sparks'] as int? ?? 0,
      poseChunkCount: json['pose_chunk_count'] as int? ?? 0,
      touchChunkCount: json['touch_chunk_count'] as int? ?? 0,
    );
  }
}
