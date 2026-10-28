import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_mlkit_commons/google_mlkit_commons.dart'; // InputImageRotation

class CameraWithLandmarks extends StatelessWidget {
  final Widget cameraPreview;
  final CustomPaint? landmarksOverlay;
  final Size imageSize;
  final CameraLensDirection cameraLensDirection;
  final bool mirrorHorizontal;
  final bool mirrorVertical;
  final bool showLandmarks;

  // NOVO: usado apenas para calcular proporção (dw, dh) no iOS
  final InputImageRotation rotation;

  const CameraWithLandmarks({
    super.key,
    required this.cameraPreview,
    this.landmarksOverlay,
    required this.imageSize,
    required this.cameraLensDirection,
    this.mirrorHorizontal = false,
    this.mirrorVertical = false,
    this.showLandmarks = true,
    // NOVO: obrigatório para termos (dw, dh) coerentes com o preview no iOS
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    // iOS: usa dimensões pós-rotação (dw, dh). Android/Web: mantém lógica atual.
    Size displaySize;
    if (Platform.isIOS) {
      final iw = imageSize.width;
      final ih = imageSize.height;
      late double dw, dh;
      switch (rotation) {
        case InputImageRotation.rotation0deg:
        case InputImageRotation.rotation180deg:
          dw = iw;
          dh = ih;
          break;
        case InputImageRotation.rotation90deg:
        case InputImageRotation.rotation270deg:
          dw = ih;
          dh = iw;
          break;
      }
      displaySize = Size(dw, dh);
    } else {
      final isPortrait = imageSize.height > imageSize.width;
      displaySize =
          isPortrait ? Size(imageSize.height, imageSize.width) : imageSize;
    }

    final isFrontCamera = cameraLensDirection == CameraLensDirection.front;

    final mirrorX = mirrorHorizontal
        ? (isFrontCamera ? 1.0 : -1.0)
        : (isFrontCamera ? -1.0 : 1.0);

    final mirrorY = mirrorVertical ? -1.0 : 1.0;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: displaySize.width,
        height: displaySize.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(
                mirrorX,
                mirrorY,
                1.0, // Always 1.0 for 2D images.
              ),
              child: cameraPreview,
            ),
            if (showLandmarks && landmarksOverlay != null) landmarksOverlay!,
          ],
        ),
      ),
    );
  }
}
