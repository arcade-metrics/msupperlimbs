import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings_model.dart';
import 'package:msupperlimbs/features/fnose/data/repositories/fnose_settings_repository.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_settings_service.dart';

final fnoseSettingsRepositoryProvider =
    Provider<FNoseSettingsRepository>((ref) {
  return FNoseSettingsRepository();
});

final fnoseSettingsServiceProvider = Provider<FNoseSettingsService>((ref) {
  return FNoseSettingsService(ref.read(fnoseSettingsRepositoryProvider));
});

final fnoseSettingsProvider =
    FutureProvider.family<FNoseSettingsModel, String>((ref, userId) async {
  final fnoseSettingsService = ref.read(fnoseSettingsServiceProvider);
  return await fnoseSettingsService.getOrCreateFNoseSettings(userId);
});

final fnoseSettingsStateProvider =
    StateProvider<FNoseSettingsModel?>((ref) => null);
