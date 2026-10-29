import 'package:msupperlimbs/core/config/app_info.dart';
import 'package:msupperlimbs/features/calibration/data/calibration_api.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_calibration.dart';
import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';

/// Uploads one FNose setup run to `/calibrations`: open → sensor chunks →
/// pose chunks → event batches → finish. The finish goes last because the
/// server refuses any new write after it.
class FnoseCalibrationFlow {
  FnoseCalibrationFlow(
    this._matches,
    this._calibrations,
    this._accessToken, {
    MatchUploader Function()? uploader,
  }) : _newUploader = uploader ?? MatchUploader.new;

  static const slug = 'msupperlimbs-fnose';
  static const maxSensorSamplesPerChunk = 1000;

  final MatchApi _matches;
  final CalibrationApi _calibrations;
  final String? Function() _accessToken;
  final MatchUploader Function() _newUploader;

  String get _token {
    final token = _accessToken();
    if (token == null) throw StateError('Not authenticated');
    return token;
  }

  /// Returns the run id. A completed run can then be linked to the match
  /// (`calibration_run_id`); an abandoned one stays without a match.
  Future<String> upload(FnoseCalibrationRun run) async {
    final level = await _matches.gameLevel(_token, slug);
    final runId = await _calibrations.open(_token, {
      'gameId': level.gameId,
      'appVersion': AppInfo.version,
      'platform': AppInfo.platform,
      ...run.openBody,
    });
    final up = _newUploader();
    await up.sendIndexed(
      run.sensorSamples,
      'chunkIndex',
      'samples',
      (chunk) => _calibrations.sensor(_token, runId, chunk),
      size: maxSensorSamplesPerChunk,
    );
    await up.sendPose(
      run.poseFrames,
      (chunk) => _calibrations.pose(_token, runId, chunk),
    );
    await up.sendEvents(
      run.events,
      (batch) => _calibrations.events(_token, runId, batch),
    );
    final finish = run.finishBody;
    await up.send(finish, () => _calibrations.finish(_token, runId, finish));
    return runId;
  }
}
