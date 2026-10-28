import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/spark_state_enum.dart';
import 'package:msupperlimbs/features/gameplay/motion/image_rotation.dart';

class FNoseCameraWithLandmarks extends StatelessWidget {
  final Widget cameraPreview;
  final CustomPaint? landmarksOverlay;
  final Size imageSize;
  final CameraLensDirection cameraLensDirection;
  final ImageRotation rotation; // já está usando para proporção
  final bool mirrorHorizontal;
  final bool mirrorVertical;
  final bool showLandmarks;

  // === NOVO: offsets prontos do pipeline unificado ===
  final Offset? noseOffset;

  // já existiam
  final Offset? leftIndex;
  final Offset? rightIndex;
  final SparkState leftSparkState;
  final SparkState rightSparkState;

  const FNoseCameraWithLandmarks({
    super.key,
    required this.cameraPreview,
    this.landmarksOverlay,
    required this.imageSize,
    required this.cameraLensDirection,
    required this.rotation,
    this.mirrorHorizontal = false,
    this.mirrorVertical = false,
    this.showLandmarks = false,
    this.noseOffset, // <— NOVO
    required this.leftIndex,
    required this.rightIndex,
    required this.leftSparkState,
    required this.rightSparkState,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular displaySize baseado na rotação da imagem
    // Isso garante consistência entre plataformas
    final isRotated = rotation == ImageRotation.rotation90deg ||
        rotation == ImageRotation.rotation270deg;
    
    // Unificar lógica: quando a imagem vier rotacionada (90/270), 
    // o display interno deve usar as dimensões trocadas para manter proporção consistente
    final Size displaySize = isRotated
        ? Size(imageSize.height, imageSize.width)
        : imageSize;

    final isFront = cameraLensDirection == CameraLensDirection.front;
    // mirrorHorizontal=true -> mirror horizontally (-1), false -> don't mirror (1)
    final mirrorX = mirrorHorizontal ? -1.0 : 1.0;
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
              transform: Matrix4.diagonal3Values(mirrorX, mirrorY, 1.0),
              child: cameraPreview,
            ),

            // === iOS: usar offsets prontos (pipeline único) para o nariz ===
            if (Platform.isIOS && showLandmarks && noseOffset != null)
              Positioned(
                left: noseOffset!.dx - 3,
                top: noseOffset!.dy - 3,
                child: IgnorePointer(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

            // Android/Web: mantém overlay original
            if (!Platform.isIOS && showLandmarks && landmarksOverlay != null)
              landmarksOverlay!,
          ],
        ),
      ),
    );
  }
}
