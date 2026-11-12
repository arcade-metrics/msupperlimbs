import 'dart:async';
import 'dart:math';

import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/application/pending_uploads.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';
import 'package:msupperlimbs/features/match/domain/match_context.dart';

/// What a finished (or abandoned) match uploads, already in the API shape.
class MatchUpload {
  const MatchUpload({
    this.poseFrames = const [],
    this.events = const [],
    this.metrics,
    required this.score,
    required this.durationMs,
  });

  final List<Map<String, dynamic>> poseFrames;
  final List<Map<String, dynamic>> events;

  /// Null for a match the player left: only the finish is sent.
  final Map<String, dynamic>? metrics;
  final int score;
  final int durationMs;

  Map<String, dynamic> toJson() => {
    'poseFrames': poseFrames,
    'events': events,
    'metrics': ?metrics,
    'score': score,
    'durationMs': durationMs,
  };

  factory MatchUpload.fromJson(Map<String, dynamic> json) => MatchUpload(
    poseFrames: _maps(json['poseFrames']),
    events: _maps(json['events']),
    metrics: (json['metrics'] as Map?)?.cast<String, dynamic>(),
    score: json['score'] as int,
    durationMs: json['durationMs'] as int,
  );
}

List<Map<String, dynamic>> _maps(Object? list) => [
  for (final item in list as List? ?? const [])
    (item as Map).cast<String, dynamic>(),
];

/// Everything needed to (re)send one match, kept on the device by
/// [PendingUploads] if the upload fails. Only what cannot be repeated is
/// tracked: the match once created, and the finish body, which must be the
/// same on every attempt for its idempotency key to hold.
class PendingMatch {
  PendingMatch({
    required this.id,
    required this.userId,
    required this.slug,
    required this.createdAt,
    required this.context,
    required this.finishKey,
    this.calibrationRunId,
    this.matchId,
    this.sessionId,
    this.contextSent = false,
    this.upload,
    this.completed = true,
    this.finishBody,
  });

  static const kind = 'match';

