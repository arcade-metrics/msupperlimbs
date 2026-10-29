import 'package:msupperlimbs/features/calibration/data/calibration_api.dart';
import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/application/pending_uploads.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';

const maxSensorSamplesPerChunk = 1000;

/// Everything needed to (re)send one setup run to `/calibrations`, kept on
/// the device by [PendingUploads] if the upload fails. Only the run id is
/// tracked: the streams and the finish are idempotent on the server.
class PendingCalibration {
  PendingCalibration({
    required this.id,
    required this.userId,
    required this.slug,
    required this.createdAt,
    required this.openBody,
    required this.sensorSamples,
    required this.poseFrames,
    required this.events,
    required this.finishBody,
    this.runId,
  });

  static const kind = 'calibration';

  final String id;
  final String userId;

  /// Game of the run; its id is resolved when the run is opened.
  final String slug;
  final DateTime createdAt;

  /// `POST /calibrations` body without `gameId`.
  final Map<String, dynamic> openBody;
  final List<Map<String, dynamic>> sensorSamples;
  final List<Map<String, dynamic>> poseFrames;
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic> finishBody;
  String? runId;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'id': id,
    'userId': userId,
    'slug': slug,
    'createdAt': createdAt.toIso8601String(),
    'openBody': openBody,
    'sensorSamples': sensorSamples,
    'poseFrames': poseFrames,
    'events': events,
    'finishBody': finishBody,
    'runId': ?runId,
  };

  factory PendingCalibration.fromJson(Map<String, dynamic> json) =>
      PendingCalibration(
        id: json['id'] as String,
        userId: json['userId'] as String,
        slug: json['slug'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        openBody: (json['openBody'] as Map).cast<String, dynamic>(),
        sensorSamples: _maps(json['sensorSamples']),
        poseFrames: _maps(json['poseFrames']),
        events: _maps(json['events']),
        finishBody: (json['finishBody'] as Map).cast<String, dynamic>(),
        runId: json['runId'] as String?,
      );
}

List<Map<String, dynamic>> _maps(Object? list) => [
  for (final item in list as List? ?? const [])
    (item as Map).cast<String, dynamic>(),
];

/// Uploads a [PendingCalibration]: open → sensor chunks → pose chunks →
/// event batches → finish. The finish goes last because the server refuses
/// any new write after it. Shared by the live flow and the resend queue.
class CalibrationJobRunner {
  CalibrationJobRunner(
    this._matches,
    this._calibrations,
    this._accessToken, {
    MatchUploader Function()? uploader,
  }) : _newUploader = uploader ?? MatchUploader.new;

  final MatchApi _matches;
  final CalibrationApi _calibrations;
  final String? Function() _accessToken;
  final MatchUploader Function() _newUploader;

  String get _token {
    final token = _accessToken();
    if (token == null) throw StateError('Not authenticated');
    return token;
  }

  /// Returns the run id. The open is not retried: after a lost response a
  /// retry would leave an extra, empty run.
  Future<String> run(PendingCalibration job) async {
    var runId = job.runId;
    if (runId == null) {
      final level = await _matches.gameLevel(_token, job.slug);
      runId = await _calibrations.open(_token, {
        'gameId': level.gameId,
        ...job.openBody,
      });
      job.runId = runId;
    }
    final id = runId;
    final up = _newUploader();
    await up.sendIndexed(
      job.sensorSamples,
      'chunkIndex',
      'samples',
      (chunk) => _calibrations.sensor(_token, id, chunk),
      size: maxSensorSamplesPerChunk,
    );
    await up.sendPose(
      job.poseFrames,
      (chunk) => _calibrations.pose(_token, id, chunk),
    );
    await up.sendEvents(
      job.events,
      (batch) => _calibrations.events(_token, id, batch),
    );
    await up.send(
      job.finishBody,
      () => _calibrations.finish(_token, id, job.finishBody),
    );
    return id;
  }

  /// [ReplayJob] for [PendingUploads].
  Future<JobOutcome> replay(Map<String, dynamic> json) async {
    final job = PendingCalibration.fromJson(json);
    try {
      await run(job);
      return const JobDone();
    } catch (e) {
      return canRetryLater(e) ? JobLater(job.toJson()) : JobRejected(e);
    }
  }
}
