import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_adv_settings_state.dart';
import 'package:msupperlimbs/features/fnose/motion/fnose_position_validation_service.dart';

final fnosePositionValidationServiceProvider =
    Provider<FNosePositionValidationService>((ref) {
  final fnoseAdvSettings = ref.watch(fnoseAdvSettingsStateProvider);
  if (fnoseAdvSettings == null) {
    throw Exception('FNose AdvSettingsModel not loaded');
  }
  return FNosePositionValidationService(fnoseAdvSettings);
});
