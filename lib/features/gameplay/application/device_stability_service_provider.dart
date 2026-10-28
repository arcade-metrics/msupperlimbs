import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../motion/device_stability_service.dart';

final deviceStabilityServiceProvider = Provider<DeviceStabilityService>((ref) {
  final service = DeviceStabilityService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

final deviceStabilityProvider = StreamProvider<bool>((ref) {
  final stabilityService = ref.watch(deviceStabilityServiceProvider);
  // Starts the service when the provider is accessed
  stabilityService.startStabilityCheck();
  return stabilityService.stabilityStream;
});

final deviceAngleProvider = StreamProvider<double>((ref) {
  final service = ref.watch(deviceStabilityServiceProvider);
  return service.angleStream;
});
