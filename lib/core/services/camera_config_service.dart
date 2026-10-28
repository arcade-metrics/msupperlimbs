import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/camera_image_config.dart';

class CameraConfigService {
  static final CameraConfigService _instance = CameraConfigService._internal();
  factory CameraConfigService() => _instance;
  CameraConfigService._internal();

  static CameraConfigService get instance => _instance;

  CameraImageConfig? _currentConfig;
  String? _deviceModel;

  static const String _collectionName = 'camera_image_configs';
  static const String _cacheKey = 'cached_camera_config';

  /// Get current configuration (loads on first call)
  /// Modified to skip Firebase and use default config for game mode
  Future<CameraImageConfig> getConfig() async {
    if (_currentConfig != null) return _currentConfig!;

    await _loadConfig();
    return _currentConfig ?? _getDefaultConfig();
  }

  /// Load configuration with fallback logic:
  /// Modified to skip Firebase validation and use default config
  Future<void> _loadConfig() async {
    try {
      // Get device model
      _deviceModel = await _getDeviceModel();
      debugPrint('📱 Device model detected: $_deviceModel');

      // Skip Firebase validation - use default config directly
      _currentConfig = _getDefaultConfig();
      debugPrint('✅ Using default config (Firebase disabled): $_currentConfig');
      
      // Optionally try cached config for better UX
      final cachedConfig = await _loadFromCache();
      if (cachedConfig != null) {
        _currentConfig = cachedConfig;
        debugPrint('✅ Using cached config: $_currentConfig');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading camera config: $e');
      _currentConfig = _getDefaultConfig();
    }
  }

  /// Load from Firebase with fallback logic
  /// Modified to skip Firebase operations and use default config
  Future<void> _loadFromFirebase() async {
    try {
      // Skip Firebase operations - use default config
      _currentConfig = _getDefaultConfig();
      debugPrint('✅ Using default config (Firebase disabled): $_currentConfig');
    } catch (e) {
      debugPrint('❌ Config load failed: $e');
      _currentConfig = _getDefaultConfig();
    }
  }

  /// Refresh from Firebase in background
  Future<void> _refreshFromFirebase() async {
    try {
      await _loadFromFirebase();
    } catch (e) {
      debugPrint('⚠️ Background refresh failed: $e');
    }
  }

  /// Get device model string (public for calibration widget)
  Future<String> getActualDeviceModel() async {
    return await _getDeviceModel();
  }

  /// Get device model string
  Future<String> _getDeviceModel() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model; // e.g., "SM-A515F"
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.model; // e.g., "iPhone"
    }
    return 'UNKNOWN';
  }

  /// Get default config based on platform
  CameraImageConfig _getDefaultConfig() {
    return Platform.isIOS
        ? CameraImageConfig.globalIOS
        : CameraImageConfig.globalAndroid;
  }

  /// Save config to SharedPreferences cache
  Future<void> _saveToCache(CameraImageConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = config.toJson();
      await prefs.setString(_cacheKey, jsonEncode(json));
    } catch (e) {
      debugPrint('⚠️ Failed to cache config: $e');
    }
  }

  /// Load config from SharedPreferences cache
  Future<CameraImageConfig?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return CameraImageConfig.fromJson(json);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load cached config: $e');
    }
    return null;
  }

  /// Clear config from SharedPreferences cache
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      debugPrint('🧹 Cleared cached config');
    } catch (e) {
      debugPrint('⚠️ Failed to clear cached config: $e');
    }
  }

  /// Check if config exists in Firebase for given device model
  /// Modified to skip Firebase and return true to avoid validation
  Future<bool> _checkIfConfigExistsInFirebase(String deviceModel) async {
    try {
      // Skip Firebase check - assume config exists to avoid validation
      debugPrint('✅ Skipping Firebase check (disabled) - assuming config exists');
      return true;
    } catch (e) {
      debugPrint('⚠️ Failed to check Firebase config existence: $e');
      return true;
    }
  }

  /// Reset and reload configuration
  Future<void> reload() async {
    _currentConfig = null;
    await _loadConfig();
  }

  /// Set temporary configuration for testing (doesn't save to Firebase)
  Future<void> setTemporaryConfig(CameraImageConfig config) async {
    _currentConfig = config;
    debugPrint('🧪 Temporarily using config: $config');
  }

  /// Save device-specific configuration to Firebase
  /// Modified to skip Firebase and only save to cache
  Future<void> saveDeviceConfig(CameraImageConfig config) async {
    try {
      // Skip Firebase save - only save to cache
      _currentConfig = config;
      await _saveToCache(config);
      
      debugPrint('✅ Saved device config to cache (Firebase disabled): $config');
    } catch (e) {
      debugPrint('❌ Failed to save device config: $e');
      rethrow;
    }
  }

  /// Delete device-specific configuration and force recalibration
  /// Modified to skip Firebase and only clear cache
  Future<void> deleteDeviceConfig() async {
    try {
      final deviceModel = await _getDeviceModel();
      
      // Skip Firebase delete - only clear cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      
      // Reset to default
      _currentConfig = null;
      
      debugPrint('✅ Deleted config for $deviceModel from cache (Firebase disabled)');
    } catch (e) {
      debugPrint('❌ Failed to delete device config: $e');
      rethrow;
    }
  }

  /// Test multiple configurations and return the first one that detects landmarks
  /// Returns null if no configuration works within the timeout
  Future<CameraImageConfig?> calibrateDevice({
    required Future<bool> Function(CameraImageConfig config) testConfig,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deviceModel = _deviceModel ?? await _getDeviceModel();
    
    // Generate test configurations
    final List<CameraImageConfig> configs = [];
    final rotations = [0, 90, 180, 270];
    final mirrorCombinations = [
      (false, false), // no mirror
      (true, false),  // horizontal mirror
      (false, true),  // vertical mirror
      (true, true),   // both mirrors
    ];

    for (final rotation in rotations) {
      for (final mirrors in mirrorCombinations) {
        configs.add(CameraImageConfig(
          deviceModel: deviceModel,
          // For testing, input and output start the same
          inputRotationDegrees: rotation,
          inputMirrorHorizontal: mirrors.$1,
          inputMirrorVertical: mirrors.$2,
          outputRotationDegrees: rotation,
          outputMirrorHorizontal: mirrors.$1,
          outputMirrorVertical: mirrors.$2,
        ));
      }
    }

    debugPrint('🔧 Starting calibration with ${configs.length} configurations');

    // Test each configuration
    for (final config in configs) {
      debugPrint('🧪 Testing config: $config');
      
      await setTemporaryConfig(config);
      
      // Test this configuration
      final success = await testConfig(config);
      
      if (success) {
        debugPrint('✅ Found working config: $config');
        await saveDeviceConfig(config);
        return config;
      }
    }

    debugPrint('❌ No working configuration found');
    return null;
  }
}

