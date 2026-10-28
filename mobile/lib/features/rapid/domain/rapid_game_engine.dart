import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';
import 'package:msupperlimbs/features/motion/domain/session_clock.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/finger_tap_detector.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/pulse_line_controller.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/pulse_line_state.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/rapid_motion_factory.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_phase.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_result.dart';

/// Owns pre-game → play → finish flow, tap counting, pulse physics and telemetry.
class RapidGameEngine {
  RapidGameEngine({
    required RapidSettings settings,
    required this.clock,
    this.handHoldDuration = const Duration(seconds: 2),
    this.poseSampleEveryNFrames = 1,
    void Function()? this._onChanged,
  }) : _settings = settings,
       _tap = RapidMotionFactory.tapDetector(settings),
       _pulse = RapidMotionFactory.pulseController(settings),
       remainingSeconds = settings.totalTime,
       totalSeconds = settings.totalTime {
    _pulse.onImpulse = (before, after, strength) {
      if (phase != RapidGamePhase.playing) return;
      final at = _impulseAt ?? clock.now();
      _pulseEvents.add({
        't': at.toUtc().millisecondsSinceEpoch,
        'pulseHeight': after,
        'pulseState': _pulse.state.name,
        'eventType': 'impulse',
        'additionalData': {
          'heightBefore': before,
          'heightAfter': after,
          'impulseStrength': strength,
        },
      });
      _maxPulseHeight = _maxPulseHeight == null
          ? after
          : (_maxPulseHeight! > after ? _maxPulseHeight : after);
      _pulseHeightSum += after;
      _pulseHeightSamples += 1;
    };
  }

  final RapidSettings _settings;
  final SessionClock clock;
  final Duration handHoldDuration;
  final int poseSampleEveryNFrames;
  final void Function()? _onChanged;

  final FingerTapDetector _tap;
  final PulseLineController _pulse;

  RapidGamePhase phase = RapidGamePhase.waitingHand;
  int remainingSeconds;
  final int totalSeconds;
  int tapCount = 0;
  bool handPresent = false;

  int? screenWidth;
  int? screenHeight;
  int? imageWidth;
  int? imageHeight;
  Map<String, double>? preview;

  DateTime? _holdStartedAt;
  DateTime? _lastPhysicsAt;
  DateTime? _lastHoldSampleAt;
  DateTime? _impulseAt;
  int _handFrameCounter = 0;

  final List<Map<String, dynamic>> _tapEvents = [];
  final List<Map<String, dynamic>> _pulseEvents = [];
  final List<Map<String, dynamic>> _poseSamples = [];
  double? _maxPulseHeight;
  double _pulseHeightSum = 0;
  int _pulseHeightSamples = 0;

  FingerTapDetector get tapDetector => _tap;
  PulseLineController get pulse => _pulse;
  RapidSettings get settings => _settings;

  RapidGameResult get result {
    final avgPulse = _pulseHeightSamples == 0
        ? null
        : _pulseHeightSum / _pulseHeightSamples;
    return RapidGameResult(
      tapCount: tapCount,
      durationSeconds: totalSeconds,
      gameMode: _settings.gameMode,
      visualizationType: _settings.visualizationType,
      tapEvents: List.unmodifiable(_tapEvents),
      pulseEvents: List.unmodifiable(_pulseEvents),
      poseSamples: List.unmodifiable(_poseSamples),
      avgPulseHeight: avgPulse,
      maxPulseHeight: _maxPulseHeight,
      settingsSnapshot: _settings.toUpdateJson(),
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      startedAtMs: clock.startedAt.millisecondsSinceEpoch,
      endedAtMs: clock.nowMs(),
      preview: preview,
    );
  }

  void notify() => _onChanged?.call();

  void onHands(List<LandmarkPoint> hands, DateTime now) {
    handPresent = hands.isNotEmpty;
    _handFrameCounter += 1;
    if (_handFrameCounter % poseSampleEveryNFrames == 0) {
      _samplePose(hands, now);
    }

    switch (phase) {
      case RapidGamePhase.waitingHand:
        if (handPresent) {
          phase = RapidGamePhase.holdingHand;
          _holdStartedAt = now;
          _lastHoldSampleAt = now;
          notify();
        }
      case RapidGamePhase.holdingHand:
        _lastHoldSampleAt = now;
        if (!handPresent) {
          phase = RapidGamePhase.waitingHand;
          _holdStartedAt = null;
          notify();
        } else if (_holdStartedAt != null &&
            now.difference(_holdStartedAt!) >= handHoldDuration) {
          phase = RapidGamePhase.countdown;
          _holdStartedAt = null;
          notify();
        } else {
          notify();
        }
      case RapidGamePhase.countdown:
      case RapidGamePhase.finished:
        break;
      case RapidGamePhase.playing:
        _processTaps(hands, now);
    }
  }

