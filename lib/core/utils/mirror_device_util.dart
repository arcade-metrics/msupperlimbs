import 'dart:io';
import 'package:flutter/services.dart';

class MirrorDeviceUtil {
  static (bool mirrorHorizontal, bool mirrorVertical) shouldMirrorCamera(
      String deviceModel, DeviceOrientation orientation) {
    if (deviceModel.contains('Moto G (4)')) {
      if (orientation == DeviceOrientation.landscapeLeft ||
          orientation == DeviceOrientation.landscapeRight) {
        // (true, true) means (horizontal mirror, vertical mirror)
        return (true, false); // Just horizontal mirror
      }
    }

    // For iOS devices, mirror horizontally for front camera
    if (Platform.isIOS) {
      return (true, false); // Mirror horizontally for iOS front camera
    }

    return (false, false); // No mirror
  }
}
