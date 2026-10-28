import 'dart:math' as math;
import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

double getAngle(
    PoseLandmark firstPoint, PoseLandmark midPoint, PoseLandmark lastPoint) {
  double result = math.atan2(
        lastPoint.y - midPoint.y,
        lastPoint.x - midPoint.x,
      ) -
      math.atan2(
        firstPoint.y - midPoint.y,
        firstPoint.x - midPoint.x,
      );

  // Convert radians to degrees
  result = result * (180 / math.pi);

  // Ensure the angle is always positive
  result = result.abs();

  // Ensure the angle is acute
  if (result > 180) {
    result = 360 - result;
  }
  return result;
}

double get2dEuclideanDistance(Offset a, Offset b) {
  final dx = a.dx - b.dx;
  final dy = a.dy - b.dy;
  return math.sqrt(dx * dx + dy * dy);
}
