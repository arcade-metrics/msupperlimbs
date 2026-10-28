import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings_model.dart';
import 'package:msupperlimbs/features/rapid/data/repositories/rapid_settings_repository.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_settings_service.dart';

final rapidSettingsRepositoryProvider =
    Provider<RapidSettingsRepository>((ref) {
  return RapidSettingsRepository();
});

final rapidSettingsServiceProvider = Provider<RapidSettingsService>((ref) {
  return RapidSettingsService(ref.read(rapidSettingsRepositoryProvider));
});

final rapidSettingsProvider =
    FutureProvider.family<RapidSettingsModel, String>((ref, userId) async {
  final rapidSettingsService = ref.read(rapidSettingsServiceProvider);
  return await rapidSettingsService.getOrCreateRapidSettings(userId);
});

final rapidSettingsStateProvider =
    StateProvider<RapidSettingsModel?>((ref) => null);


