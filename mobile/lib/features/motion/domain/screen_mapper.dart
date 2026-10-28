import 'dart:ui';

import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';

/// Única conversão autorizada do espaço A (MediaPipe) para o espaço B
/// (ecrã lógico normalizado).
class ScreenMapper {
  const ScreenMapper({required this.screenSize, required this.previewRect});

  final Size screenSize;
  final Rect previewRect;

  /// Espaço B: x/y em 0–1 do ecrã lógico.
  Offset toScreen(LandmarkPoint point) => toScreenXY(point.x, point.y);

  Offset toScreenXY(double x, double y) => Offset(
    (previewRect.left + x * previewRect.width) / screenSize.width,
    (previewRect.top + y * previewRect.height) / screenSize.height,
  );

  Offset toPixels(Offset screenPoint) => Offset(
    screenPoint.dx * screenSize.width,
    screenPoint.dy * screenSize.height,
  );

  double radiusToPixels(double shortestSideFraction) =>
      shortestSideFraction * screenSize.shortestSide;

  /// Distância em fração do menor lado, preservando círculos entre aspetos.
  double distance(Offset a, Offset b) {
    final dx = (a.dx - b.dx) * screenSize.width / screenSize.shortestSide;
    final dy = (a.dy - b.dy) * screenSize.height / screenSize.shortestSide;
    return (Offset(dx, dy)).distance;
  }

  Map<String, double> get normalizedPreview => {
    'left': previewRect.left / screenSize.width,
    'top': previewRect.top / screenSize.height,
    'width': previewRect.width / screenSize.width,
    'height': previewRect.height / screenSize.height,
  };
}
