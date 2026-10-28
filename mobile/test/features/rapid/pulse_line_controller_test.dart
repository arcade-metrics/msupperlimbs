import 'package:flutter_test/flutter_test.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/pulse_line_controller.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/pulse_line_state.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/rapid_motion_factory.dart';

void main() {
  group('PulseLineController', () {
    test('starts at baseline with a full window', () {
      final c = PulseLineController(maxPoints: 10, baseline: 0.25);
      expect(c.currentY, 0.25);
      expect(c.points, everyElement(0.25));
      expect(c.points.length, 10);
    });

    test('tick applies gravity and lowers height', () {
      final c = PulseLineController(
        maxPoints: 8,
        baseline: 0.5,
        gravityPerSecond: 0.5,
        decayRateIdle: 0,
        decayRateActive: 0,
        decayRateUnstable: 0,
        decayRateFlatline: 0,
      );
      c.tick(0.2); // fall 0.1
      expect(c.currentY, closeTo(0.4, 1e-9));
    });

    test('impulse raises height and clamps to maxY', () {
      final c = PulseLineController(
        maxPoints: 8,
        baseline: 0.9,
        impulseStrength: 0.2,
        maxY: 1.0,
      );
      c.impulse();
      expect(c.currentY, 1.0);
    });

    test('floor restitution lifts off minY when configured', () {
      final c = PulseLineController(
        maxPoints: 8,
        baseline: 0.25,
        minY: 0,
        gravityPerSecond: 10,
        decayRateIdle: 0,
        floorRestitution: 0.5,
      );
      c.tick(1); // would fall far below 0
      expect(c.currentY, closeTo(0.125, 1e-9)); // 0 + (0.25-0)*0.5
    });

    test('active state decays slower than idle for same gravity', () {
      PulseLineController make(PulseLineState state) {
        return PulseLineController(
          maxPoints: 4,
          baseline: 0.8,
          gravityPerSecond: 0.2,
          decayRateIdle: 0.1,
          decayRateActive: 0.0,
          initialState: state,
        );
      }

      final idle = make(PulseLineState.idle)..tick(1);
      final active = make(PulseLineState.active)..tick(1);
      expect(active.currentY, greaterThan(idle.currentY));
    });

    test('sliding window keeps maxPoints', () {
      final c = PulseLineController(maxPoints: 5, baseline: 0.2);
      for (var i = 0; i < 20; i++) {
        c.impulse(0.01);
      }
      expect(c.points.length, 5);
    });

    test('onImpulse callback receives before/after', () {
      final c = PulseLineController(
        maxPoints: 4,
        baseline: 0.2,
        impulseStrength: 0.1,
      );
      double? before;
      double? after;
      c.onImpulse = (b, a, _) {
        before = b;
        after = a;
      };
      c.impulse();
      expect(before, 0.2);
      expect(after, closeTo(0.3, 1e-9));
    });

    test('fromSettings / factory wire RapidSettings params', () {
      final settings = RapidSettings(
        userId: 'u',
        showInfoVideo: true,
        totalTime: 30,
        gameMode: 'rightHand',
        visualizationType: 'line',
        tapSensitivity: 0.04,
        tapCooldownMs: 110,
        maxPoints: 12,
        minY: 0,
        maxY: 1,
        baseline: 0.3,
        gravityPerSecond: 0.4,
        impulseStrength: 0.08,
        floorRestitution: 0,
        decayRateIdle: 0.05,
        decayRateActive: 0.03,
        decayRateUnstable: 0.07,
        decayRateFlatline: 0.10,
        lineColor: null,
        lineWidth: 3,
        glowEnabled: true,
        glowBlurSigma: 8,
        useFixedDt: true,
        fixedDtSeconds: 1 / 30,
        pulseMaxIntensity: 0.6,
        pulseGravity: 0.003,
        pulseImpulse: 0.16,
        updatedAt: DateTime.utc(2026),
      );

      final pulse = RapidMotionFactory.pulseController(settings);
      expect(pulse.maxPoints, 12);
      expect(pulse.baseline, 0.3);
      expect(pulse.gravityPerSecond, 0.4);
      expect(pulse.impulseStrength, 0.08);

      final tap = RapidMotionFactory.tapDetector(settings);
      expect(tap.dOn, closeTo(0.04, 1e-9));
      expect(tap.cooldownMs, 110);
    });

    test('reset restores baseline window', () {
      final c = PulseLineController(maxPoints: 6, baseline: 0.25)
        ..impulse(0.5)
        ..reset();
      expect(c.currentY, 0.25);
      expect(c.points, everyElement(0.25));
    });
  });
}
