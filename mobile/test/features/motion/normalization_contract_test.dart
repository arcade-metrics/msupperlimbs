import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:msupperlimbs/features/motion/data/mediapipe_service.dart';
import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';
import 'package:msupperlimbs/features/motion/domain/screen_mapper.dart';
import 'package:msupperlimbs/features/motion/domain/session_clock.dart';

void main() {
  test('landmark serializes raw kinematics including presence', () {
    const point = LandmarkPoint(
      index: 11,
      x: 0.2,
      y: 0.3,
      z: -0.1,
      visibility: 0.9,
      presence: 0.8,
    );
    expect(point.toKinematicJson(), {
      'i': 11,
      'x': 0.2,
      'y': 0.3,
      'z': -0.1,
      'v': 0.9,
      'p': 0.8,
    });
  });

  test('screen mapper emits normalized screen coordinates', () {
    const mapper = ScreenMapper(
      screenSize: Size(1000, 500),
      previewRect: Rect.fromLTWH(-100, 0, 1200, 500),
    );
    const point = LandmarkPoint(index: 0, x: 0.5, y: 0.25, z: 0);
    expect(mapper.toScreen(point), const Offset(0.5, 0.25));
    expect(mapper.radiusToPixels(0.1), 50);
    expect(mapper.normalizedPreview['left'], -0.1);
  });

  test('mirrored frames restore the real anatomical side', () {
    int mapped(int index) =>
        MediaPipeService.anatomicalPoseIndex(index, mirrored: true);
    expect(mapped(19), 20);
    expect(mapped(20), 19);
    expect(mapped(11), 12);
    expect(mapped(0), 0);
    expect(MediaPipeService.anatomicalPoseIndex(19, mirrored: false), 19);
  });

  test('session clock counts offsets from the run start', () {
    var now = DateTime.utc(2026, 9, 19, 12, 30);
    final clock = SessionClock(source: () => now);
    expect(clock.startedAt, now);
    expect(clock.offsetMs(), 0);

    now = now.add(const Duration(milliseconds: 1500));
    expect(clock.offsetMs(), 1500);
    expect(
      clock.offsetMs(clock.startedAt.add(const Duration(seconds: 2))),
      2000,
    );
    expect(
      clock.offsetMs(clock.startedAt.subtract(const Duration(seconds: 1))),
      0,
      reason: 'never negative',
    );
  });

  test('default session clock is monotonic from zero', () async {
    final clock = SessionClock();
    final first = clock.offsetMs();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final second = clock.offsetMs();
    expect(first, inInclusiveRange(0, 5));
    expect(second, greaterThanOrEqualTo(first + 15));
  });
}
