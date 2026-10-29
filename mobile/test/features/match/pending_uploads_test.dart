import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/calibration/application/calibration_job.dart';
import 'package:msupperlimbs/features/calibration/data/calibration_api.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_calibration_flow.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_calibration.dart';
import 'package:msupperlimbs/features/match/application/match_flow.dart';
import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/application/pending_uploads.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';
import 'package:msupperlimbs/features/match/data/pending_upload_store.dart';

const _rapid = '/api/v1/msupperlimbs-rapid/matches/m-1';
const _finish = '/api/v1/matches/m-1/finish';

/// Fake ciatec-core. [offline] fails every request before it reaches the
/// server; [lostResponses] lets a request reach the server and then fails
/// on the way back, like a connection dropped after the write.
class _FakeCore {
  final requests = <http.Request>[];
  bool offline = false;

  /// Path → how many responses to drop after the server handled them.
  final lostResponses = <String, int>{};
  final rejections = <String, int>{};
  int created = 0;

  late final client = MockClient((request) async {
    if (offline) throw http.ClientException('offline');
    requests.add(request);
    final path = request.url.path;
    final rejected = rejections[path];
    if (rejected != null) {
      return _json({'success': false, 'code': 'X', 'message': 'x'}, rejected);
    }
    final response = switch (path) {
      '/api/v1/catalog/games' => _json({
        'games': [
          {'id': 'g-1', 'slug': 'msupperlimbs-rapid'},
          {'id': 'g-2', 'slug': 'msupperlimbs-fnose'},
        ],
      }, 200),
      '/api/v1/matches/preset' => _json({
        'preset': {'id': 'p-1'},
        'current_level_id': 'l-1',
      }, 200),
      '/api/v1/sessions/matches' => () {
        created += 1;
        return _json({'id': 'm-1', 'session_id': 's-1'}, 201);
      }(),
      '/api/v1/calibrations' => _json({'id': 'run-1'}, 201),
      _ => _json({'created': true}, 202),
    };
    final lost = lostResponses[path] ?? 0;
    if (lost > 0) {
      lostResponses[path] = lost - 1;
      throw http.ClientException('dropped');
    }
    return response;
  });

  late final api = ApiClient(client: client);
  late final matches = MatchApi(api);

  List<http.Request> to(String path) =>
      requests.where((r) => r.url.path == path).toList();
}

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

MatchUploader _noWait() => MatchUploader(sleep: (_) async {});

MatchUpload _upload() => MatchUpload(
  poseFrames: [
    for (var i = 0; i < 600; i++)
      {'offsetMs': i * 33, 'phase': 'playing', 'hands': const []},
  ],
  events: const [
    {'offsetMs': 0, 'eventType': 'phase', 'toPhase': 'playing'},
  ],
  metrics: const {'tapCount': 9, 'isValidMatch': true},
  score: 9,
  durationMs: 30000,
);

const _context = {'appVersion': '0.1.0'};

({PendingUploads queue, MemoryPendingUploadStore store}) _queueFor(
  _FakeCore core, {
  String? Function()? user,
}) {
  final store = MemoryPendingUploadStore();
  final queue = PendingUploads(
    store,
    handlers: {
      PendingMatch.kind: MatchJobRunner(
        core.matches,
        () => 'access',
        uploader: _noWait,
      ).replay,
      PendingCalibration.kind: CalibrationJobRunner(
        core.matches,
        CalibrationApi(core.api),
        () => 'access',
        uploader: _noWait,
      ).replay,
    },
    userId: user ?? () => 'u-1',
  );
  return (queue: queue, store: store);
}

MatchFlow _flow(_FakeCore core, PendingUploads queue) => MatchFlow(
  core.matches,
  () => 'access',
  slug: 'msupperlimbs-rapid',
  userId: () => 'u-1',
  queue: queue,
  uploader: _noWait,
);