  final String id;
  final String userId;
  final String slug;
  final DateTime createdAt;
  final Map<String, dynamic> context;
  final String finishKey;
  String? calibrationRunId;
  String? matchId;
  String? sessionId;
  bool contextSent;
  MatchUpload? upload;
  bool completed;
  Map<String, dynamic>? finishBody;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'id': id,
    'userId': userId,
    'slug': slug,
    'createdAt': createdAt.toIso8601String(),
    'context': context,
    'finishKey': finishKey,
    'calibrationRunId': ?calibrationRunId,
    'matchId': ?matchId,
    'sessionId': ?sessionId,
    'contextSent': contextSent,
    'upload': ?upload?.toJson(),
    'completed': completed,
    'finishBody': ?finishBody,
  };

  factory PendingMatch.fromJson(Map<String, dynamic> json) {
    final upload = json['upload'] as Map?;
    return PendingMatch(
      id: json['id'] as String,
      userId: json['userId'] as String,
      slug: json['slug'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      context: (json['context'] as Map).cast<String, dynamic>(),
      finishKey: json['finishKey'] as String,
      calibrationRunId: json['calibrationRunId'] as String?,
      matchId: json['matchId'] as String?,
      sessionId: json['sessionId'] as String?,
      contextSent: json['contextSent'] as bool? ?? false,
      upload: upload == null
          ? null
          : MatchUpload.fromJson(upload.cast<String, dynamic>()),
      completed: json['completed'] as bool? ?? true,
      finishBody: (json['finishBody'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

/// Runs the steps of a [PendingMatch] that are still missing, updating the
/// job as they complete. Shared by the live flow and the resend queue.
class MatchJobRunner {
  MatchJobRunner(
    this._api,
    this._accessToken, {
    MatchUploader Function()? uploader,
  }) : _newUploader = uploader ?? MatchUploader.new;

  final MatchApi _api;
  final String? Function() _accessToken;
  final MatchUploader Function() _newUploader;

  String get _token {
    final token = _accessToken();
    if (token == null) throw StateError('Not authenticated');
    return token;
  }

  /// Creates the match if not yet. Never retried here: a retry after a
  /// lost response could open a second match.
  Future<void> create(PendingMatch job) async {
    if (job.matchId != null) return;
    final level = await _api.gameLevel(_token, job.slug);
    final match = await _create(level, job.calibrationRunId);
    job
      ..matchId = match.id
      ..sessionId = match.sessionId;
  }

  Future<void> sendContext(PendingMatch job) async {
    if (job.contextSent) return;
    await _api.context(_token, job.slug, job.matchId!, job.context);
    job.contextSent = true;
  }

  /// A run the server will not link (`CALIBRATION_*`) must not cost the
  /// match: it is created without the link.
  Future<CreatedMatch> _create(GameLevel level, String? runId) async {
    if (runId == null) return _api.createMatch(_token, level: level);
    try {
      return await _api.createMatch(
        _token,
        level: level,
        calibrationRunId: runId,
      );
    } on ApiException catch (e) {
      if (!(e.code?.startsWith('CALIBRATION_') ?? false)) rethrow;
      return _api.createMatch(_token, level: level);
    }
  }

  /// Everything still missing, through the finish and the session end.
  /// Throws on the first failure; the job keeps what was done.
  Future<CreatedMatch> run(PendingMatch job) async {
    final upload = job.upload!;
    final up = _newUploader();
    await create(job);
    if (!job.contextSent) {
      await up.send(job.context, () => sendContext(job));
    }
    final matchId = job.matchId!;
    await up.sendPose(
      upload.poseFrames,
      (chunk) => _api.pose(_token, job.slug, matchId, chunk),
    );
    await up.sendEvents(
      upload.events,
      (batch) => _api.events(_token, job.slug, matchId, batch),
    );
    final metrics = upload.metrics;
    if (metrics != null) {
      await up.send(
        metrics,
        () => _api.metrics(_token, job.slug, matchId, metrics),
      );
    }
    final finish = job.finishBody ??= {
      'score': upload.score,
      'duration_ms': max(1, upload.durationMs),
      'completed': job.completed,
      'client_meta': buildClientMeta(),
      if (job.completed) 'extra': {'upload_stats': up.stats.toJson()},
    };
    await up.send(
      finish,
      () => _api.finish(_token, matchId, finish, idempotencyKey: job.finishKey),
    );
    final match = CreatedMatch(id: matchId, sessionId: job.sessionId!);
    try {
      await _api.endSession(_token, match.sessionId, cancelled: !job.completed);
    } catch (_) {
      // The match is already finished; an open session is harmless.
    }
    return match;
  }

  /// [ReplayJob] for [PendingUploads].
  Future<JobOutcome> replay(Map<String, dynamic> json) async {
    final job = PendingMatch.fromJson(json);
    try {
      await run(job);
      return const JobDone();
    } catch (e) {
      return canRetryLater(e) ? JobLater(job.toJson()) : JobRejected(e);
    }
  }
}

/// One MS Upper Limbs match on ciatec-core, from the start of play to the
/// finish: create the match (optionally linked to a calibration run) →
/// context → pose chunks → event batches → metrics → finish (idempotency
/// key, `upload_stats`) → end of the play session.
///
/// If the upload cannot finish now (offline, server down) and a [queue] is
/// given, the match is kept on the device and [complete] throws
/// [UploadQueuedException]; the queue sends it later.
class MatchFlow {
  MatchFlow(
    MatchApi api,
    String? Function() accessToken, {
    required this.slug,
    String? Function()? userId,
    this._queue,
    MatchUploader Function()? uploader,
  }) : _runner = MatchJobRunner(api, accessToken, uploader: uploader),
       _userId = userId ?? (() => null);

  final String slug;
  final MatchJobRunner _runner;
  final String? Function() _userId;
  final PendingUploads? _queue;

  PendingMatch? _job;
  Future<void>? _opening;
  bool _closed = false;

  /// At the start of play: the server freezes the settings and starts its
  /// clock here. Runs in the background; [complete] waits for it.
  ///
  /// [calibrationRunId] resolves to the completed setup run to link (or null
  /// when there is none or its upload failed); the match waits for it.
  void start(
    Map<String, dynamic> context, {
    Future<String?>? calibrationRunId,
  }) {
    if (_job != null) return;
    final job = _job = PendingMatch(
      id: newIdempotencyKey(),
      userId: _userId() ?? '',
      slug: slug,
      createdAt: DateTime.now().toUtc(),
      context: context,
      finishKey: newIdempotencyKey(),
    );
    _opening = () async {
      job.calibrationRunId = await calibrationRunId;
      await _runner.create(job);
      try {
        await _runner.sendContext(job);
      } catch (_) {
        // Sent again with the upload; the first write wins on the server.
      }
    }();
    unawaited(_opening!.then<void>((_) {}, onError: (Object _) {}));
  }

  /// Uploads [upload] and finishes the match. If the opening failed, it is
  /// attempted again here.
  Future<CreatedMatch> complete(
    MatchUpload upload,
    Map<String, dynamic> context,
  ) {
    start(context);
    _closed = true;
    return _finish(upload, completed: true);
  }

  /// The player left mid-match: finish it as not completed. Never throws;
  /// does nothing if play never started or the match is already closed.
  Future<void> cancel({required int score, required int durationMs}) async {
    if (_job == null || _closed) return;
    _closed = true;
    try {
      await _finish(
        MatchUpload(score: score, durationMs: durationMs),
        completed: false,
      );
    } catch (_) {
      // Kept for later when possible; otherwise nothing the player can do.
    }
  }

  Future<CreatedMatch> _finish(
    MatchUpload upload, {
    required bool completed,
  }) async {
    final job = _job!
      ..upload = upload
      ..completed = completed;
    try {
      await _opening;
    } catch (e) {
      // Offline at the start: [MatchJobRunner.run] creates it now (or the
      // queue later). Anything else would be refused again.
      if (!canRetryLater(e)) rethrow;
    }
    try {
      final match = await _runner.run(job);
      // The network works now: a good moment to send what was kept.
      final queue = _queue;
      if (queue != null) unawaited(queue.flush());
      return match;
    } catch (e) {
      final queue = _queue;
      if (queue == null || job.userId.isEmpty || !canRetryLater(e)) rethrow;
      await queue.keep(job.toJson());
      throw UploadQueuedException(e);
    }
  }
}
