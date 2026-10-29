import 'dart:async';
import 'dart:math';

import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';
import 'package:msupperlimbs/features/match/domain/match_context.dart';

/// What a finished match uploads, already in the API shape.
class MatchUpload {
  const MatchUpload({
    required this.poseFrames,
    required this.events,
    required this.metrics,
    required this.score,
    required this.durationMs,
  });

  final List<Map<String, dynamic>> poseFrames;
  final List<Map<String, dynamic>> events;
  final Map<String, dynamic> metrics;
  final int score;
  final int durationMs;
}

/// One MS Upper Limbs match on ciatec-core, from the start of play to the
/// finish: create the match (optionally linked to a calibration run) →
/// context → pose chunks → event batches → metrics → finish (idempotency
/// key, `upload_stats`) → end of the play session.
class MatchFlow {
  MatchFlow(
    this._api,
    this._accessToken, {
    required this.slug,
    MatchUploader Function()? uploader,
  }) : _newUploader = uploader ?? MatchUploader.new;

  final String slug;
  final MatchApi _api;
  final String? Function() _accessToken;
  final MatchUploader Function() _newUploader;
  final _finishKey = newIdempotencyKey();

  Future<CreatedMatch>? _match;
  bool _contextSent = false;
  bool _closed = false;

  String get _token {
    final token = _accessToken();
    if (token == null) throw StateError('Not authenticated');
    return token;
  }

  /// At the start of play: the server freezes the settings and starts its
  /// clock here. Runs in the background; [complete] waits for it.
  ///
  /// [calibrationRunId] resolves to the completed setup run to link (or null
  /// when there is none or its upload failed); the match waits for it.
  void start(
    Map<String, dynamic> context, {
    Future<String?>? calibrationRunId,
  }) {
    if (_match != null) return;
    final opening = _open(context, calibrationRunId);
    _match = opening;
    unawaited(opening.then<void>((_) {}, onError: (Object _) {}));
  }

  Future<CreatedMatch> _open(
    Map<String, dynamic> context,
    Future<String?>? calibrationRunId,
  ) async {
    final level = await _api.gameLevel(_token, slug);
    final runId = await calibrationRunId;
    final match = await _create(level, runId);
    try {
      await _api.context(_token, slug, match.id, context);
      _contextSent = true;
    } catch (_) {
      // Sent again by [complete]; the first write wins on the server.
    }
    return match;
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

  /// Uploads [upload] and finishes the match. Throws if anything fails;
  /// every step is safe to repeat.
  Future<CreatedMatch> complete(
    MatchUpload upload,
    Map<String, dynamic> context,
  ) async {
    start(context);
    final match = await _match!;
    final up = _newUploader();
    if (!_contextSent) {
      await up.send(
        context,
        () => _api.context(_token, slug, match.id, context),
      );
      _contextSent = true;
    }
    await up.sendPose(
      upload.poseFrames,
      (chunk) => _api.pose(_token, slug, match.id, chunk),
    );
    await up.sendEvents(
      upload.events,
      (batch) => _api.events(_token, slug, match.id, batch),
    );
    await up.send(
      upload.metrics,
      () => _api.metrics(_token, slug, match.id, upload.metrics),
    );
    final finish = {
      'score': upload.score,
      'duration_ms': max(1, upload.durationMs),
      'completed': true,
      'client_meta': buildClientMeta(),
      'extra': {'upload_stats': up.stats.toJson()},
    };
    await up.send(
      finish,
      () => _api.finish(_token, match.id, finish, idempotencyKey: _finishKey),
    );
    _closed = true;
    await _endSession(match, cancelled: false);
    return match;
  }

  /// The player left mid-match: finish it as not completed. Best effort,
  /// never throws; does nothing if the match was never opened or is closed.
  Future<void> cancel({required int score, required int durationMs}) async {
    final opening = _match;
    if (opening == null || _closed) return;
    _closed = true;
    try {
      final match = await opening;
      await _api.finish(_token, match.id, {
        'score': score,
        'duration_ms': max(1, durationMs),
        'completed': false,
        'client_meta': buildClientMeta(),
      }, idempotencyKey: _finishKey);
      await _endSession(match, cancelled: true);
    } catch (_) {
      // Left open on the server; nothing the player can do about it here.
    }
  }

  Future<void> _endSession(
    CreatedMatch match, {
    required bool cancelled,
  }) async {
    try {
      await _api.endSession(_token, match.sessionId, cancelled: cancelled);
    } catch (_) {
      // The match is already finished; an open session is harmless.
    }
  }
}
