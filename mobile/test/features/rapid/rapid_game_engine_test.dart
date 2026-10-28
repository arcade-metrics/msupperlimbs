import 'package:flutter_test/flutter_test.dart';
import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';
import 'package:msupperlimbs/features/motion/domain/session_clock.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_engine.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_phase.dart';

RapidSettings _settings({int totalTime = 5}) {
  return RapidSettings(
    userId: 'u',
    showInfoVideo: false,
    totalTime: totalTime,
    gameMode: 'rightHand',
    visualizationType: 'line',
    tapSensitivity: 0.04,
    tapCooldownMs: 50,
    maxPoints: 20,
    minY: 0,
    maxY: 1,
    baseline: 0.25,
    gravityPerSecond: 0.2,
    impulseStrength: 0.1,
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

List<LandmarkPoint> _handClose({double tipDx = 0.02}) {
  return [
    const LandmarkPoint(index: 4, x: 0.5, y: 0.5, z: 0, handIndex: 0),
    LandmarkPoint(index: 8, x: 0.5 + tipDx, y: 0.5, z: 0, handIndex: 0),
    const LandmarkPoint(index: 12, x: 0.9, y: 0.9, z: 0, handIndex: 0),
    const LandmarkPoint(index: 16, x: 0.9, y: 0.9, z: 0, handIndex: 0),
    const LandmarkPoint(index: 20, x: 0.9, y: 0.9, z: 0, handIndex: 0),
  ];
}

void main() {
  SessionClock clock() => SessionClock(source: () => DateTime.utc(2026, 1, 1));

  test('pregame: hand hold advances to countdown', () {
    final engine = RapidGameEngine(
      settings: _settings(),
      clock: clock(),
      handHoldDuration: const Duration(milliseconds: 100),
    );
    final t0 = DateTime.utc(2026, 1, 1);
    expect(engine.phase, RapidGamePhase.waitingHand);

    engine.onHands(_handClose(tipDx: 0.2), t0);
    expect(engine.phase, RapidGamePhase.holdingHand);

    engine.onHands(
      _handClose(tipDx: 0.2),
      t0.add(const Duration(milliseconds: 120)),
    );
    expect(engine.phase, RapidGamePhase.countdown);
  });

  test('playing counts taps and finishes on timer', () {
    final engine = RapidGameEngine(
      settings: _settings(totalTime: 2),
      clock: clock(),
    );
    engine.phase = RapidGamePhase.countdown;
    engine.onCountdownFinished();
    expect(engine.phase, RapidGamePhase.playing);

    final t0 = DateTime.utc(2026, 1, 1, 12);
    engine.onHands(_handClose(tipDx: 0.2), t0);
    engine.onHands(
      _handClose(tipDx: 0.02),
      t0.add(const Duration(milliseconds: 20)),
    );
    expect(engine.tapCount, 1);
    final eventT = t0
        .add(const Duration(milliseconds: 20))
        .millisecondsSinceEpoch;
    expect(engine.result.tapEvents.single['t'], eventT);
    expect(
      engine.result.pulseEvents
          .where((event) => event['eventType'] == 'impulse')
          .single['t'],
      eventT,
    );
    expect(
      engine.result.poseSamples.any((sample) => sample['t'] == eventT),
      isTrue,
    );

    engine.onSecondElapsed();
    expect(engine.remainingSeconds, 1);
    engine.onSecondElapsed();
    expect(engine.phase, RapidGamePhase.finished);
    expect(engine.result.tapCount, 1);
  });

  test('losing hand during hold resets to waiting', () {
    final engine = RapidGameEngine(
      settings: _settings(),
      clock: clock(),
      handHoldDuration: const Duration(seconds: 3),
    );
    final t0 = DateTime.utc(2026, 1, 1);
    engine.onHands(_handClose(), t0);
    expect(engine.phase, RapidGamePhase.holdingHand);
    engine.onHands(const [], t0.add(const Duration(milliseconds: 50)));
    expect(engine.phase, RapidGamePhase.waitingHand);
  });
}
