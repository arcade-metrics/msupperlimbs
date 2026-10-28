import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/camera_image_config.dart';

/// One-time script to populate Firebase with default camera configs
/// Run this once from main() or a debug button
class PopulateCameraConfigs {
  static Future<void> populate() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final collection = firestore.collection('camera_image_configs');

      // GLOBAL_ANDROID - current hardcoded behaviour
      final globalAndroid = CameraImageConfig.globalAndroid;
      await collection.doc('GLOBAL_ANDROID').set(globalAndroid.toJson());
      debugPrint('✅ Created GLOBAL_ANDROID config');

      // GLOBAL_IOS - current hardcoded behaviour
      final globalIOS = CameraImageConfig.globalIOS;
      await collection.doc('GLOBAL_IOS').set(globalIOS.toJson());
      debugPrint('✅ Created GLOBAL_IOS config');

      debugPrint('🎉 Camera configs populated successfully');
    } catch (e) {
      debugPrint('❌ Failed to populate configs: $e');
      rethrow;
    }
  }

  /// Add a device-specific configuration
  static Future<void> addDeviceConfig(CameraImageConfig config) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('camera_image_configs')
          .doc(config.deviceModel)
          .set(config.toJson());
      debugPrint('✅ Added config for ${config.deviceModel}');
    } catch (e) {
      debugPrint('❌ Failed to add device config: $e');
      rethrow;
    }
  }

  /// Example: Add a specific device config
  static Future<void> addExampleDeviceConfig() async {
    const exampleConfig = CameraImageConfig(
      deviceModel: 'SM-A515F',
      inputRotationDegrees: 270,
      inputMirrorHorizontal: true,
      inputMirrorVertical: false,
      outputRotationDegrees: 270,
      outputMirrorHorizontal: true,
      outputMirrorVertical: false,
    );
    await addDeviceConfig(exampleConfig);
  }
}


