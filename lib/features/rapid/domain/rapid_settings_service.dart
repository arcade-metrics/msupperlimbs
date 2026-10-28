import 'package:msupperlimbs/features/rapid/data/models/rapid_settings_model.dart';
import 'package:msupperlimbs/features/rapid/data/repositories/rapid_settings_repository.dart';

class RapidSettingsService {
  final RapidSettingsRepository _repository;

  RapidSettingsService(this._repository);

  /// Private method to return default settings
  RapidSettingsModel _defaultSettings(String userId) {
    return RapidSettingsModel(
      userId: userId,
      showInfoVideo: true,
      totalTime: 30,
      updatedAt: DateTime.now().toUtc(),
      gameMode: 'rightHand',
      tapSensitivity: 50.0, // Sensibilidade padrão para detecção de toque
    );
  }

  /// Creates settings for user if none exist
  Future<void> createRapidSettingsIfNotExists(String userId) async {
    final existingSettings = await _repository.getRapidSettings(userId);
    if (existingSettings == null) {
      final defaultSettings = _defaultSettings(userId);
      await _repository.saveRapidSettings(userId, defaultSettings);
    }
  }

  /// Creates and saves default settings (always creates new)
  Future<RapidSettingsModel> createRapidSettingsStandard(String userId) async {
    final defaultSettings = _defaultSettings(userId);
    await _repository.saveRapidSettings(userId, defaultSettings);
    return defaultSettings;
  }

  /// Resets and returns settings to default values
  Future<RapidSettingsModel> restoreDefaults(String userId) async {
    final defaultSettings = _defaultSettings(userId);
    await _repository.saveRapidSettings(userId, defaultSettings);
    return defaultSettings;
  }

  /// Returns current settings or creates them if not present
  Future<RapidSettingsModel> getOrCreateRapidSettings(String userId) async {
    final existingSettings = await _repository.getRapidSettings(userId);
    return existingSettings ?? await createRapidSettingsStandard(userId);
  }

  /// Update existing RapidSettings
  Future<void> updateRapidSettings(
      RapidSettingsModel rapidSettingsModel) async {
    await _repository.saveRapidSettings(
        rapidSettingsModel.userId, rapidSettingsModel);
  }

  /// Set game mode for Rapid
  Future<void> setRapidGameMode(String userId, String gameMode) async {
    final settings = await getOrCreateRapidSettings(userId);
    final updated = settings.copyWith(
      gameMode: gameMode,
      updatedAt: DateTime.now().toUtc(),
    );
    await _repository.saveRapidSettings(userId, updated);
  }
}


