import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_adv_settings_model.dart';
import 'package:msupperlimbs/features/fnose/data/repositories/fnose_adv_settings_repository.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_adv_settings_service.dart';

final fnoseAdvSettingsRepositoryProvider =
    Provider<FNoseAdvSettingsRepository>((ref) {
  return FNoseAdvSettingsRepository();
});

final fnoseAdvSettingsServiceProvider =
    Provider<FNoseAdvSettingsService>((ref) {
  return FNoseAdvSettingsService(ref.read(fnoseAdvSettingsRepositoryProvider));
});

final fnoseAdvSettingsProvider =
    FutureProvider.family<FNoseAdvSettingsModel, String>((ref, userId) async {
  final service = ref.read(fnoseAdvSettingsServiceProvider);
  return await service.getOrCreateFNoseAdvSettings(userId);
});

final fnoseAdvSettingsStateProvider =
    StateProvider<FNoseAdvSettingsModel?>((ref) => null);
