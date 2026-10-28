import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/gameplay/motion/camera_service.dart';

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});
