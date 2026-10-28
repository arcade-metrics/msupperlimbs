import 'package:flutter/material.dart';
import 'package:msupperlimbs/core/services/camera_config_service.dart';
import 'package:msupperlimbs/core/services/populate_camera_configs.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// Debug utilities for camera configuration
class DebugCameraConfig {
  /// Show current device model and configuration
  static Future<void> showCurrentConfig(BuildContext context) async {
    try {
      // Get device model
      String deviceModel = 'Unknown';
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        deviceModel = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        deviceModel = iosInfo.model;
      }

      // Get current config
      final config = await CameraConfigService.instance.getConfig();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera Configuration'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Device Model: $deviceModel',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('Using Config: ${config.deviceModel}'),
                Text('Rotation: ${config.rotationDegrees}°'),
                Text('Mirror H: ${config.mirrorHorizontal}'),
                Text('Mirror V: ${config.mirrorVertical}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error showing config: $e');
    }
  }

  /// Populate Firebase with default configs (run once)
  static Future<void> populateDefaults() async {
    try {
      await PopulateCameraConfigs.populate();
      debugPrint('✅ Firebase populated with default configs');
    } catch (e) {
      debugPrint('❌ Failed to populate Firebase: $e');
    }
  }

  /// Reload configuration from Firebase
  static Future<void> reloadConfig() async {
    try {
      await CameraConfigService.instance.reload();
      debugPrint('✅ Configuration reloaded');
    } catch (e) {
      debugPrint('❌ Failed to reload config: $e');
    }
  }

  /// Show debug button overlay (add to game screen)
  static Widget buildDebugButton(BuildContext context) {
    return Positioned(
      top: 50,
      right: 16,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.orange,
        onPressed: () => showCurrentConfig(context),
        child: const Icon(Icons.settings, size: 20),
      ),
    );
  }
}


