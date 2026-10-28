import 'package:flutter_test/flutter_test.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/finger_tap_detector.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/mp_tip_index.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings.dart';

void main() {
  group('FingerTapDetector', () {
    late FingerTapDetector detector;
    final t0 = DateTime.utc(2026, 1, 1, 12);

    setUp(() {
      detector = FingerTapDetector(dOn: 0.04, dOff: 0.055, cooldownMs: 100);
    });

    Map<int, TapLandmark> hand({
      required double tipDist,
      int tip = MpTipIndex.index,
    }) {
      return {
        MpTipIndex.thumb: const TapLandmark(0.5, 0.5),
        tip: TapLandmark(0.5 + tipDist, 0.5),
        for (final other in MpTipIndex.nonThumbTips)
          if (other != tip) other: const TapLandmark(0.9, 0.9),
      };
    }

    test('does not fire when tips stay far from thumb', () {
      expect(detector.update(hand(tipDist: 0.2), t0), isFalse);
      expect(
        detector.update(
          hand(tipDist: 0.2),
          t0.add(const Duration(milliseconds: 50)),
        ),
        isFalse,
      );
    });

    test('fires on rising edge when tip crosses dOn', () {
      expect(detector.update(hand(tipDist: 0.2), t0), isFalse);
      expect(
        detector.update(
          hand(tipDist: 0.02),
          t0.add(const Duration(milliseconds: 16)),
        ),
        isTrue,
      );
    });

    test('does not re-fire while tip stays close (hysteresis)', () {
      final t1 = t0.add(const Duration(milliseconds: 16));
      expect(detector.update(hand(tipDist: 0.02), t1), isTrue);
      expect(
        detector.update(
          hand(tipDist: 0.03),
          t1.add(const Duration(milliseconds: 200)),
        ),
        isFalse,
      );
    });

    test('can fire again after leaving beyond dOff and cooldown', () {
      var t = t0;
      expect(detector.update(hand(tipDist: 0.02), t), isTrue);
      t = t.add(const Duration(milliseconds: 20));
      // still close (between dOn and dOff) — stay latched
      expect(detector.update(hand(tipDist: 0.05), t), isFalse);
      t = t.add(const Duration(milliseconds: 20));
      // leave
      expect(detector.update(hand(tipDist: 0.2), t), isFalse);
      t = t.add(const Duration(milliseconds: 150));
      // re-enter after cooldown
      expect(detector.update(hand(tipDist: 0.02), t), isTrue);
    });

    test('respects cooldown between taps', () {
      var t = t0;
      expect(detector.update(hand(tipDist: 0.02), t), isTrue);
      t = t.add(const Duration(milliseconds: 20));
      expect(detector.update(hand(tipDist: 0.2), t), isFalse);
      t = t.add(const Duration(milliseconds: 50)); // < 100ms cooldown
      expect(detector.update(hand(tipDist: 0.02), t), isFalse);
    });

    test('missing thumb never fires', () {
      final landmarks = {MpTipIndex.index: const TapLandmark(0.5, 0.5)};
      expect(detector.update(landmarks, t0), isFalse);
    });

    test('fromSettings uses normalized MediaPipe sensitivity', () {
      final settings = _fixtureSettings(
        tapSensitivity: 0.04,
        tapCooldownMs: 120,
      );
      final d = FingerTapDetector.fromSettings(settings);
      expect(d.dOn, closeTo(0.04, 1e-9));
      expect(d.dOff, closeTo(0.055, 1e-9));
      expect(d.cooldownMs, 120);
    });

    test('reset clears latch and cooldown', () {
      expect(detector.update(hand(tipDist: 0.02), t0), isTrue);
      detector.reset();
      expect(detector.lastTapAt, isNull);
      expect(
        detector.update(
          hand(tipDist: 0.02),
          t0.add(const Duration(milliseconds: 10)),
        ),
        isTrue,
      );
    });
  });
}

RapidSettings _fixtureSettings({
  double tapSensitivity = 0.04,
  int tapCooldownMs = 110,
}) {
  return RapidSettings(
    userId: 'test',
    showInfoVideo: true,
    totalTime: 30,
    gameMode: 'rightHand',
    visualizationType: 'line',
    tapSensitivity: tapSensitivity,
    tapCooldownMs: tapCooldownMs,
    maxPoints: 420,
    minY: 0,
    maxY: 1,
    baseline: 0.25,
    gravityPerSecond: 0.35,
    impulseStrength: 0.06,
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
}
