import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings_model.dart';
import 'package:msupperlimbs/features/fnose/data/repositories/fnose_settings_repository.dart';

class FNoseSettingsService {
  final FNoseSettingsRepository _repository;

  FNoseSettingsService(this._repository);

  /// Private method to return default settings
  FNoseSettingsModel _defaultSettings(String userId) {
    return FNoseSettingsModel(
      userId: userId, // Default user identifier
      gameMode: FNoseGameMode.leftHand.asString, // Default mode: left
      showInfoVideo: true, // Show tutorial/instructional video at start
      totalTime: 60, // Total game duration in seconds
      targetSize:
          1, // Not Implemented -  Size of the visual target (relative scale)
      updatedAt: DateTime.now().toUtc(), // Timestamp for last update
    );
  }

  /// Creates settings for user if none exist
  Future<void> createFNoseSettingsIfNotExists(String userId) async {
    final existingSettings = await _repository.getFNoseSettings(userId);
    if (existingSettings == null) {
      final defaultSettings = _defaultSettings(userId);
      await _repository.saveFNoseSettings(userId, defaultSettings);
    }
  }

  /// Creates and saves default settings (always creates new)
  Future<FNoseSettingsModel> createFNoseSettingsStandard(String userId) async {
    final defaultSettings = _defaultSettings(userId);
    await _repository.saveFNoseSettings(userId, defaultSettings);
    return defaultSettings;
  }

  /// Resets and returns settings to default values
  Future<FNoseSettingsModel> restoreDefaults(String userId) async {
    final defaultSettings = _defaultSettings(userId);
    await _repository.saveFNoseSettings(userId, defaultSettings);
    return defaultSettings;
  }

  /// Returns current settings or creates them if not present
  Future<FNoseSettingsModel> getOrCreateFNoseSettings(String userId) async {
    final existingSettings = await _repository.getFNoseSettings(userId);
    return existingSettings ?? await createFNoseSettingsStandard(userId);
  }

  /// Update existing FNoseSettings
  Future<void> updateFNoseSettings(
      FNoseSettingsModel fnoseSettingsModel) async {
    await _repository.saveFNoseSettings(
        fnoseSettingsModel.userId, fnoseSettingsModel);
  }

  /// Updates only the game mode in settings
  Future<void> setFNoseGameMode(String userId, FNoseGameMode mode) async {
    final current = await getOrCreateFNoseSettings(userId);
    final updated = current.copyWith(gameMode: mode.asString);
    await updateFNoseSettings(updated);
  }

  /// Returns the game mode as enum from settings
  Future<FNoseGameMode> getFNoseGameMode(String userId) async {
    final current = await getOrCreateFNoseSettings(userId);
    return FNoseGameModeX.fromString(current.gameMode);
  }
}
