import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

// Nova função que traduz coordenadas com rotação 90° anti-horário para Android
Offset translateLandmark({
  required double x,
  required double y,
  required Size canvasSize,
  required Size imageSize,
  required InputImageRotation rotation,
  required CameraLensDirection cameraLensDirection,
  BoxFit fit = BoxFit.cover,
}) {
  // Para câmera frontal no Android, aplicar apenas ESCALA LINEAR (sem BoxFit interno aqui)
  // O preview já está dentro de um FittedBox(BoxFit.cover), então o canvasSize aqui
  // corresponde ao displaySize do preview. Precisamos apenas escalar de imageSize -> canvasSize.
  if (cameraLensDirection == CameraLensDirection.front && !Platform.isIOS) {
    // Alinhamento correto para câmera frontal com preview espelhado:
    // 1) Rotação 90° anti-horário: (x,y) -> (y, x)
    // 2) Flip horizontal para espelhar como o preview
    final rotatedX = y;
    final rotatedY = x;

    final rotatedW = imageSize.height; // largura após rotação
    final rotatedH = imageSize.width;  // altura após rotação

    // Escala linear da imagem rotacionada para o displaySize (canvasSize)
    // Ajuste leve de alinhamento para evitar deslocamento à direita
    final scaleX = canvasSize.width / rotatedW;
    final scaleY = canvasSize.height / rotatedH;

    final scaledX = rotatedX * scaleX;
    final scaledY = rotatedY * scaleY;

    // Espelhamento horizontal para corresponder ao preview espelhado
    final mirroredX = scaledX; // sem flip neste estágio

    return Offset(mirroredX, scaledY);
  }
  
  // Lógica original para outros casos
  final translatedX = translateX(x, canvasSize, imageSize, rotation, cameraLensDirection);
  final translatedY = translateY(y, canvasSize, imageSize, rotation, cameraLensDirection);
  return Offset(translatedX, translatedY);
}

// Tradução de coordenadas com correção para câmera frontal no Android
// Rotação de 90° anti-horário + espelhamento horizontal
double translateX(
  double x,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  // Para câmera frontal no Android, redireciona para translateLandmark
  // Esta função está deprecated, use translateLandmark() em vez disso
  
  // Lógica original para outros casos
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return x * canvasSize.width / imageSize.height;
    case InputImageRotation.rotation270deg:
      return canvasSize.width - x * canvasSize.width / imageSize.height;
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      switch (cameraLensDirection) {
        case CameraLensDirection.back:
          return x * canvasSize.width / imageSize.width;
        default:
          // Comportamento padrão para câmera frontal
          return canvasSize.width - x * canvasSize.width / imageSize.width;
      }
  }
}

double translateY(
  double y,
  Size canvasSize,
  Size imageSize,
  InputImageRotation rotation,
  CameraLensDirection cameraLensDirection,
) {
  // Para câmera frontal no Android, redireciona para translateLandmark
  // Esta função está deprecated, use translateLandmark() em vez disso
  
  // Lógica original para outros casos
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return y * canvasSize.height / imageSize.width;
    case InputImageRotation.rotation270deg:
      return y * canvasSize.height / imageSize.width;
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      return y * canvasSize.height / imageSize.height;
  }
}

