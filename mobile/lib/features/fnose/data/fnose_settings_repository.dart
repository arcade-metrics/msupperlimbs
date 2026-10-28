import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings.dart';

class FnoseSettingsRepository {
  FnoseSettingsRepository(this._api);

  final ApiClient _api;

  Future<FnoseSettings> getSettings(String accessToken) async {
    final json = await _api.getJson(
      '/fnose/settings',
      accessToken: accessToken,
    );
    return FnoseSettings.fromJson(json);
  }

  Future<FnoseSettings> updateSettings(
    String accessToken,
    FnoseSettings settings,
  ) async {
    final json = await _api.putJson(
      '/fnose/settings',
      accessToken: accessToken,
      body: settings.toUpdateJson(),
    );
    return FnoseSettings.fromJson(json);
  }

  Future<FnoseSettings> patchSettings(
    String accessToken,
    Map<String, dynamic> patch,
  ) async {
    final json = await _api.putJson(
      '/fnose/settings',
      accessToken: accessToken,
      body: patch,
    );
    return FnoseSettings.fromJson(json);
  }

  Future<FnoseSettings> restoreDefaults(String accessToken) async {
    final json = await _api.postJson(
      '/fnose/settings/restore',
      accessToken: accessToken,
    );
    return FnoseSettings.fromJson(json);
  }

  Future<FnoseAdvSettings> getAdvSettings(String accessToken) async {
    final json = await _api.getJson(
      '/fnose/adv-settings',
      accessToken: accessToken,
    );
    return FnoseAdvSettings.fromJson(json);
  }

  Future<FnoseAdvSettings> updateAdvSettings(
    String accessToken,
    Map<String, dynamic> data,
  ) async {
    final json = await _api.putJson(
      '/fnose/adv-settings',
      accessToken: accessToken,
      body: {'data': data},
    );
    return FnoseAdvSettings.fromJson(json);
  }

  Future<FnoseAdvSettings> restoreAdvDefaults(String accessToken) async {
    final json = await _api.postJson(
      '/fnose/adv-settings/restore',
      accessToken: accessToken,
    );
    return FnoseAdvSettings.fromJson(json);
  }
}
