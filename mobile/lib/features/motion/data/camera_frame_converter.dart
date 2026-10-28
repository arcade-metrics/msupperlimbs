import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DownsampledPlane {
  const DownsampledPlane({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Extracts the Y plane (grayscale) from a camera frame for MediaPipe.
class CameraFrameConverter {
  static Uint8List? yPlaneBytes(CameraImage image) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;
    final bytes = plane.bytes;
    final width = image.width;
    final height = image.height;
    final rowStride = plane.bytesPerRow;

    if (rowStride == width) {
      return bytes.length >= width * height
          ? Uint8List.sublistView(bytes, 0, width * height)
          : Uint8List.fromList(bytes);
    }

    final out = Uint8List(width * height);
    for (var row = 0; row < height; row++) {
      final srcStart = row * rowStride;
      final dstStart = row * width;
      out.setRange(dstStart, dstStart + width, bytes, srcStart);
    }
    return out;
  }

  /// Nearest-neighbor downsample to keep MediaPipe under ~maxSide.
  static DownsampledPlane downsampleY(
    Uint8List src,
    int width,
    int height, {
    int maxSide = 320,
  }) {
    final longest = width > height ? width : height;
    if (longest <= maxSide) {
      return DownsampledPlane(bytes: src, width: width, height: height);
    }

    final scale = maxSide / longest;
    final nw = (width * scale).round().clamp(1, width);
    final nh = (height * scale).round().clamp(1, height);
    final out = Uint8List(nw * nh);
    for (var y = 0; y < nh; y++) {
      final sy = (y * height) ~/ nh;
      final srcRow = sy * width;
      final dstRow = y * nw;
      for (var x = 0; x < nw; x++) {
        out[dstRow + x] = src[srcRow + ((x * width) ~/ nw)];
      }
    }
    return DownsampledPlane(bytes: out, width: nw, height: nh);
  }

  /// Degrees for MediaPipe input so the frame matches CameraPreview orientation.
  static int rotationForPreview({
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
  }) {
    final sensor = camera.sensorOrientation;
    final deviceDegrees = switch (deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };

    if (camera.lensDirection == CameraLensDirection.front) {
      final compensated = (sensor + deviceDegrees) % 360;
      return (360 - compensated) % 360;
    }
    return (sensor - deviceDegrees + 360) % 360;
  }
}

void logCameraError(Object error, [StackTrace? stack]) {
  debugPrint('Camera error: $error');
  if (stack != null) debugPrintStack(stackTrace: stack);
}