void main() {
  test(
    'offline at the end: kept, then sent once with the network back',
    () async {
      final core = _FakeCore();
      final (:queue, :store) = _queueFor(core);
      final flow = _flow(core, queue)..start(_context);
      await pumpEventQueue();

      core.offline = true;
      await expectLater(
        flow.complete(_upload(), _context),
        throwsA(isA<UploadQueuedException>()),
      );
      final kept = store.jobs.values.single;
      expect(kept['kind'], 'match');
      expect(kept['matchId'], 'm-1');
      expect(kept['userId'], 'u-1');

      core.offline = false;
      expect(await queue.flush(), 1);

      expect(core.created, 1, reason: 'the match is not created twice');
      expect(core.to('$_rapid/telemetry/pose'), hasLength(2));
      expect(core.to('$_rapid/metrics'), hasLength(1));
      expect(core.to(_finish), hasLength(1));
      expect(core.to('/api/v1/sessions/s-1/end'), hasLength(1));
      expect(store.jobs, isEmpty);
    },
  );

  test('a finish that landed is resent with the same key and body', () async {
    // Dropped on the first attempt and both retries.
    final core = _FakeCore()..lostResponses[_finish] = 3;
    final (:queue, :store) = _queueFor(core);
    final flow = _flow(core, queue)..start(_context);

    await expectLater(
      flow.complete(_upload(), _context),
      throwsA(isA<UploadQueuedException>()),
    );
    expect(store.jobs.values.single['finishBody'], isNotNull);

    await queue.flush();

    final finishes = core.to(_finish);
    expect(finishes, hasLength(4));
    expect(
      finishes.map((r) => r.headers['Idempotency-Key']).toSet(),
      hasLength(1),
    );
    expect(
      finishes.map((r) => r.body).toSet(),
      hasLength(1),
      reason: 'the same body every time, or the key gives 409',
    );
    expect(store.jobs, isEmpty);
  });

  test('offline from the start: the match is created when sent', () async {
    final core = _FakeCore()..offline = true;
    final (:queue, :store) = _queueFor(core);
    final flow = _flow(core, queue)..start(_context);

    await expectLater(
      flow.complete(_upload(), _context),
      throwsA(isA<UploadQueuedException>()),
    );
    expect(store.jobs.values.single, isNot(contains('matchId')));

    core.offline = false;
    await queue.flush();

    expect(core.created, 1);
    expect(core.to(_finish), hasLength(1));
  });

  test('a rejected upload is not kept', () async {
    final core = _FakeCore()..rejections['$_rapid/events'] = 400;
    final (:queue, :store) = _queueFor(core);
    final flow = _flow(core, queue)..start(_context);

    await expectLater(
      flow.complete(_upload(), _context),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 400)),
    );
    expect(store.jobs, isEmpty);
  });

  test('leaving offline keeps a not-completed finish', () async {
    final core = _FakeCore();
    final (:queue, :store) = _queueFor(core);
    final flow = _flow(core, queue)..start(_context);
    await pumpEventQueue();

    core.offline = true;
    await flow.cancel(score: 2, durationMs: 9000);
    expect(store.jobs.values.single['completed'], isFalse);

    core.offline = false;
    await queue.flush();

    final finish = jsonDecode(core.to(_finish).single.body) as Map;
    expect(finish['completed'], isFalse);
    expect(finish, isNot(contains('extra')));
    expect(core.to('$_rapid/metrics'), isEmpty);
    expect(core.to('/api/v1/sessions/s-1/end').single.url.queryParameters, {
      'cancelled': 'true',
    });
  });

  test('only the logged-in user’s jobs are sent', () async {
    final core = _FakeCore();
    String? user = 'u-2';
    final (:queue, :store) = _queueFor(core, user: () => user);
    store.jobs['j-1'] = {
      ...PendingMatch(
        id: 'j-1',
        userId: 'u-1',
        slug: 'msupperlimbs-rapid',
        createdAt: DateTime.utc(2026),
        context: _context,
        finishKey: 'k-1',
        matchId: 'm-1',
        sessionId: 's-1',
        contextSent: true,
        upload: _upload(),
      ).toJson(),
    };

    expect(await queue.flush(), 0);
    expect(core.requests, isEmpty);
    expect(store.jobs, hasLength(1));

    user = 'u-1';
    expect(await queue.flush(), 1);
    expect(store.jobs, isEmpty);
  });

  test(
    'a job refused on resend is dropped; one still offline is kept',
    () async {
      final core = _FakeCore()..rejections['$_rapid/events'] = 400;
      final (:queue, :store) = _queueFor(core);
      PendingMatch job(String id, DateTime at) => PendingMatch(
        id: id,
        userId: 'u-1',
        slug: 'msupperlimbs-rapid',
        createdAt: at,
        context: _context,
        finishKey: 'k-$id',
        matchId: 'm-1',
        sessionId: 's-1',
        contextSent: true,
        upload: _upload(),
      );
      store.jobs['old'] = job('old', DateTime.utc(2026)).toJson();
      store.jobs['new'] = job('new', DateTime.utc(2027)).toJson();

      expect(await queue.flush(), 0);
      expect(store.jobs.keys, isEmpty, reason: 'both refused the same way');

      core.rejections.clear();
      core.offline = true;
      store.jobs['again'] = job('again', DateTime.utc(2028)).toJson();
      expect(await queue.flush(), 0);
      expect(store.jobs.keys, ['again']);
    },
  );

  test('a calibration run kept offline keeps its run id', () async {
    final core = _FakeCore()
      ..lostResponses['/api/v1/calibrations/run-1/pose'] = 1;
    final (:queue, :store) = _queueFor(core);
    final flow = FnoseCalibrationFlow(
      core.matches,
      CalibrationApi(core.api),
      () => 'access',
      userId: () => 'u-1',
      queue: queue,
      uploader: () => MatchUploader(maxRetries: 0),
    );
    const run = FnoseCalibrationRun(
      completed: true,
      startedOffsetMs: 0,
      endedOffsetMs: 5000,
      context: {'screenWidth': 1000},
      sensorSamples: [
        {'offsetMs': 0, 'ax': 0.0, 'ay': 9.8, 'az': 0.0},
      ],
      poseFrames: [
        {'offsetMs': 10, 'pose': <Map<String, dynamic>>[]},
      ],
      events: [
        {'offsetMs': 0, 'eventType': 'calibration_start'},
      ],
      steps: [],
    );

    await expectLater(flow.upload(run), throwsA(isA<UploadQueuedException>()));
    expect(store.jobs.values.single['runId'], 'run-1');

    await queue.flush();

    expect(core.to('/api/v1/calibrations'), hasLength(1));
    expect(core.to('/api/v1/calibrations/run-1/finish'), hasLength(1));
    expect(store.jobs, isEmpty);
  });

  test('the file store survives a reload and drops broken files', () async {
    final dir = await Directory.systemTemp.createTemp('pending_uploads');
    addTearDown(() => dir.delete(recursive: true));
    final store = FilePendingUploadStore(() async => dir);

    await store.save('a', {'id': 'a', 'kind': 'match', 'n': 1});
    await File('${dir.path}/broken.json').writeAsString('{not json');

    final reloaded = await FilePendingUploadStore(() async => dir).load();
    expect(reloaded, [
      {'id': 'a', 'kind': 'match', 'n': 1},
    ]);
    expect(await File('${dir.path}/broken.json').exists(), isFalse);

    await store.delete('a');
    expect(await store.load(), isEmpty);
  });
}
