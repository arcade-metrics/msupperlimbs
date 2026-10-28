import 'package:flutter_test/flutter_test.dart';
import 'package:msupperlimbs/features/fnose/domain/pregame_telemetry_buffer.dart';
import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';
import 'package:msupperlimbs/features/motion/domain/session_clock.dart';

void main() {
  group('PregameTelemetryBuffer clock sync', () {
    test('pose sensor and events share same t timeline', () {
      final buf = PregameTelemetryBuffer(
        clock: SessionClock(source: () => DateTime.utc(2026, 9, 18, 12)),
        poseMinIntervalMs: 0,
        sensorMinIntervalMs: 0,
      );
      final t0 = DateTime.utc(2026, 9, 18, 12, 0, 0);
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

      final started = payload['started_at_ms'] as int;
      final ended = payload['ended_at_ms'] as int;

      expect(started, t0.millisecondsSinceEpoch);
      expect(buf.poseSamples.first['t'], t0.millisecondsSinceEpoch + 100);
      final pose = buf.poseSamples.first['pose'] as List;
      expect((pose.single as Map)['p'], 0.8);
      expect(buf.poseSamples.first, isNot(contains('landmarks')));
      expect(buf.sensorSamples.first['t'], t0.millisecondsSinceEpoch + 120);

      final eventTs = (payload['events'] as List)
          .map((e) => (e as Map)['t'] as int)
          .toList();
      expect(eventTs, contains(t0.millisecondsSinceEpoch));
      expect(eventTs, contains(t0.millisecondsSinceEpoch + 150));
      expect(eventTs, contains(t0.millisecondsSinceEpoch + 1000));
      expect(eventTs.every((t) => t >= started && t <= ended), isTrue);
    });
  });
}
