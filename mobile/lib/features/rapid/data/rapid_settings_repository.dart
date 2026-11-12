import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings.dart';

class RapidSettingsRepository {
  RapidSettingsRepository(this._api, this._userId);

  final ApiClient _api;

  /// Logged-in user's id; the API only serves the caller's own settings.
  final String Function() _userId;

  String get _path => '/msupperlimbs-rapid/players/${_userId()}/settings';

  Future<RapidSettings> getSettings(String accessToken) async {
    final json = await _api.getJson(_path, accessToken: accessToken);
    return RapidSettings.fromApi(json);
  }

  Future<RapidSettings> updateSettings(
    String accessToken,
    RapidSettings settings,
  ) => patchSettings(accessToken, settings.toUpdateJson());

  /// Changes only the fields in [patch] (camelCase or snake_case).
  Future<RapidSettings> patchSettings(
    String accessToken,
    Map<String, dynamic> patch,
  ) async {
    final json = await _api.patchJson(
      _path,
      accessToken: accessToken,
      body: patch,
    );
    return RapidSettings.fromApi(json);
  }

  /// Back to the preset's settings.
  Future<RapidSettings> restoreDefaults(String accessToken) async {
    final json = await _api.postJson(
      '$_path/restore',
      accessToken: accessToken,
    );
    return RapidSettings.fromApi(json);
  }
}
