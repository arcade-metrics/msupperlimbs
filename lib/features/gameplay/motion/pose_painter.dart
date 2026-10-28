import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'coordinates_translator.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  PosePainter(
    this.poses,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final detailedPoints = <PoseLandmarkType>{};
    final simplePoints = <PoseLandmarkType>{
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftIndex,
      PoseLandmarkType.rightIndex,
    };

    final greenDotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.greenAccent;

    final rightOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = Colors.blue.withAlpha((0.5 * 255).round());
    final rightMiddle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.transparent;
    final rightCenter = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blueAccent.withAlpha((0.9 * 255).round());

    final leftOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = Colors.orange.withAlpha((0.5 * 255).round());
    final leftMiddle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.transparent;
    final leftCenter = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.deepOrange.withAlpha((0.9 * 255).round());

    for (final pose in poses) {
      pose.landmarks.forEach((type, landmark) {
        Offset point;

        if (Platform.isIOS) {
          point = translateLandmarkIOS(
            x: landmark.x,
            y: landmark.y,
            imageSize: imageSize,
            canvasSize: size,
            rotation: rotation,
            lensDirection: cameraLensDirection,
            fit: BoxFit.cover,
            previewIsMirrored: true,
          );
        } else {
          // Android: usa a nova função translateLandmark que rotaciona 90° anti-horário
          point = translateLandmark(
            x: landmark.x,
            y: landmark.y,
            canvasSize: size,
            imageSize: imageSize,
            rotation: rotation,
            cameraLensDirection: cameraLensDirection,
          );
        }

        if (detailedPoints.contains(type)) {
          final isRight = type == PoseLandmarkType.rightIndex;
          final outer = isRight ? rightOuter : leftOuter;
          final middle = isRight ? rightMiddle : leftMiddle;
          final center = isRight ? rightCenter : leftCenter;
          canvas.drawCircle(point, 24, outer);
          canvas.drawCircle(point, 16, middle);
          canvas.drawCircle(point, 10, center);
        } else if (simplePoints.contains(type)) {
          canvas.drawCircle(point, 3, greenDotPaint);
        }
      });
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.poses != poses;
  }
}
