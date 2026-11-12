import 'package:msupperlimbs/core/network/api_client.dart';

/// ciatec-core setup calibration runs (`/api/v1/calibrations`, camelCase;
/// `CALIBRATION-RUNS.md`). After the finish every new write is a 409.
class CalibrationApi {
  CalibrationApi(this._api);

  final ApiClient _api;

  /// Opens a run (201) and returns its id. Not idempotent.
  Future<String> open(String accessToken, Map<String, dynamic> body) async {
    final json = await _api.postJson(
      '/calibrations',
      accessToken: accessToken,
      body: body,
    );
    return json['id'] as String;
  }

  Future<void> sensor(
    String accessToken,
    String runId,
    Map<String, dynamic> chunk,
  ) => _api.postJson(
    '/calibrations/$runId/sensor',
    accessToken: accessToken,
    body: chunk,
  );

  Future<void> pose(
    String accessToken,
    String runId,
    Map<String, dynamic> chunk,
  ) => _api.postJson(
    '/calibrations/$runId/pose',
    accessToken: accessToken,
    body: chunk,
  );

  Future<void> events(
    String accessToken,
    String runId,
    Map<String, dynamic> batch,
  ) => _api.postJson(
    '/calibrations/$runId/events',
    accessToken: accessToken,
    body: batch,
  );

  /// A retry after a finish that did reach the server gets
  /// `CALIBRATION_ALREADY_FINALIZED`; that is treated as done.
  Future<void> finish(
    String accessToken,
    String runId,
    Map<String, dynamic> body,
  ) async {
    try {
      await _api.postJson(
        '/calibrations/$runId/finish',
        accessToken: accessToken,
        body: body,
      );
    } on ApiException catch (e) {
      if (e.code != 'CALIBRATION_ALREADY_FINALIZED') rethrow;
    }
  }
}
