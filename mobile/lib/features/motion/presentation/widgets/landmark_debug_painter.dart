import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';

class LandmarkDebugPainter extends CustomPainter {
  LandmarkDebugPainter({
    required this.pose,
    required this.hands,
    this.mirrorHorizontal = false,
  });

  final List<LandmarkPoint> pose;
  final List<LandmarkPoint> hands;
  final bool mirrorHorizontal;

  static const _poseConnections = <List<int>>[
    [11, 12],
    [11, 13],
    [13, 15],
    [15, 19],
    [12, 14],
    [14, 16],
    [16, 20],
    [0, 11],
    [0, 12],
  ];

  Offset _toOffset(LandmarkPoint p, Size size) {
    final x = mirrorHorizontal ? (1.0 - p.x) : p.x;
    return Offset(x * size.width, p.y * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final posePaint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final poseFill = Paint()..color = const Color(0xFF27AE60);
    final handPaint = Paint()
      ..color = const Color(0xFF3498DB)
      ..strokeWidth = 2;
    final handFill = Paint()..color = const Color(0xFF2980B9);

    final poseMap = {for (final p in pose) p.index: p};

    for (final pair in _poseConnections) {
      final a = poseMap[pair[0]];
      final b = poseMap[pair[1]];
      if (a == null || b == null) continue;
      canvas.drawLine(_toOffset(a, size), _toOffset(b, size), posePaint);
    }

    for (final p in pose) {
      canvas.drawCircle(_toOffset(p, size), 5, poseFill);
    }

    for (final p in hands) {
      canvas.drawCircle(_toOffset(p, size), 3, handFill);
    }

    final byHand = <int, List<LandmarkPoint>>{};
    for (final p in hands) {
      byHand.putIfAbsent(p.handIndex ?? 0, () => []).add(p);
    }
    for (final points in byHand.values) {
      points.sort((a, b) => a.index.compareTo(b.index));
      for (var i = 0; i < points.length - 1; i++) {
        if (points[i + 1].index != points[i].index + 1) continue;
        canvas.drawLine(
          _toOffset(points[i], size),
          _toOffset(points[i + 1], size),
          handPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LandmarkDebugPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.hands != hands ||
        oldDelegate.mirrorHorizontal != mirrorHorizontal;
  }
}