  void beginPlaying() {
    if (phase != RapidGamePhase.countdown) return;
    phase = RapidGamePhase.playing;
    remainingSeconds = totalSeconds;
    tapCount = 0;
    _tap.reset();
    _pulse.reset();
    _pulse.state = PulseLineState.active;
    _lastPhysicsAt = null;
    // Mantém o contador e os samples capturados no pré-jogo.
    _tapEvents.clear();
    _pulseEvents.clear();
    _maxPulseHeight = null;
    _pulseHeightSum = 0;
    _pulseHeightSamples = 0;
    notify();
  }

  void onCountdownFinished() => beginPlaying();

  void tickPhysics(DateTime now) {
    if (phase != RapidGamePhase.playing) return;
    final last = _lastPhysicsAt;
    _lastPhysicsAt = now;
    if (last == null) return;
    var dt = now.difference(last).inMicroseconds / 1e6;
    if (_settings.useFixedDt) {
      dt = _settings.fixedDtSeconds;
    }
    if (dt <= 0 || dt > 0.25) return;
    _pulse.tick(dt);
    final y = _pulse.currentY;
    _maxPulseHeight = _maxPulseHeight == null
        ? y
        : (_maxPulseHeight! > y ? _maxPulseHeight : y);
    _pulseHeightSum += y;
    _pulseHeightSamples += 1;
    // Subsample pulse ticks for storage (~3 Hz when fixedDt≈1/30).
    if (_pulseHeightSamples % 10 == 0) {
      _pulseEvents.add({
        't': now.toUtc().millisecondsSinceEpoch,
        'pulseHeight': y,
        'pulseState': _pulse.state.name,
        'eventType': 'tick',
      });
    }
    notify();
  }

  void onSecondElapsed() {
    if (phase != RapidGamePhase.playing) return;
    remainingSeconds -= 1;
    if (remainingSeconds <= 0) {
      remainingSeconds = 0;
      phase = RapidGamePhase.finished;
    }
    notify();
  }

  double get holdProgress {
    if (phase != RapidGamePhase.holdingHand || _holdStartedAt == null) {
      return 0;
    }
    final sample = _lastHoldSampleAt ?? _holdStartedAt!;
    final elapsed = sample.difference(_holdStartedAt!).inMilliseconds;
    return (elapsed / handHoldDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  void _samplePose(List<LandmarkPoint> hands, DateTime now) {
    _poseSamples.add({
      't': now.toUtc().millisecondsSinceEpoch,
      'phase': phase.name,
      'pose': const <Map<String, dynamic>>[],
      'hands': [for (final p in hands) p.toKinematicJson()],
    });
  }

  void _processTaps(List<LandmarkPoint> hands, DateTime now) {
    final byHand = <int, List<LandmarkPoint>>{};
    for (final p in hands) {
      byHand.putIfAbsent(p.handIndex ?? 0, () => []).add(p);
    }

    final mode = _settings.gameMode;
    final entries = byHand.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    Iterable<MapEntry<int, List<LandmarkPoint>>> selected = entries;
    if (mode != 'bothHands' && entries.isNotEmpty) {
      selected = [entries.first];
    }

    for (final entry in selected) {
      final before = _pulse.currentY;
      if (_tap.updateFromPoints(entry.value, now)) {
        tapCount += 1;
        _impulseAt = now;
        _pulse.impulse();
        _impulseAt = null;
        _tapEvents.add({
          't': now.toUtc().millisecondsSinceEpoch,
          'tappedFinger': 'tip',
          'handIndex': entry.key,
          'pulseHeightBefore': before,
          'pulseHeightAfter': _pulse.currentY,
          'tapSensitivity': _settings.tapSensitivity,
        });
        notify();
        break;
      }
    }
  }
}
