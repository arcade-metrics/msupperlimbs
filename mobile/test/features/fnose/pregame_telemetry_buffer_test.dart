import 'package:flutter_test/flutter_test.dart';
import 'package:msupperlimbs/features/fnose/domain/pregame_telemetry_buffer.dart';
import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';
import 'package:msupperlimbs/features/motion/domain/session_clock.dart';

import '../../support/no_epoch.dart';

void main() {
  group('PregameTelemetryBuffer clock sync', () {
    test('pose sensor and events share the run offset timeline', () {
      final t0 = DateTime.utc(2026, 9, 18, 12, 0, 0);
      final buf = PregameTelemetryBuffer(
        clock: SessionClock(source: () => t0),
        poseMinIntervalMs: 0,
        sensorMinIntervalMs: 0,
      );
      buf.start(at: t0);

      buf.addPose(const [
        LandmarkPoint(
          index: 0,
          x: 0.5,
          y: 0.3,
          z: 0,
          visibility: 0.9,
          presence: 0.8,
        ),
      ], at: t0.add(const Duration(milliseconds: 100)));
      buf.addSensor(
        ax: 0,
        ay: 0,
        az: 9.8,
        angle: 90,
        at: t0.add(const Duration(milliseconds: 120)),
      );
      buf.addEvent(
        'stability_ok',
        at: t0.add(const Duration(milliseconds: 150)),
      );

      final payload = buf.finish(
        gameMode: 'leftHand',
        status: 'completed',
        at: t0.add(const Duration(seconds: 1)),
      );

      final started = payload['started_offset_ms'] as int;
      final ended = payload['ended_offset_ms'] as int;

      expect((started, ended), (0, 1000));
      expect(buf.poseSamples.first['offsetMs'], 100);
      final pose = buf.poseSamples.first['pose'] as List;
      expect((pose.single as Map)['p'], 0.8);
      expect(buf.poseSamples.first, isNot(contains('landmarks')));
      expect(buf.sensorSamples.first['offsetMs'], 120);

      final eventOffsets = (payload['events'] as List)
          .map((e) => (e as Map)['offsetMs'] as int)
          .toList();
      expect(eventOffsets, containsAll([0, 150, 1000]));
      expect(eventOffsets.every((t) => t >= started && t <= ended), isTrue);
      expectNoEpoch(payload);
    });

    test('throttling treats offset 0 as a real sample', () {
      final t0 = DateTime.utc(2026, 9, 18, 12);
      final buf = PregameTelemetryBuffer(
        clock: SessionClock(source: () => t0),
        sensorMinIntervalMs: 50,
      );
      buf.start(at: t0);

      for (final ms in [0, 20, 49, 50, 60, 100]) {
        buf.addSensor(
          ax: 0,
          ay: 0,
          az: 9.8,
          at: t0.add(Duration(milliseconds: ms)),
        );
      }

      expect(buf.sensorSamples.map((s) => s['offsetMs']), [0, 50, 100]);
    });
  });
}
