import 'package:msupperlimbs/core/config/app_info.dart';
import 'package:msupperlimbs/features/calibration/application/calibration_job.dart';
import 'package:msupperlimbs/features/calibration/data/calibration_api.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_calibration.dart';
import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/application/pending_uploads.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';

/// Uploads one FNose setup run to `/calibrations` ([CalibrationJobRunner]).
///
/// If it cannot finish now and a [queue] is given, the run is kept on the
/// device and [upload] throws [UploadQueuedException]; the match is then
/// created without the link.
class FnoseCalibrationFlow {
  FnoseCalibrationFlow(
    MatchApi matches,
    CalibrationApi calibrations,
    String? Function() accessToken, {
    String? Function()? userId,
    this._queue,
    MatchUploader Function()? uploader,
  }) : _runner = CalibrationJobRunner(
         matches,
         calibrations,
         accessToken,
         uploader: uploader,
       ),
       _userId = userId ?? (() => null);

  static const slug = 'msupperlimbs-fnose';

  final CalibrationJobRunner _runner;
  final String? Function() _userId;
  final PendingUploads? _queue;

  /// Returns the run id. A completed run can then be linked to the match
  /// (`calibration_run_id`); an abandoned one stays without a match.
  Future<String> upload(FnoseCalibrationRun run) async {
    final job = PendingCalibration(
      id: newIdempotencyKey(),
      userId: _userId() ?? '',
      slug: slug,
      createdAt: DateTime.now().toUtc(),
      openBody: {
        'appVersion': AppInfo.version,
        'platform': AppInfo.platform,
        ...run.openBody,
      },
      sensorSamples: run.sensorSamples,
      poseFrames: run.poseFrames,
      events: run.events,
      finishBody: run.finishBody,
    );
    try {
      return await _runner.run(job);
    } catch (e) {
      final queue = _queue;
      if (queue == null || job.userId.isEmpty || !canRetryLater(e)) rethrow;
      await queue.keep(job.toJson());
      throw UploadQueuedException(e);
    }
  }
}
