import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings.dart';

/// Basic and advanced settings live in one API resource; each screen reads
/// and patches its part.
class FnoseSettingsRepository {
  FnoseSettingsRepository(this._api, this._userId);

  final ApiClient _api;

  /// Logged-in user's id; the API only serves the caller's own settings.
  final String Function() _userId;

  String get _path => '/msupperlimbs-fnose/players/${_userId()}/settings';

  Future<Map<String, dynamic>> _get(String accessToken) =>
      _api.getJson(_path, accessToken: accessToken);

  Future<Map<String, dynamic>> _patch(
    String accessToken,
    Map<String, dynamic> body,
  ) => _api.patchJson(_path, accessToken: accessToken, body: body);

  Future<Map<String, dynamic>> _restore(String accessToken) =>
      _api.postJson('$_path/restore', accessToken: accessToken);

  Future<FnoseSettings> getSettings(String accessToken) async =>
      FnoseSettings.fromApi(await _get(accessToken));

  Future<FnoseSettings> updateSettings(
    String accessToken,
    FnoseSettings settings,
  ) => patchSettings(accessToken, settings.toUpdateJson());

  /// Changes only the top-level fields in [patch] (camelCase or snake_case).
  Future<FnoseSettings> patchSettings(
    String accessToken,
    Map<String, dynamic> patch,
  ) async => FnoseSettings.fromApi(await _patch(accessToken, patch));

  /// Back to the preset's settings, advanced included.
  Future<FnoseSettings> restoreDefaults(String accessToken) async =>
      FnoseSettings.fromApi(await _restore(accessToken));

  Future<FnoseAdvSettings> getAdvSettings(String accessToken) async =>
      FnoseAdvSettings.fromApi(await _get(accessToken));

  /// [data] uses the app's snake_case keys; the API merges key by key.
  Future<FnoseAdvSettings> updateAdvSettings(
    String accessToken,
    Map<String, dynamic> data,
  ) async {
    final body = FnoseAdvSettings(data: data).toApiJson();
    return FnoseAdvSettings.fromApi(await _patch(accessToken, body));
  }

  /// Back to the preset's settings, basic fields included.
  Future<FnoseAdvSettings> restoreAdvDefaults(String accessToken) async =>
      FnoseAdvSettings.fromApi(await _restore(accessToken));
}
