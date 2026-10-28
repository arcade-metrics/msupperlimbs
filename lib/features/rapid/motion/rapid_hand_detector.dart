import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Class for handling hand detection in Rapid Game
class RapidHandDetector {
  // Method channel for native communication
  static const platform = MethodChannel('com.example/native');
  
  // Callback for when landmarks are detected
  Function(List<Map<String, dynamic>> landmarks)? onLandmarksDetected;
  
  // Frame counter for processing optimization
  int _frameCounter = 0;
  final int processEveryNFrames = 2; // Process 15fps at 30fps camera
  
  // Process a camera frame
  Future<void> processFrame(Uint8List imageBytes, Size imageSize) async {
    // Only process every Nth frame
    if (_frameCounter % processEveryNFrames != 0) {
      _frameCounter++;
      return;
    }
    
    _frameCounter++;
    
    try {
      // Ensure dimensions are integers
      final width = imageSize.width.toInt();
      final height = imageSize.height.toInt();
      
      
      // Verify data size matches expected Y-plane size
      if (imageBytes.length != width * height) {
      }
      
      // Send to native code with image dimensions
      final List<dynamic> landmarks = await platform.invokeMethod('detectHands', {
        'image': imageBytes,
        'width': width,
        'height': height,
      });
      
      
      // Converter de forma segura para evitar erros de tipo
      final List<Map<String, dynamic>> typedLandmarks = [];
      
      // Converter manualmente cada landmark para o formato correto
      for (final landmark in landmarks) {
        if (landmark is Map) {
          final Map<String, dynamic> typedLandmark = {};
          landmark.forEach((key, value) {
            if (key is String) {
              typedLandmark[key] = value;
            }
          });
          typedLandmarks.add(typedLandmark);
        }
      }
      
      // Call callback if available
      if (onLandmarksDetected != null) {
        onLandmarksDetected!(typedLandmarks);
      }
    } on PlatformException catch (e) {
      // Silent error handling - hand detection failed
    }
  }
  
  // Test the native connection
  Future<String> testNativeConnection() async {
    try {
      final String result = await platform.invokeMethod('test');
      return result;
    } on PlatformException catch (e) {
      return "Error: ${e.message}";
    }
  }
}
