import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings.dart';
import 'package:msupperlimbs/features/fnose/domain/arm_movement_tracker.dart';
import 'package:msupperlimbs/features/fnose/domain/device_attitude.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_game_engine.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_types.dart';
import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';
import 'package:msupperlimbs/features/motion/domain/session_clock.dart';

import '../../support/no_epoch.dart';

void main() {
  SessionClock clock() => SessionClock(source: () => DateTime.utc(2026, 1, 1));
  test('device attitude becomes still after consecutive equal samples', () {
    final filter = DeviceAttitudeFilter(alpha: 0.3, stabilityThreshold: 0.5);
    final first = filter.update(
      x: 9.8,
      y: 0,
      z: 0,
      orientation: DeviceOrientation.landscapeLeft,
    );
    final second = filter.update(
      x: 9.8,
      y: 0,
      z: 0,
      orientation: DeviceOrientation.landscapeLeft,
    );
    expect(first.still, isFalse);
    expect(second.still, isTrue);
    expect(second.pitch, closeTo(0, 0.01));
    expect(second.roll, closeTo(0, 0.01));
  });

  group('ArmMovementTracker', () {
    test('computeElbowAngle returns ~180 for straight arm', () {
      final angle = ArmMovementTracker.computeElbowAngle(
        shoulder: [0, 0, 0],
        elbow: [1, 0, 0],
        wrist: [2, 0, 0],
      );
      expect(angle, closeTo(180, 1));
    });

    test('isNoseTouch arms readyForTargetTouch', () {
      final t = ArmMovementTracker();
      t.update(40);
      t.update(35);
      t.updateFromLandmarks(
        shoulder: const LandmarkPoint(index: 11, x: 0.4, y: 0.4, z: 0),
        elbow: const LandmarkPoint(index: 13, x: 0.45, y: 0.5, z: 0),
        wrist: const LandmarkPoint(index: 15, x: 0.5, y: 0.5, z: 0),
        index: const LandmarkPoint(index: 19, x: 0.52, y: 0.5, z: 0),
        nose: const LandmarkPoint(index: 0, x: 0.51, y: 0.51, z: 0),
      );
      // Force flexed angle near nose.
      t.update(30);
      expect(t.isNoseTouch(), isTrue);
    });

    test('isTargetTouch requires prior nose touch and extension', () {
      final t = ArmMovementTracker();
      t.update(40);
      t.update(30);
      t.updateFromLandmarks(
        shoulder: const LandmarkPoint(index: 11, x: 0.4, y: 0.4, z: 0),
        elbow: const LandmarkPoint(index: 13, x: 0.45, y: 0.5, z: 0),
        wrist: const LandmarkPoint(index: 15, x: 0.5, y: 0.5, z: 0),
        index: const LandmarkPoint(index: 19, x: 0.8, y: 0.5, z: 0),
        nose: const LandmarkPoint(index: 0, x: 0.51, y: 0.51, z: 0),
      );
      t.update(30);
      expect(t.isNoseTouch(), isTrue);
      t.update(160);
      expect(t.isTargetTouch(), isTrue);
      expect(t.isTargetTouch(), isFalse); // only once
    });
  });

  group('FnoseGameEngine', () {
    FnoseSettings settings() => FnoseSettings(
      gameMode: 'leftHand',
      showInfoVideo: true,
      totalTime: 5,
      targetSize: 1,
      updatedAt: DateTime.utc(2026),
    );

    FnoseAdvSettings adv() => FnoseAdvSettings(
      data: {
        'required_stable_time_ms': 100,
        'stability_grace_ms': 200,
        'tilt_hold_ms': 100,
        'nose_hold_ms': 100,
        'finger_hold_ms': 100,
        'finger_stability': 0.05,
        'finger_grace_ms': 400,
        'spark_fire_ms': 300,
        'elbow_flexion_threshold': 45,
        'nose_touch_distance_threshold': 0.35,
        'roll_min_deg': -8,
        'roll_max_deg': 8,
        'pitch_min_deg': -12,
        'pitch_max_deg': 12,
        'landmark_buffer_size': 3,
        'x_target_position': 0.1,
        'y_target_position': 0.5,
        'target_scale': 0.45,
      },
      updatedAt: DateTime.utc(2026),
    );

    List<LandmarkPoint> poseCore() => [
      const LandmarkPoint(index: PoseIdx.nose, x: 0.7, y: 0.3, z: 0),
      const LandmarkPoint(index: PoseIdx.leftShoulder, x: 0.4, y: 0.4, z: 0),
      const LandmarkPoint(index: PoseIdx.rightShoulder, x: 0.6, y: 0.4, z: 0),
      const LandmarkPoint(index: PoseIdx.leftElbow, x: 0.35, y: 0.55, z: 0),
      const LandmarkPoint(index: PoseIdx.leftWrist, x: 0.5, y: 0.31, z: 0),
      // Indicador dentro do alvo esquerdo (centro em ~0.21, 0.5).
      const LandmarkPoint(index: PoseIdx.leftIndex, x: 0.22, y: 0.52, z: 0),
    ];

    test('pregame advances through stability, tilt, nose and finger', () {
      final engine = FnoseGameEngine(
        settings: settings(),
        adv: adv(),
        clock: clock(),
      );
      final t0 = DateTime.utc(2026, 1, 1);
      engine
        ..screenWidth = 1000
        ..screenHeight = 500
        ..previewRect = const Rect.fromLTWH(0, 0, 1000, 500);
      expect(engine.phase, FnoseGamePhase.deviceStill);

      engine.onSensorStatus(still: true, pitch: 0, roll: 0, now: t0);
      engine.onSensorStatus(
        still: true,
        pitch: 0,
        roll: 0,
        now: t0.add(const Duration(milliseconds: 120)),
      );
      expect(engine.phase, FnoseGamePhase.deviceRoll);
      engine.onSensorStatus(
        still: true,
        pitch: 0,
        roll: 0,
        now: t0.add(const Duration(milliseconds: 130)),
      );
      engine.onSensorStatus(
        still: true,
        pitch: 0,
        roll: 0,
        now: t0.add(const Duration(milliseconds: 250)),
      );
      expect(engine.phase, FnoseGamePhase.devicePitch);
      engine.onSensorStatus(
        still: true,
        pitch: 0,
        roll: 0,
        now: t0.add(const Duration(milliseconds: 260)),
      );
      engine.onSensorStatus(
        still: true,
        pitch: 0,
        roll: 0,
        now: t0.add(const Duration(milliseconds: 380)),
      );
      expect(engine.phase, FnoseGamePhase.alignNose);

      engine.onPose(poseCore(), t0.add(const Duration(milliseconds: 400)));
      engine.onPose(poseCore(), t0.add(const Duration(milliseconds: 520)));
      expect(engine.phase, FnoseGamePhase.calibrateFinger);
      engine.onPose(poseCore(), t0.add(const Duration(milliseconds: 530)));
      engine.onPose(poseCore(), t0.add(const Duration(milliseconds: 650)));
      expect(engine.phase, FnoseGamePhase.countdown);
      expect(engine.fingerCalibrationOffset, isNotNull);
      final adjusted = engine.adjustedFingerPosition(
        poseCore().firstWhere((p) => p.index == PoseIdx.leftIndex),
      );
      expect(adjusted!.dx, closeTo(engine.fingerTargetCenter.dx, 0.01));
      expect(adjusted.dy, closeTo(engine.fingerTargetCenter.dy, 0.01));
    });

    List<LandmarkPoint> poseWithFinger(double x, double y) => [
      for (final p in poseCore())
        if (p.index == PoseIdx.leftIndex)
          LandmarkPoint(index: PoseIdx.leftIndex, x: x, y: y, z: 0)
        else
          p,
    ];

    FnoseGameEngine fingerEngine() =>
        FnoseGameEngine(settings: settings(), adv: adv(), clock: clock())
          ..screenWidth = 1000
          ..screenHeight = 500
          ..previewRect = const Rect.fromLTWH(0, 0, 1000, 500)
          ..phase = FnoseGamePhase.calibrateFinger;

    test('finger tremor around the target edge still completes', () {
      final engine = fingerEngine();
      final t0 = DateTime.utc(2026, 1, 1);

      for (var i = 0; i <= 8; i++) {
        // Alterna entre o centro e ligeiramente fora da borda do alvo.
        final y = i.isEven ? 0.5 : 0.74;
        engine.onPose(
          poseWithFinger(0.2125, y),
          t0.add(Duration(milliseconds: i * 30)),
        );
      }

      expect(engine.phase, FnoseGamePhase.countdown);
      expect(engine.fingerCalibrationOffset, isNotNull);
    });

    test('finger away from the target never completes', () {
      final engine = fingerEngine();
      final t0 = DateTime.utc(2026, 1, 1);

      for (var i = 0; i <= 20; i++) {
        engine.onPose(
          poseWithFinger(0.8, 0.9),
          t0.add(Duration(milliseconds: i * 50)),
        );
      }

      expect(engine.phase, FnoseGamePhase.calibrateFinger);
      expect(engine.fingerInside, isFalse);
      expect(engine.fingerCalibrationOffset, isNull);
    });

    test('brief instability is tolerated before regressing', () {
      final engine = FnoseGameEngine(
        settings: settings(),
        adv: adv(),
        clock: clock(),
      )..phase = FnoseGamePhase.devicePitch;
      final t0 = DateTime.utc(2026);

      engine.onSensorStatus(still: false, pitch: 0, roll: 0, now: t0);
      expect(engine.phase, FnoseGamePhase.devicePitch);

      engine.onSensorStatus(
        still: false,
        pitch: 0,
        roll: 0,
        now: t0.add(const Duration(milliseconds: 250)),
      );
      expect(engine.phase, FnoseGamePhase.deviceStill);
    });

    test('pregame progress does not reset between phases', () {
      final engine = FnoseGameEngine(
        settings: settings(),
        adv: adv(),
        clock: clock(),
      );
      final t0 = DateTime.utc(2026, 1, 1);

      engine.onSensorStatus(still: true, pitch: 0, roll: 0, now: t0);
      engine.onSensorStatus(
        still: true,
        pitch: 0,
        roll: 0,
        now: t0.add(const Duration(milliseconds: 120)),
      );
      expect(engine.phase, FnoseGamePhase.deviceRoll);
      expect(engine.holdProgress, greaterThan(0));
    });

    test('timer finishes match', () {
      final engine = FnoseGameEngine(
        settings: settings(),
        adv: adv(),
        clock: clock(),
      );
      engine.phase = FnoseGamePhase.countdown;
      engine.beginPlaying();
      expect(engine.phase, FnoseGamePhase.playing);
      for (var i = 0; i < 5; i++) {
        engine.onSecondElapsed();
      }
      expect(engine.phase, FnoseGamePhase.finished);
      expect(engine.remainingSeconds, 0);
    });

    test('spark scores after nose arm then target touch', () {
      final engine =
          FnoseGameEngine(settings: settings(), adv: adv(), clock: clock())
            ..screenWidth = 1000
            ..screenHeight = 500
            ..previewRect = const Rect.fromLTWH(0, 0, 1000, 500)
            ..phase = FnoseGamePhase.countdown;
      engine.beginPlaying();
      final t0 = DateTime.utc(2026, 1, 1);

      // Braço flexionado com pulso junto ao nariz → armed (precisa 2 frames).
      final nosePose = [
        const LandmarkPoint(index: PoseIdx.nose, x: 0.5, y: 0.3, z: 0),
        const LandmarkPoint(index: PoseIdx.leftShoulder, x: 0.4, y: 0.4, z: 0),
        const LandmarkPoint(index: PoseIdx.rightShoulder, x: 0.6, y: 0.4, z: 0),
        const LandmarkPoint(index: PoseIdx.leftElbow, x: 0.42, y: 0.55, z: 0),
        const LandmarkPoint(index: PoseIdx.leftWrist, x: 0.5, y: 0.32, z: 0),
        const LandmarkPoint(index: PoseIdx.leftIndex, x: 0.51, y: 0.31, z: 0),
      ];
      engine.onPose(nosePose, t0);
      engine.onPose(nosePose, t0.add(const Duration(milliseconds: 20)));
      expect(engine.leftSpark, FnoseSparkState.armed);
      expect(engine.leftSparks, 0);

      // Mesmo ciclo armed: ponta do indicador no centro do alvo → spark.
      final target = engine.fingerTargetCenter;
      engine.onPose([
        const LandmarkPoint(index: PoseIdx.nose, x: 0.5, y: 0.3, z: 0),
        const LandmarkPoint(index: PoseIdx.leftShoulder, x: 0.4, y: 0.4, z: 0),
        const LandmarkPoint(index: PoseIdx.rightShoulder, x: 0.6, y: 0.4, z: 0),
        const LandmarkPoint(index: PoseIdx.leftElbow, x: 0.3, y: 0.5, z: 0),
        const LandmarkPoint(index: PoseIdx.leftWrist, x: 0.25, y: 0.5, z: 0),
        LandmarkPoint(
          index: PoseIdx.leftIndex,
          x: target.dx,
          y: target.dy,
          z: 0,
        ),
      ], t0.add(const Duration(milliseconds: 40)));
      expect(engine.leftSparks, 1);
      expect(engine.leftSpark, FnoseSparkState.fire);
      expect(engine.lastHitValid, isTrue);

      // Durante o flash não conta outro hit; depois volta a idle.
      engine.onPose([
        const LandmarkPoint(index: PoseIdx.nose, x: 0.5, y: 0.3, z: 0),
        const LandmarkPoint(index: PoseIdx.leftShoulder, x: 0.4, y: 0.4, z: 0),
        const LandmarkPoint(index: PoseIdx.rightShoulder, x: 0.6, y: 0.4, z: 0),
        const LandmarkPoint(index: PoseIdx.leftElbow, x: 0.3, y: 0.5, z: 0),
        const LandmarkPoint(index: PoseIdx.leftWrist, x: 0.25, y: 0.5, z: 0),
        LandmarkPoint(
          index: PoseIdx.leftIndex,
          x: target.dx,
          y: target.dy,
          z: 0,
        ),
      ], t0.add(const Duration(milliseconds: 80)));
      expect(engine.leftSparks, 1);

      engine.onPose([
        const LandmarkPoint(index: PoseIdx.nose, x: 0.5, y: 0.3, z: 0),
        const LandmarkPoint(index: PoseIdx.leftShoulder, x: 0.4, y: 0.4, z: 0),
        const LandmarkPoint(index: PoseIdx.rightShoulder, x: 0.6, y: 0.4, z: 0),
        const LandmarkPoint(index: PoseIdx.leftElbow, x: 0.3, y: 0.5, z: 0),
        const LandmarkPoint(index: PoseIdx.leftWrist, x: 0.25, y: 0.5, z: 0),
        LandmarkPoint(
          index: PoseIdx.leftIndex,
          x: target.dx,
          y: target.dy,
          z: 0,
        ),
      ], t0.add(const Duration(milliseconds: 400)));
      expect(engine.leftSpark, FnoseSparkState.idle);
    });

    test('setup phases go to calibration, match phases to the match', () {
      final t0 = DateTime.utc(2026, 1, 1);
      var now = t0;
      DateTime at(int ms) => t0.add(Duration(milliseconds: ms));
      final engine =
          FnoseGameEngine(
              settings: settings(),
              adv: adv(),
              clock: SessionClock(source: () => now),
            )
            ..screenWidth = 1000
            ..screenHeight = 500
            ..previewRect = const Rect.fromLTWH(0, 0, 1000, 500);

      for (final ms in [0, 120, 130, 250, 260, 380]) {
        engine.onSensorStatus(still: true, pitch: 0, roll: 0, now: at(ms));
      }
      for (final ms in [400, 520, 530, 650]) {
        engine.onPose(poseCore(), at(ms));
      }
      expect(engine.phase, FnoseGamePhase.countdown);
      final pregame = engine.closePregame(status: 'completed', at: at(3650))!;
      now = at(3650);
      engine.onCountdownFinished();
      for (var s = 1; s <= 5; s++) {
        now = at(3650 + s * 1000);
        engine.onSecondElapsed();
      }

      final setup = [
        for (final e in engine.telemetry.events)
          if (e['type'] == 'phase')
            (e['offsetMs'], (e['data'] as Map)['toPhase']),
      ];
      expect(setup, [
        (0, 'deviceStill'),
        (120, 'deviceRoll'),
        (250, 'devicePitch'),
        (380, 'alignNose'),
        (520, 'calibrateFinger'),
      ]);

      final result = engine.result;
      expect(
        result.phaseEvents
            .map((e) => (e['offsetMs'], e['fromPhase'], e['toPhase']))
            .toList(),
        [
          (650, 'calibrateFinger', 'countdown'),
          (3650, 'countdown', 'playing'),
          (8650, 'playing', 'finished'),
        ],
      );
      expect(result.durationMs, 5000);
      expectNoEpoch(pregame);
      expectNoEpoch(result.toMatchPayload(deviceModel: 'test'));
    });
  });
}
