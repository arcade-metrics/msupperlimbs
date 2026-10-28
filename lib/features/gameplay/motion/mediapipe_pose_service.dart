import 'dart:typed_data';

import 'package:flutter/services.dart';

class MediaPipePoseService {
  static const MethodChannel _channel = MethodChannel('com.msupperlimbs/mediapipe_pose');

  Future<void> initialize({
    String model = 'lite', // 'lite' | 'full' | 'heavy'
    String delegate = 'cpu', // 'cpu' | 'gpu'
    double detectionConfidence = 0.5,
    double trackingConfidence = 0.5,
    double presenceConfidence = 0.5,
  }) async {
    await _channel.invokeMethod('initialize', {
      'model': model,
      'delegate': delegate,
      'detectionConfidence': detectionConfidence,
      'trackingConfidence': trackingConfidence,
      'presenceConfidence': presenceConfidence,
    });
  }

  Future<List<Map<String, dynamic>>> processFrame({
    required Uint8List grayscaleBytes,
    required int width,
    required int height,
    int rotationDegrees = 0,
    bool mirrorHorizontal = false,
    bool mirrorVertical = false,
    bool isFrontCamera = true,
  }) async {
    final List<dynamic> result = await _channel.invokeMethod('processFrame', {
      'image': grayscaleBytes,
      'width': width,
      'height': height,
      'rotation': rotationDegrees,
      'mirrorHorizontal': mirrorHorizontal,
      'mirrorVertical': mirrorVertical,
      'isFrontCamera': isFrontCamera,
    });

    final List<Map<String, dynamic>> typed = [];
    for (final item in result) {
      if (item is Map) {
        final Map<String, dynamic> casted = {};
        item.forEach((key, value) {
          if (key is String) casted[key] = value;
        });
        typed.add(casted);
      }
    }
    return typed;
  }

  Future<void> dispose() async {
    await _channel.invokeMethod('dispose');
  }
}


