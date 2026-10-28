import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'coordinates_translator.dart';
import 'mediapipe_types.dart';

class MediaPipePosePainter extends CustomPainter {
  final MediaPipePose pose;
  final Size imageSize;
  final CameraLensDirection cameraLensDirection;
  final int rotationDegrees; // Backward compatibility
  final int outputRotationDegrees; // New: OUTPUT rotation for display
  final bool outputMirrorHorizontal; // New: OUTPUT mirror for display
  final bool outputMirrorVertical; // New: OUTPUT mirror for display

  MediaPipePosePainter({
    required this.pose,
    required this.imageSize,
    required this.cameraLensDirection,
    this.rotationDegrees = 0, // Backward compatibility
    this.outputRotationDegrees = 0,
    this.outputMirrorHorizontal = false,
    this.outputMirrorVertical = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pose.landmarks.isEmpty) return;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.greenAccent;

    final isFront = cameraLensDirection == CameraLensDirection.front;

    for (final lm in pose.landmarks) {
      // Only draw nose landmark (index 0)
      if (lm.index != 0) continue;
      
      // MediaPipe fornece x/y normalizados [0,1]
      final pt = translateNormalizedLive(
        nx: lm.x,
        ny: lm.y,
        imageSize: imageSize,
        canvasSize: size,
        isFrontCamera: isFront,
        rotationDegrees: rotationDegrees, // Backward compatibility
        outputRotationDegrees: outputRotationDegrees,
        outputMirrorHorizontal: outputMirrorHorizontal,
        outputMirrorVertical: outputMirrorVertical,
      );
      canvas.drawCircle(pt, 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MediaPipePosePainter oldDelegate) {
    return oldDelegate.pose != pose || 
           oldDelegate.imageSize != imageSize ||
           oldDelegate.rotationDegrees != rotationDegrees ||
           oldDelegate.outputRotationDegrees != outputRotationDegrees ||
           oldDelegate.outputMirrorHorizontal != outputMirrorHorizontal ||
           oldDelegate.outputMirrorVertical != outputMirrorVertical;
  }
}


