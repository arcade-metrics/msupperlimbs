import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings.dart';

class RapidSettingsRepository {
  RapidSettingsRepository(this._api);

  final ApiClient _api;

  Future<RapidSettings> getSettings(String accessToken) async {
    final json = await _api.getJson(
      '/rapid/settings',
      accessToken: accessToken,
    );
    return RapidSettings.fromJson(json);
  }

  Future<RapidSettings> updateSettings(
    String accessToken,
    RapidSettings settings,
  ) async {
    final json = await _api.putJson(
      '/rapid/settings',
      accessToken: accessToken,
      body: settings.toUpdateJson(),
    );
    return RapidSettings.fromJson(json);
  }

  Future<RapidSettings> patchSettings(
    String accessToken,
    Map<String, dynamic> patch,
  ) async {
    final json = await _api.putJson(
      '/rapid/settings',
      accessToken: accessToken,
      body: patch,
    );
    return RapidSettings.fromJson(json);
  }

  Future<RapidSettings> restoreDefaults(String accessToken) async {
    final json = await _api.postJson(
      '/rapid/settings/restore',
      accessToken: accessToken,
    );
    return RapidSettings.fromJson(json);
  }
}
