import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/gameplay/motion/pose_service.dart';

final poseServiceProvider = Provider<PoseService>((ref) {
  final service = PoseService();
  ref.onDispose(service.dispose);
  return service;
});
