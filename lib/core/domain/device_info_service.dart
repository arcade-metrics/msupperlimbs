import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    String deviceModel = "Unknown";
    String osVersion = "Unknown";
    String brand = "Unknown";
    String manufacturer = "Unknown";
    bool isPhysicalDevice = true;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceModel = androidInfo.model ?? "Unknown";
        osVersion = androidInfo.version.release ?? "Unknown";
        brand = androidInfo.brand ?? "Unknown";
        manufacturer = androidInfo.manufacturer ?? "Unknown";
        isPhysicalDevice = androidInfo.isPhysicalDevice ?? true;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine ?? "Unknown";
        osVersion = iosInfo.systemVersion ?? "Unknown";
        brand = "Apple"; // iOS não fornece brand, usar Apple como padrão
        manufacturer = "Apple"; // iOS não fornece manufacturer, usar Apple como padrão
        isPhysicalDevice = iosInfo.isPhysicalDevice ?? true;
      }
    } catch (e) {
      // Em caso de erro, manter valores padrão
      print('[WARN] Error getting device info: $e');
    }

    return {
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'brand': brand,
      'manufacturer': manufacturer,
      'isPhysicalDevice': isPhysicalDevice,
    };
  }
}