Offset translateLandmarkIOS({
  required double x,
  required double y,
  required Size imageSize,
  required Size canvasSize,
  required InputImageRotation rotation,
  required CameraLensDirection lensDirection,
  BoxFit fit = BoxFit.cover,
  bool previewIsMirrored = true,
}) {
  // Hardcode de proporção para iOS
  final iw = imageSize.height; // <-- invertido
  final ih = imageSize.width; // <-- invertido

  double xr, yr, dw, dh;

  switch (rotation) {
    case InputImageRotation.rotation0deg:
      xr = x;
      yr = y;
      dw = iw;
      dh = ih;
      break;
    case InputImageRotation.rotation90deg:
      xr = ih - y;
      yr = x;
      dw = ih;
      dh = iw;
      break;
    case InputImageRotation.rotation180deg:
      xr = iw - x;
      yr = ih - y;
      dw = iw;
      dh = ih;
      break;
    case InputImageRotation.rotation270deg:
      xr = y;
      yr = iw - x;
      dw = ih;
      dh = iw;
      break;
  }

  final isLandscape = rotation == InputImageRotation.rotation90deg ||
      rotation == InputImageRotation.rotation270deg;
  final ax = isLandscape ? yr : xr;
  final ay = isLandscape ? xr : yr;

  bool mirrorX =
      (lensDirection == CameraLensDirection.front) && previewIsMirrored;
  if (rotation == InputImageRotation.rotation270deg &&
      lensDirection == CameraLensDirection.front) {
    mirrorX = !mirrorX;
  }

  final mx = mirrorX ? (dw - ax) : ax;
  final my = ay;

  final fitted = applyBoxFit(fit, Size(dw, dh), canvasSize);
  final dest = fitted.destination;
  final renderRect = Alignment.center.inscribe(dest, Offset.zero & canvasSize);

  final scaleX = dest.width / dw;
  final scaleY = dest.height / dh;

  final alignedX = renderRect.left + mx * scaleX;
  final alignedY = renderRect.top + my * scaleY;

  return Offset(alignedX, alignedY);
}

// Nova: tradução para landmarks normalizados [0,1] do MediaPipe em LIVE_STREAM
// Aplica BoxFit.cover (escala = max), com opção de espelhar para câmera frontal
Offset translateNormalizedLive({
  required double nx,
  required double ny,
  required Size imageSize,
  required Size canvasSize,
  required bool isFrontCamera,
  int rotationDegrees = 0, // Backward compatibility
  int outputRotationDegrees = 0, // New: OUTPUT rotation for display
  bool outputMirrorHorizontal = false, // New: OUTPUT mirror for display
  bool outputMirrorVertical = false, // New: OUTPUT mirror for display
}) {
  // Use output parameters if provided, otherwise fall back to legacy
  final actualRotation = outputRotationDegrees != 0 ? outputRotationDegrees : rotationDegrees;
  // Apply inverse rotation transform to landmarks
  // MLKit returns landmarks in rotated orientation, we need to transform back
  double transformedNx = nx;
  double transformedNy = ny;
  double transformedIw = imageSize.width;
  double transformedIh = imageSize.height;
  
  switch (actualRotation) {
    case 90:
      // Inverse: rotate -90° (or +270°)
      transformedNx = 1.0 - ny;
      transformedNy = nx;
      transformedIw = imageSize.height;
      transformedIh = imageSize.width;
      break;
    case 180:
      // Inverse: rotate -180°
      transformedNx = 1.0 - nx;
      transformedNy = 1.0 - ny;
      break;
    case 270:
      // Inverse: rotate -270° (or +90°)
      transformedNx = ny;
      transformedNy = 1.0 - nx;
      transformedIw = imageSize.height;
      transformedIh = imageSize.width;
      break;
    default:
      // 0° or invalid - no transform
      break;
  }
  
  final double iw = transformedIw;
  final double ih = transformedIh;
  if (iw <= 0 || ih <= 0) return const Offset(0, 0);

  // BoxFit.cover → escala = max(canvasW/iw, canvasH/ih)
  final double scale = max(canvasSize.width / iw, canvasSize.height / ih);
  final double destW = iw * scale;
  final double destH = ih * scale;
  final double left = (canvasSize.width - destW) / 2.0;
  final double top = (canvasSize.height - destH) / 2.0;

  // Posição dentro do destino escalado
  double xInDest = transformedNx * destW;
  double yInDest = transformedNy * destH;

  // Apply OUTPUT mirror transformations
  if (outputMirrorHorizontal) {
    xInDest = destW - xInDest;
  }
  if (outputMirrorVertical) {
    yInDest = destH - yInDest;
  }
  
  // Legacy: Espelhar horizontalmente para câmera frontal (if no explicit output mirror)
  if (isFrontCamera && !outputMirrorHorizontal && outputRotationDegrees == 0) {
    xInDest = destW - xInDest;
  }

  final double x = left + xInDest;
  final double y = top + yInDest;
  return Offset(x, y);
}