import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

void lockToLandscape() {
  ScreenOrientation.lockToLandscape();
}

void lockToPortrait() {
  ScreenOrientation.lockToPortrait();
}

void unlockOrientation() {
  ScreenOrientation.unlockOrientation();
}

class ScreenOrientation {
  /// Lock portrait orientation
  static void lockToPortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Lock landscape orientation
  static void lockToLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      // DeviceOrientation.landscapeRight,
    ]);
  }

  /// Unlock orientations
  static void unlockOrientation() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }
}

/// Calculates the rotation angle needed to align the camera preview with the screen orientation
double calculateCameraRotation(CameraDescription description) {
  if (description.sensorOrientation == 90) {
    return 3.14159 / 2; // Standard landscape orientation
  } else if (description.sensorOrientation == 270) {
    return -3.14159 / 2; // Inverted landscape orientation
  } else {
    return 0.0; // Default rotation
  }
}
