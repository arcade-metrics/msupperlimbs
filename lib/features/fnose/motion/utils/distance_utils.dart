import 'dart:math';
import 'dart:ui';

/// Normalises a 3D Euclidean distance by the diagonal of the image.
/// This makes distance values consistent across devices with different resolutions.
///
/// Example:
///   If dx = 50, dy = 40, dz = 0 and the image size is 1280x720 pixels,
///   then distance = sqrt(50² + 40² + 0²) = 64.03
///   image diagonal = sqrt(1280² + 720²) ≈ 1468.6
///   normalised distance ≈ 64.03 / 1468.6 ≈ 0.044
///
double normaliseDistance(double dx, double dy, double dz, Size imageSize) {
  final distance = sqrt(dx * dx + dy * dy + dz * dz);
  final diagonal = sqrt(
    imageSize.width * imageSize.width + imageSize.height * imageSize.height,
  );
  return distance / diagonal;
}
